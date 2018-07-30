#!/usr/bin/perl
#
use Data::Dumper qw(Dumper);

#Pull in info from ldap query
#
while (<>) 
{
   if ($_ =~ /dn/)
      {
         $today_unix = time;
         $today = ( $today_unix + 11644473600 ) * 10000000;
         $daysago = (( $today_unix - ( 30 * 24 *60 *60)) + 11644473600 ) * 10000000;

         $dn = $sam = "";
         $dn = $_;
         $dn =~ s/dn: //;

	 $dpt = "NULL";
	 $mig_stat = "NOT";
	 $accountExpires ="NULL";
	 $acc_exp="NULL";
	 $act_act="NULL";
	 $acc_inuse="NULL";
      }
   elsif($_ =~ /department/)
      {
         $dpt = $_;
	 chomp($dpt);
         $dpt =~ s/department: //;
      }

   elsif($_ =~ /targetAddress/)
      {
         $targetAddress = $_;
	 if ($targetAddress =~ /onmicrosoft/)
	    {
	       $mig_stat = "MIGRATED";
	    }
      }
   elsif($_ =~ /accountExpires/)
      {
          $accountExpires = $_;
	  $accountExpires =~ s/accountExpires: //;
	  chomp($accountExpires);

	  if ($accountExpires == 0)
	     {
	        $acc_exp="NEVER";
             }
	  elsif ($accountExpires > $today )
	     {
	        $acc_exp="FUTURE";
             }
	  else
	     {
	        $acc_exp="EXPIRED";
             }
      }
   elsif($_ =~ /userAccountControl/)
      {
          $userAccountControl = $_;
	  $userAccountControl =~ s/userAccountControl: //;
	  chomp($userAccountControl);

	  if ($userAccountControl == 512)
	     {
	        $acc_act = "ENABLED";
	     }
	  elsif ($userAccountControl == 514)
	     {
	       $acc_act = "DISABLED";
	     }
	  else
	     {
	        $acc_act = "OTHER";
             }
      }
   elsif($_ =~ /lastLogonTimestamp/)
      {
         $lastLogonTimestamp = $_;
	 $lastLogonTimestamp =~ s/lastLogonTimestamp: //;
	 chomp($lastLogonTimestamp);
         
         if ( $lastLogonTimestamp < $daysago )
	    {
	       $acc_inuse = "INACTIVE";
	    }
	 else
	    {
	       $acc_inuse = "ACTIVE";
	    }
      }

   elsif($_ =~ /sAMAccountName/ && $dpt !~ /NULL/)
      {
         $sam = $_;
	 $sam =~ s/sAMAccountName: //;
	 chomp($sam);

         $dn =~ s/OU=|DC=|CN=//g;

         @bits = split /,/,$dn;
	 $num = @bits;
	 $location = $bits[$num-4];
	 $name = $bits[0];

        if ($location =~ /London/)
	    {
               $dpt_list{$dpt}=1;
	       push (@$dpt, "$name|$sam|$mig_stat|$acc_exp|$acc_act|$acc_inuse"); 
	  #     print "HERE2: $name | $accountExpires | $today | $acc_exp \n";
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
                  print "$dpt_n|$name \n";
	       }
	 }
   }
