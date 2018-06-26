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
sub SUB_RPT_N_DIE {
 print "$_[0]";
 exit (0);
}
sub SUB_ORA_GET_CONNECTION {
 my $ora_sid   = $_[0]; #  database SID
 my $ora_host  = $_[1]; #  database host
 my $ora_user  = $_[2];
 my $ora_pswd  = $_[3];
 my $driver= "Oracle";
 my $dsn = "DBI:$driver:sid=$$ora_sid;host=$ora_host";
$dbh = DBI->connect($dsn, $ora_user, $ora_pswd);
     $ora_conn = ISIS::AC->ac_conn( ( "dbi:$driver:" . $ora_sid ) , "/")
                 or SUB_RPT_N_DIE( 2, "Failed to get Connection. ".
                                      "ORA_Err :- $DBI::errstr" );
 }
 sub SUB_ORA_PREP_SQL_TEXT {
 my $ora_conn = $_[0];
 my $sql_text = $_[1];
    $ora_stmt = $ora_conn->prepare($sql_text)
                or SUB_RPT_N_DIE("Failed to prepare the SQl text. ".
                                    "ORA_Err :- $DBI::errstr" );

 }

 sub SUB_ORA_RUN_STMT {
 my $ora_stmt = $_[0];
    $ora_stmt->execute()
               or SUB_RPT_N_DIE("Faile to execute the statement. ".
                                    "ORA_Err :- $DBI::errstr" );
 }
 
 sub PRINT_ORA_ROWS {
 my $ora_stmt = $_[0] 
 my @res;
 while(@res = $ora_stmt->fetchrow_array()) { #.......... Loop thru all the rows returned
   print $res[0];   
 } 
 
