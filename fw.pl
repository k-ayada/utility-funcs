#!/opt/bin/perl5.8 -w
#==================================================================================================
# Script : fw.pl
# Desc   : Utility to watch for file(s) based on the input path (fully qualified path/regEx).
# Usage  :
#             
#    >fw.pl [-f[--file] "<file>"  
#           [-w[--waitfor] <mins> ]
#           [-s[--sleepfor] <seconds>]
#           [-r[--recheck]<recheck>]
#           [-e[--exe] <exe path> [-a[--arg] <arg>]...]
#           [-v[--verbose]]
#           [-nl[--nologfile]]
#         ]    
#         [-h[--help]]
#         
#    -f[--file]       -> Fully Qualified File Path.
#    -w[--waitfor]    -> Max watch time in minutes (default : 480 mins)
#    -s[--sleepfor]   -> sleep time between lookup intervals in seconds (default: 3 seconds)
#    -r[--recheck]    -> Number of times to Rechecks the file size before ending (default: 2)
#    -e[--exe]        -> Command to execute when the file is available( default: noExe).
#    -a[--arg]        -> Argument(s) to be passed. 
#	                    (If multiple arguments needs to be passed, add -a[--arg] for each argument).
#    -v[--verbose]    -> verbose mode. Logs remaining wait time (default: inactive)
#    -nl[--nologfile] -> Doesn't creates the separate log file 
#    -h[--help]       -> Displays the usage instructions.
#
#
#
#                                   Change Log
#                                ================
# No. Developer       Date     Request No.     Description
#---- --------------- --/--/-- --------------- -----------------------------------------------------
#   1 Kiran Ayada     08/01/15 ???????????     Initial Version
#---- --------------- --/--/-- --------------- -----------------------------------------------------
#===================================================================================================
#
## perl modules imports
#
 use strict;
 use warnings;
 use Switch;
 use IO::Handle;
 use File::stat;
 use File::Basename;
 use Time::Local;
 use POSIX qw(strftime);
 use Env qw(FWCV_BIN_DIR FWCV_LOG_DIR FWCV_VERBOSE);
#
##pragma to pre-declare sub names
#
 use subs qw(SUB_INIT_PGM)         ; # Initialize the program.
 use subs qw(SUB_CHECK_ARGS)       ; # Validates the arguments
 use subs qw(SUB_LOGIT)            ; # Logs the status messages
 use subs qw(SUB_RPT_N_DIE)        ; # Report the error and exit with a RC
 use subs qw(SUB_LOG_DTLS)         ; # Log the file watcher details
 use subs qw(SUB_HELP)             ; # Display the usage information.
 use subs qw(SUB_FW)               ; # Wait for the file to get downloaded.
 use subs qw(SUB_RUN_EXE)          ; # Runs the executable requested.
 use subs qw(SUB_WAIT_FOR_FILE)    ; # Wait for single file  
 use subs qw(SUB_WAIT_FOR_DOWNLOAD); # Wait for al files 
 use subs qw(SUB_CLEANUP_AND_EXIT) ; # Cleanup and exit
 use subs qw(trim)                 ; # Trim the string 
#
##Arguments (default values)
#
 my $max_children= 10;  # Max number of parallel load process
 my $waitfor     = 480; # Sleep interval
 my $sleepfor    = 05;  # Sleep interval
 my $recheck     = 02;  # recheck count
 my $verbose     = 0 ;  # Verbose mode flag
 my $file        = '.'; # Verbose mode flag
 my $nologfl     = 1  ; # If 0 - creates a log file. 1 - just termount
 my @exe         = () ; # command to be executed post success.
#
##General variables.
# 
 local $| = 1;
 my $rc   = 0;
 my $ts;
 my $stage;
 my $cmd;
 my $script = basename($0);
 my $end_time;
 my $end_time_ftm;
 my $start_time_ftm;
 
 my $LOGFL;
