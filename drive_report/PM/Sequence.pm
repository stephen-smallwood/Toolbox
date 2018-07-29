package Sequence;

#
# much borrowed from kevin campbell's lseq
# added getsortedhash(),
# added sequnpack(),
# added checkfiles(),
#    -jms 9/99
#
# added rangeparse(),
# added getseqhash(),
# added getseqlist(),
# added getbestprefixmatch(),
# added seqfoundbyprefix(),
# added parseseqbyprefix(),
# fixed range packing buglette:
#    1-4x3,5-10 is now 1,4-10
#    -jms 01/10/99
#
# removed seqfoundbyprefix(),
# removed parseseqbyprefix(),
# added parseseq(),
#    -jms 11/10/99

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
    getfiles
    sortfiles
    printout
    sequnpack
    checkfiles
    getseqlist
    getseqhash
    parseseq
    rangeparse
    getbestseqmatchbyprefix
	    );

require 5.004;

#Globals
my %fileNums;
my %fileAge;
my $dir='';
my $sortmode=0;


#read the dir
sub getfiles {
    $dir=shift;
    opendir(DIR,$dir) or die "can't open the directory $dir:\n  $!";
    my @files=grep{!/^\.+/ && -f "$dir/$_"} readdir(DIR);
    closedir(DIR);
    return @files;
}

#sort
sub sortfiles {
    my ($files)=shift;
    %fileNums=();
    %fileAge=();
    if (@_) {$sortmode=$_[0];}
    my ($age,$fn,$pad,$f);
    foreach (@$files){
        next if (/^\.*$/); #ignore hidden files
	$f=$_;
        if (s/(-?(\d+))(\D*)$/$;$3/) {
	    $fn=$1;
	    $pad=length($2);
	    #
	    # stab at fixing padding problem
	    if ($pad>1 && $fn=~/^0/) {
	        $fileNums{$_}->{$pad}.="$fn,";
	    } else {
		$fileNums{$_}->{1}.="$fn,";
	    }
        } else {
            $fileNums{$_}++;
        }
	if ($sortmode)
	{
	    if (!$fileAge{$_})
	    {
	        lstat("$dir/$f");
	        if (-e _)
		{
		    $fileAge{$_}=-M _;
		}
	    }
	}
    }
    my $stub;
    my $l;
    my @list;
    foreach $stub (keys %fileNums) {
	#
	# if we have some undetermined zero padded files,
	# and the length of the mallest of these is
	# greater than 1, and we have a match for zero
	# padded files at this length, throw them together.
	#
	if (scalar(keys(%{$fileNums{$stub}})) > 1 && defined($fileNums{$stub}->{1})) {
	    $l=length((sort {$a <=> $b} split(/,/,$fileNums{$stub}->{1}))[0]);
	    if ($l>1 && defined($fileNums{$stub}->{$l})) {
	        $fileNums{$stub}->{$l} .= "$fileNums{$stub}->{1},";
	        delete($fileNums{$stub}->{1});
	    }
	}
    }
}

sub getseqhash {
    return %fileNums;
}

