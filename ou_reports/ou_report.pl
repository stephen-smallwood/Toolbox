#!/usr/bin/perl
#
use Data::Dumper qw(Dumper);

#Pull in info from ldap query
#
while (<>) 
{
   if ($_ =~ /dn/)
      {
         $dn = $sam = "";
         $dn = $_;
         $dn =~ s/dn: //;
      }
   elsif($_ =~ /sAMAccountName/)
      {
         $sam = $_;
	 $sam =~ s/sAMAccountName: //;

         if ($sam =~ s/\$/\$/g)
           { 
              $sam = "MACHINE";
           }

         $dn =~ s/OU=|DC=|CN=//g;

         @bits = split /,/,$dn;
	 $num = @bits;
	 $location = $bits[$num-4];
	 $dpt = $bits[$num-5];
	 $name = $bits[0];

         if ($location =~ /London/ && $sam !~ /MACHINE/)
	    {
#	       print "$sam";
#	       print "$dn";
#	       print "$dpt \n";
               $dpt_list{$dpt}=1;
	       push (@$dpt, $name); 
	    }
      }
}
@dpt_names = keys %dpt_list;
foreach $dpt_n (@dpt_names)
   {
      if(@$dpt_n && $dpt_n !~ /@$dpt_n[0]/)
         {
#            print "$dpt_n: ".scalar @$dpt_n." \n";
            foreach $name (@$dpt_n)
	       {
                  print "$dpt_n:$name \n";
	       }
	 }
   }
