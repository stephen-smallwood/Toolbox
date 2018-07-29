#!/usr/bin/perl

$start_path="<DIR PATH>";

open(DIR_LISTING, "find $start_path -type d |");

while ($line = <DIR_LISTING>){
   chomp($line);
   # print "$line | ";
   @result = `./seqls -nc "$line"`;
#   if (@result){
      foreach(@result){
         chomp($_);
         print "$line|$_ \n";
      }
#   }

}

close(DIR_LISTING);