#print out
sub printout {
    my ($quiet)=shift;
    $quiet=0 unless defined $quiet;
    my ($func)='';
    $func=($sortmode)?\&sortbyage:\&sortbyname;
    my $stub;
    foreach $stub (sort $func keys %fileNums) {
	if (!%{$fileNums{$stub}}) {
	    print $stub,"\n";
	    next;
	}
	my ($pad,$file,$nums,$numFrames);
	foreach $pad (sort {$a <=> $b} keys (%{$fileNums{$stub}})) {
            $file=$stub;
            ($nums,$numFrames)=&range($fileNums{$stub}->{$pad});
            $nums="\e\[32m$nums\e\[36m" if($numFrames>1);
            $file=~s/$;/$nums/;
            $file="\e\[36m$file\e\[m" if($numFrames>1);
	    $file=~s/\e\[\d*m//g if ($quiet);
            print $file,"\n";
	}
    }
}

sub sortbyname {
    $a cmp $b
}
sub sortbyage {
    $fileAge{$b} <=> $fileAge{$a}
}

#
# Return a sorted list of seqs
#
sub getseqlist {
    my (@list)=();
    foreach my $stub (sort keys %fileNums){
        if ('HASH' ne ref($fileNums{$stub})) {
            push(@list, $stub);
            next;
        }
	my (%lists)=%{$fileNums{$stub}};
	foreach my $key (sort {$b <=> $a} keys %lists) {
	    my $file=$stub;
	    my ($nums,$numFrames)=&range($lists{$key},0);
	    $file=~s/$;/$nums/;
	    push(@list, $file);
	}
    }
    return (sort @list);
}

#
# There are (at least) two things to address here:
# - zero padding is not rigorously pursued:
#   01,2,3,4 returns a single sequence 01-04
# - ranges can look like 1-5x4,6-9
#   instead of 1,5-9
#
# Range problem fixed, it is always assumed
# that a file belongs with the neighbor with
# whom it shares the smaller step.  jms 10-99
#
sub range {
    my $range=shift;
    my $do_compress=shift;
    $do_compress=1 unless defined($do_compress);
    $range =~s /,$//; #remove trailing comma if present
    local($^W)=0;

    my @frames=sort {$a <=> $b} split(/\,/,$range);
    my $numframes=@frames;

    #pack 'em into ranges
    my @newframes;
    while (@frames){
	my ($s)=shift(@frames);
	my ($e)=$s;
        my ($step)=$frames[0]-$s;
        while(@frames){
	    my $nstep=defined($frames[1])?$frames[1]-$frames[0]:$step;
	    last if ($nstep < $step);
            last unless ($frames[0] == $e+$step);
	    $e=shift(@frames);
        }
	my $subrange="$s";
	if ($s != $e) {
	    $subrange.="-$e";
	    $subrange.="x$step" if ($step>1);
	}
	push(@newframes,$subrange);
    }
    my $newrange=join(',',@newframes);
    if ($do_compress) {
        my $cnt=0;
        $newrange=~ s/\,/($cnt++ and $cnt%6==0)?" ... \n  ... ":','/eg;
    }
    return ($newrange,$numframes);
}

#
# Right now, this only returns a seq
# which matches: the given prefix or the
# given prefix with with "." appended...
# Which is all I need right now.
#
sub getbestseqmatchbyprefix {
    my ($mpref)=shift;
    my ($best)='';
    my ($stub);
    foreach $stub (keys(%fileNums)) {
	my ($test,$suff)=split(/$;/,$stub);
	if ($test eq $mpref) {
	    $best=$stub;
	    last;
	}
	if ($test eq "$mpref.") {
	    $best=$stub;
	}
    }
    return '' if ($best eq '');
    my (%list)=%{$fileNums{$best}};
    my ($r,$n)=range($list{(keys(%list))[0]});
    $best=~s/$;/$r/;
    return $best;
}

#
# Determine and return:
#  - frame start
#  - frame end
#  - frame step
#  - frame pad.
# From the given range.
#
sub rangeparse {
    my ($range)=shift;
    #PrintDebug( "DEBUG: rangeparse(): input range is $range");

    my ($fs,$fe,$step,$pad)=(1,1,1,1);
    if ($range =~ s/x(\d+)$//) {
	$step=$1;
        #PrintDebug( "DEBUG: rangeparse(): got step=$step");
    }
    #PrintDebug( "DEBUG: rangeparse(): range is now $range");

    return undef unless ($range=~/^(-?\d+)-?(-?\d*)$/);
    $fs=$1;
    $fe=$2;
    #PrintDebug( "DEBUG: rangeparse(): fs=$fs, fe=$fe");

    $fe=$fs if (!defined($fe) || $fe eq '');
    $pad=length($fs);
    $pad-- if ($fs=~/^-/);

    #PrintDebug( "DEBUG: rangeparse(): returning $fs,$fe,$step,$pad");
    return ($fs,$fe,$step,$pad);
}

#
# I'm cheating.  I'm returning the
# first matching range from the hash of ranges
# associated with this prefix and extension.
# This would be a problem if I were to pass in
# something like: foo.0001-0010,20-30.cin
# Hopefully I won't do this.
#
# Note that the call to sortfiles wipes out
# any previous hash stored in %fileNums.
#
sub parseseq {
    my ($seq)=shift;
    my (@list)=sequnpack($seq);
    return ('','','') unless (@list);
    sortfiles(\@list);
    my ($stub)=(keys(%fileNums))[0];
    my (%list)=%{$fileNums{$stub}};
    my ($prefix,$suffix)=split(/$;/,$stub);
    my ($key)=(keys(%list))[0];
    my ($range,$n)=('','');
    ($range,$n)=range($list{$key}) if (defined($key) && defined($list{$key}));
    return ($prefix,$range,$suffix);
}

#
# Take the given sequence and return
# a sorted list of individual files.
#
sub sequnpack {
    my ($seq)=shift;
    my ($dir)='';
    if ($seq=~/^(.*\/)([^\/]+)$/) {
	$dir=$1;
	$seq=$2;
    }
    my ($range)='';
    my ($sep)='';
    my ($found)=0;
    while ($seq=~s/(-?\d+(--?\d+(x\d+)?)?,?)$sep(\D*)$/$;$+/) {
	$range = "$1$range";
	$found=1;
	$sep=$;
    }

    return ("$seq") unless $found;

    my ($prefix,$ext)=split(/$;/,$seq);
    my (@ranges)=split(/,/,$range);

    #PrintDebug( "DEBUG: pre=$prefix");
    #PrintDebug( "DEBUG: ext=$ext");
    #for (@ranges) {PrintDebug( "DEBUG: range: $_");}

    my (@unpacked)=();
    for (@ranges) {
        my ($s,$e,$step,$pad)=rangeparse($_);
        my ($i);
        for ($i=$s;$i<=$e;$i+=$step) {
            push(@unpacked,sprintf("%s%s%0${pad}d%s", $dir,$prefix,$i,$ext));
        }
    }
    return (@unpacked);
}

#
# Return a list of files from the
# given list which are not found
# on the file system
#
sub checkfiles {
    my ($list)=shift;
    my (@missing)=();
    for (@$list) {
	if (!-e $_) {
	    push (@missing, $_);
	}
    }
    return (@missing);
}

1;