# 
## arrays  
# 
 my @pids;
#
## Interrupt signal handler.
#
 local $SIG{INT} = sub {
        kill @pids;
        SUB_LOGIT("[".__LINE__."],  ****** All child process stopped ******.");
        exit 16;
 };
#
## DIE signal handler
#
 local $SIG{__DIE__} = sub {
 my($signal) = @_;
    SUB_LOGIT ("[".__LINE__."], Runtime error at stage :- $stage");
    SUB_RPT_N_DIE(16,"DIE: $signal");
 };
 
#**************************************************************************************************
#************************************  Execution Starts Here  *************************************
#**************************************************************************************************
 SUB_CHECK_ARGS; #.......... Read and validate the arguments.
 SUB_INIT_PGM; #............ Initialize the execution.
  
 $start_time_ftm = strftime("%Y-%m-%d %H:%M:%S" ,localtime);
 $end_time_ftm   = strftime("%Y-%m-%d %H:%M:%S" ,localtime(time + $waitfor * 60));
 $end_time       = strftime("%Y%m%d%H%M%S"      ,localtime(time + $waitfor * 60));
 
 SUB_LOG_DTLS          unless ($rc); # Log the parameters
 SUB_FW                unless ($rc); # Wait for at least one file to be catalogued.
 SUB_WAIT_FOR_DOWNLOAD unless ($rc); # Wait for all the files to be downloaded.
 SUB_RUN_EXE           unless ($rc); # If requested, run the executable.
 SUB_CLEANUP_AND_EXIT; #.............. Clean-up and exit.

#**************************************************************************************************
#************************************  Sub-routine definitions  ***********************************
#**************************************************************************************************

#--------------------------------------------------------------------------------------------------
# Prepares the script for execution.
#--------------------------------------------------------------------------------------------------
 sub SUB_INIT_PGM {
 my $term   = `tty`               ; $term = substr($term,0,-1);
    $ts     = `date +"%y%m%d%H%M"`; $ts   = substr($ts,0,-1);

#   Open the log file, redirect the standard error to log file

    if ($nologfl) {
#      Redirect the errors to std out.
       *STDERR = *STDOUT;
    } else {
        open($LOGFL, ">","${FWCV_LOG_DIR}/${ARGV[0]}/${ARGV[0]}_fw.pl_$ts.log")
          or die("Failed to open the log file".
                 "${FWCV_LOG_DIR}/fw.pl_$ts.log");
#    Redirect the errors to log files.
        *STDERR = $LOGFL unless ($nologfl);
    }

    $verbose     =  ${FWCV_VERBOSE} if (defined(${FWCV_VERBOSE}));

    SUB_LOGIT ("[".__LINE__."], Terminal :$term , Starting script:- $0 @ARGV");
 }
#--------------------------------------------------------------------------------------------------
# Write the log message to log file and to terminal if in verbose mode.
#--------------------------------------------------------------------------------------------------
 sub SUB_LOGIT {
 my $lts=`date +"%H:%M:%S"`; $lts=substr($lts,0,-1); # current system timestamp.
 my $ln = "$lts,$$,${script}$_[0]\n"; #............... concat timestamp, current pid, script & msg

    print STDOUT "$ln" ; #......................................... Spool to terminal
    print $LOGFL "$ln" if ( (!$nologfl)     and 
                            defined($LOGFL) and 
                            $LOGFL->opened());; # Spool to log file
 }
#--------------------------------------------------------------------------------------------------
# Report the error message and end the execution.
#--------------------------------------------------------------------------------------------------
 sub SUB_RPT_N_DIE {

     $rc=($_[0]); #........................... Set the return code
     SUB_LOGIT("[".__LINE__."], $_[1]"); #.... Log the error
     SUB_CLEANUP_AND_EXIT; #.................. Close all the handlers and exit.
 }

