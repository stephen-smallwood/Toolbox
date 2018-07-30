#!/usr/bin/perl

#use strict;
#use warnings;
#
# OPEN SOURCE FILE
$SrcFile="restorelist.txt";
$ArchiveDir="/usr/openv/netbackup/ArchiveLogs";
$RestoreSrcDir="/root/STEVE/INT_REST/RESTS";
$RestoreDestDir="/mill/vol35/sven_restore/2015-09-24-Fiona";

open $fh,"<",$SrcFile or die $!;
while ($row = <$fh>) {
#  chomp $row;
#  print "$row\n";
#
# Get key and set path to file for restore
#
  # Get id
  @fields = split /\//,$row;
  $id = "$fields[3]/$fields[4]";
#  print "$id\n";
  # Get key
  $ArchiveGrep = `grep $id $ArchiveDir/*.lst`;
#  print "$ArchiveGrep\n";
  @ArchiveGrepBits = split /[-.]/,$ArchiveGrep;
  $ArchiveID = $ArchiveGrepBits[1];
#  print "$ArchiveID\n";
  # set file source path
#  print "$row \n";
  $FSP = $row; 
  $FSP =~ s/data/\/mill\/sven/;
  print "$FSP";
  # chuck path in key'ed restore list
  open OUT, ">>$RestoreSrcDir/$ArchiveID" or die "Couldn't open file: $!";
  print OUT "$FSP";
  close OUT;
}

# For each key set we found
@RestKeys = <$RestoreSrcDir/*>;
foreach $RestKey (@RestKeys) {
  print "$RestKey \n";
  @RestKeyBits = split/\//, $RestKey;
  $RestKeyShort=$RestKeyBits[-1];
#}
# write rename file
   open OUT, ">$RestKey.rnm" or die "Couldn't open file: $!";
   print OUT "change /mill/sven to $RestoreDestDir";
   close OUT;

   # Write scripts to do restore
   open OUT, ">$RestKey.cmd" or die "Couldn't open file: $!";
   print OUT "/usr/openv/netbackup/bin/bprestore -C spot -D spot.mill.co.uk -disk_media_server spot.mill.co.uk -k $RestKeyShort -L $RestKey.log -R $RestKey.rnm -f $RestKey";
   close OUT;
}

