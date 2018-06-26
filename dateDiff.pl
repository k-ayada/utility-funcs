#!/opt/bin/perl5.8 -w
#==================================================================================================
# Script : DateDiff.pl
# Desc   : Return the difference between the two timestamps passed.
#        
# Args   : 1. End Timestamp :- 'yyyy-mm-dd HH:MM:SS'
#          2. Start Timestamp :- 'yyyy-mm-dd HH:MM:SS'
#
# Sample : 1  >perl dateDiff.pl '20150131100459' '20150101100500'
#              29:23:59:59
#
#        : 2  >perl dateDiff.pl '20150101100500' '20150131100459'
#             -29:-23:-59:-59
#
#                                   Change Log
#                                ================
# No. Developer       Date     Request No.     Description
#---- --------------- --/--/-- --------------- -----------------------------------------------------
#   1 Kiran Ayada     08/01/15 ???????????     Initial Version
#---- --------------- --/--/-- --------------- -----------------------------------------------------
#===================================================================================================
 use Time::Local;
 my ($D1 , $D2) = @ARGV; 
#20150206102656
 my $y1 = substr $D1, 0,4;
 my $m1 = substr $D1, 4,2;
 my $d1 = substr $D1, 6,2;
 my $H1 = substr $D1,-6,2;
 my $M1 = substr $D1,-4,2;
 my $S1 = substr $D1,-2;
 my $y2 = substr $D2, 0,4;
 my $m2 = substr $D2, 4,2;
 my $d2 = substr $D2, 6,2;
 my $H2 = substr $D2,-6,2;
 my $M2 = substr $D2,-4,2;
 my $S2 = substr $D2,-2;
 my $time1 = timegm($S1, $M1, $H1, $d1, $m1 - 1, $y1 - 1900);
 my $time2 = timegm($S2, $M2, $H2, $d2, $m2 - 1, $y2 - 1900);
 my $diff = ($time1 - $time2) ;
 
 #if ($diff < 0) {
 #  print " -ve diff";
 #  $diff *= -1;
 #}
 my $diffD = int($diff / 86400);
    $diff =  $diff - int(($diffD * 86400));
 my $diffH = int($diff / (3600));
    $diff  = $diff -  ($diffH*3600);
 my $diffM = int($diff / 60);
 my $diffS = $diff - ($diffM * 60);
 printf("%d:%02d:%02d:%02d", $diffD,$diffH,$diffM,$diffS);
 exit;