#--------------------------------------------------------------------------------------------------
# Clean up and end the script.
#--------------------------------------------------------------------------------------------------
 sub SUB_CLEANUP_AND_EXIT {

     SUB_LOGIT ("[".__LINE__."], Ending script:- $0"); # Log the end message.
	 
     close $LOGFL if (defined($LOGFL )); #.............. Close the log file.
     exit($rc); #....................................... Exit with RC=$rc.

 }
#--------------------------------------------------------------------------------------------------
# Validates the arguments passed in the commndline.
#--------------------------------------------------------------------------------------------------
 sub SUB_CHECK_ARGS {
 $stage="SUB_CHECK_ARGS:- Get arguments. count : " .scalar @ARGV;

#   Loop through the arguments, validate them and store them in variables.
    for (my $i= 0; $i < scalar @ARGV ; $i= $i+2) {    
       my $switch = $ARGV[$i];
       switch ($ARGV[$i])  {
            case ["-f","--file"]        {$file    =  $ARGV[$i + 1] if (defined($ARGV[$i + 1]));}
            case ["-w","--waitfor" ]    {$waitfor =  $ARGV[$i + 1] if (defined($ARGV[$i + 1]));} 
            case ["-s","--sleepfor"]    {$sleepfor=  $ARGV[$i + 1] if (defined($ARGV[$i + 1]));} 
            case ["-r","--recheck" ]    {$recheck =  $ARGV[$i + 1] if (defined($ARGV[$i + 1]));} 
            case ["-e","--exe"     ]    {push(@exe,"\"$ARGV[$i + 1]\"") if (defined($ARGV[$i + 1]));} 
            case ["-a","--arg"     ]    {push(@exe,"\"$ARGV[$i + 1]\"") if (defined($ARGV[$i + 1]));} 
            case ["-h","--help"    ]    {SUB_HELP    ; exit(0)}
            case ["-v","--verbose" ]    {$verbose = 1;$i--;} 
            case ["-nl","--nologfile" ] {$nologfl = 1;$i--;} 
            else {
			    SUB_LOGIT ("[".__LINE__."], Unknown switch '$ARGV[$i]' received.");
			    SUB_HELP; 
				exit(1);
		    }            
         }    
    }  
#   If we didn't get any file to look for, show the usage and exit with RC=1	
    if (!defined($file)) {
       SUB_HELP;
       exit(1);
    }
 }    
#--------------------------------------------------------------------------------------------------
# Prints the help information and exists with rc 0.
#--------------------------------------------------------------------------------------------------
 sub SUB_HELP {
 $stage  = "SUB_HELP :- Print help info.";
 print qq{Utility to watch for file(s) based on the input path (fully qualified path regEx)
 Usage,
             
    >fww [-f[--file] "<file>"  
           [-w[--waitfor] <mins> ]
           [-s[--sleepfor] <seconds>]
           [-r[--recheck]<recheck>]
           [-e[-exe] <exe path> [-a[--arg] <arg>]...]
           [-v[-verbose]]
           [-nl[--nologfile]]
         ]    
         [-h[--help]]
         
    -f[--file]       -> Fully Qualified File Path.
    -w[--waitfor]    -> Max watch time in minutes (default : 480 mins)
    -s[--sleepfor]   -> sleep time between lookup intervals in seconds (default: 3 seconds)
    -r[--recheck]    -> Number of times to Rechecks the file size before ending (default: 2)
    -e[--exe]        -> Command to execute when the file is available( default: noExe).
    -a[--arg]        -> Argument(s) to be passed. 
	                    (If multiple arguments needs to be passed, add -a[--arg] for each argument).
    -v[--verbose]    -> verbose mode. Logs remaining wait time (default: inactive)
    -nl[--nologfile] -> Doesn't creates the separate log file
    -h[--help]       -> Displays the usage instructions."          
    };
 }

   
