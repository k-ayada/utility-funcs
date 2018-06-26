#!/opt/bin/perl5.8 -w
use strict;
use subs qw(trim); # Trim the string#use String::Util qw(trim);  #use Text::Trim qw(trim);
use subs qw(rmChar); # Removes the set of chars in a string
use subs qw(nullIf); # Return null if value matches
use subs qw(printLn); # Print the line

sub  trim {
  my $s = shift;
  $s =~ s/^\s+|\s+$//g;
  return $s
};
sub rmChar {
  my ($s, $chars) = @_;
  $s =~ s/[$chars]//g;
  return $s;
}
sub nullIf {
   my ($s, $c) = @_;
   return "" if $s eq $c;
   return $s;
}
sub toNum {
    my $s = shift;
    $s = rmChar(trim($s),",");
    $s = "0".$s              if (substr($s,0,1) eq '.');
    $s = "-".substr($s,1,-1) if (substr($s,-1)  eq '-');
    return trim($s);
}