#--------------------------------------------------------------------------------------------------
# Logs the parameters used for file watcher.
#-------------------------------------------------------------------------------------------------- 
 sub SUB_LOG_DTLS {
 $stage  = "SUB_LOG_DTLS :- Log the parameters.";
 
    SUB_LOGIT ("[".__LINE__."], $stage");
    SUB_LOGIT ("[".__LINE__."], Parent pid : ".getppid."  Current pid : $$");
    SUB_LOGIT ("[".__LINE__."], Input,");
    SUB_LOGIT ("[".__LINE__."], File Path       : $file");
    SUB_LOGIT ("[".__LINE__."], Max Wait time   : $waitfor (in min)");
    SUB_LOGIT ("[".__LINE__."], Sleep interval  : $sleepfor (in secs)");
    SUB_LOGIT ("[".__LINE__."], Recheck Count   : $recheck");
    SUB_LOGIT ("[".__LINE__."], Execute Command : @exe")          if (@exe);
    SUB_LOGIT ("[".__LINE__."], Execute Command : no exe to run") unless (@exe);
    SUB_LOGIT ("[".__LINE__."], Job Started at  : $start_time_ftm");
    SUB_LOGIT ("[".__LINE__."], Job Ends at     : $end_time_ftm".
                                                  " ( if the file is not catalogued...)"); 
 }
#--------------------------------------------------------------------------------------------------
# Wait until file is catalogued.
#-------------------------------------------------------------------------------------------------- 
 sub SUB_FW {
 my $curTime = strftime("%Y%m%d%H%M%S",localtime); 
 my $timeLeft_fmt = `${FWCV_BIN_DIR}/DateDiff.pl '$end_time' '$curTime' `; 
 my $cntr=-1;
 my $timeLeft= $end_time - $curTime; #..................... Calc the time left
 my $fileNotPresent=system("ls -l $file >/dev/null 2>&1"); #Return 0 if file is present
 $stage  = "SUB_FW :- Wait for atleast one file to catalogue.";
 
    SUB_LOGIT ("[".__LINE__."], $stage");
    SUB_LOGIT ("[".__LINE__."], Looking for the file(s) : '$file'");
    SUB_LOGIT ("[".__LINE__."],     Watcher ends in (D:H:M:S) : $timeLeft_fmt");
   
#  Wait for the file to get catalogued.    
    while ($fileNotPresent) {
        sleep($sleepfor);  #.............................. Sleep 
		$curTime = strftime("%Y%m%d%H%M%S",localtime); #.. Get the formatted current time
	    $timeLeft = $end_time - $curTime; #............... Calc the time left
        $sleepfor = $timeLeft if ($sleepfor > $timeLeft) ; # reset the sleep interval
        $cntr++; #........................................ Increment the counter for logging
		$cntr = 0 if ($cntr ge 9); #...................... Reset the counter 
		
#       call DateDiff.pl to get the time left in days:hours:minutes:seconds format	and log it	
		$timeLeft_fmt = `${FWCV_BIN_DIR}/DateDiff.pl '$end_time' '$curTime' `; 
        SUB_LOGIT ("[".__LINE__."],".
		           "     Watcher ends in (D:H:M:S) : $timeLeft_fmt ") if ($verbose and !$cntr);	

#       Stop waiting if out of max wait time 				   
        if ( $timeLeft le 0) { #................... End wait if out of max wait time
            SUB_LOGIT ("[".__LINE__."], Out of wait time. Ending the file watcher");
            SUB_LOGIT ("[".__LINE__."], File was not catalogued since $start_time_ftm");    
            $rc=04;                                        
            last;
        } 
        $fileNotPresent=system("ls -l $file >/dev/null 2>&1");
    }
#   If we found at least one file, log the file details.
    if ( $rc eq 0) {
        SUB_LOGIT ("[".__LINE__."], Files found in catalogue,");
		foreach (glob($file)) {
			my $ls = `ls -eth $_`; $ls = substr($ls,0,-1);
			SUB_LOGIT ("[".__LINE__."], $ls");
	   }
		
    } 
 }
#--------------------------------------------------------------------------------------------------
# Wait until file is catalogued.
#-------------------------------------------------------------------------------------------------- 
 sub SUB_WAIT_FOR_DOWNLOAD {
 $stage  = "SUB_WAIT_FOR_DOWNLOAD :- Wait for $file";
		   
    SUB_LOGIT ("[".__LINE__."], $stage"); 

#   For all the files matching the input pattern, wait for file download. 	
	foreach (glob($file)) {
	  SUB_WAIT_FOR_FILE($_);
	}
 } 
#--------------------------------------------------------------------------------------------------
# Wait until file is catalogued.
#-------------------------------------------------------------------------------------------------- 
 sub SUB_WAIT_FOR_FILE {
 my $reChk    = 0;
 my $sizeHold = -1;
 my $size     = '';
 my $fl = shift;
 my $curSize;
 
 $stage  = "SUB_WAIT_FOR_FILE :- Wait for '$fl'.";
 
    SUB_LOGIT ("[".__LINE__."], $stage"); 
#   Loop infinitely, break when the file size read is same for $recheck times. 	
    while (1) {
        $curSize = -s $fl;  #.................... Get the new file size 
		
        if (defined($curSize) and 
            $sizeHold eq $curSize ) {$reChk++;} # Is the size is same increment the counter
        else {
            $reChk  = 0; #................................ Size increased, reset the counter to 0
            $sizeHold = $curSize if (defined($curSize)); # hold the new size. 
        }
#       Format the size and report it.
        if ($curSize < 1024) {
            $size = "$curSize Bytes"; #........ convert bytes to KB        
        }elsif ($curSize < 1232896) {           
		    $size = $curSize/1024;              
            $size = `printf "%.2f KB" $size`; # convert bytes to KB
        }elsif($curSize < 1073741824){          
		    $size = $curSize/1232896;           
            $size = `printf "%.2f MB" $size`; # convert bytes to MB
        }else {
		    $size = $curSize/1073741824;
            $size = `printf "%.2f GB" $size`; # convert bytes to GB
        }  
        SUB_LOGIT("[".__LINE__."], ".
                 "Current File size : $size. ".
				 " Re-check count : $reChk.")  if ($verbose);
				 
#       Log and break the loop if counter reached the max   				 
        if ( $reChk gt $recheck ) { 
            SUB_LOGIT("[".__LINE__."], ".
                      "Stopping the wait as the counter reached max limit ($recheck)".
					  ". Final File Size : $size ($curSize Bytes)");             
            last;        
        } 		
        sleep($sleepfor);  #.......... Sleep before re-checking the file size.        
    }
 }
#--------------------------------------------------------------------------------------------------
# Runs the executable requested.
#-------------------------------------------------------------------------------------------------- 
 sub SUB_RUN_EXE {
  
   if (@exe) {    
      $stage  = "SUB_RUN_EXE :- Execuet the exe  @exe";
      SUB_LOGIT ("[".__LINE__."], $stage");

      my $cmd = `printf "@exe"`; # Build the command string 
      my $res = `$cmd 2>&1`; #.... Execute the command and store the term-out results
      $rc = $?; #................. Capture the return code
       
#     Log the term-out results captured.	
  	  SUB_LOGIT("[".__LINE__."], Return code from child process :$rc");
  	  SUB_LOGIT("[".__LINE__."], Results of child process -Start");
  	  SUB_LOGIT("[".__LINE__."],".
  	            "---------------------------------------------------------------------------------".
  	            "\n\n$res");		  
  	  SUB_LOGIT("[".__LINE__."], ".
  	            "---------------------------------------------------------------------------------");
  	  SUB_LOGIT("[".__LINE__."], Results of child process -End");
   } else {
      $stage  = "SUB_RUN_EXE :- No executable to execute";
      SUB_LOGIT ("[".__LINE__."], $stage");        
   }
 }
