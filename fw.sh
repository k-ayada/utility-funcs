#!/usr/bin/env bash
# Script : fw
#
# Desc   : Utility to watch for file(s) based on the input path (fully qualified path regEx)
#
# Usage  : >fw -f[--file] "<file>" 
#               [-w[--waitfor] <mins> 
#                -s[--sleepfor] <seconds> 
#                -r[--recheck]<recheck>] 
#                -e[-exe] <exe path> [-a[--arg] <arg>]...
#                -v[-verbose] 
#                -h[--help]
#               ]
#
# Args   : -f[--file]    -> Fully Qualified File Path.
#          -w[--waitfor] -> Max watch time in minutes (default : 480 mins)
#          -s[--sleepfor]-> sleep time between lookup intervals in seconds (default: 3 seconds)
#          -r[--recheck] -> Number of times to Rechecks the file size before ending (default 2)
#          -e[--exe]     -> Command to execute when the file is available. 
#          -v[--verbose] -> verbose mode. Logs remaining wait time (default : inactive)
#          -h[--help]    -> Displays the usage.
#
#                                   Change Log
#                                ================
# No. Developer       Date     Request No.     Description
#---- --------------- --/--/-- --------------- -----------------------------------------------------
#   1 Kiran Ayada     06/26/15 ???????????     Initial Version
#---- --------------- --/--/-- --------------- -----------------------------------------------------
#===================================================================================================
func_helpInfo() {
     echo "Utility to watch for file(s) based on the input path (fully qualified path regEx)"
     echo "Usage "
     echo '      >fw -f[--file] "<file>'
     echo '           [-w[--waitfor] <mins> '
     echo '            -s[--sleepfor] <seconds>'
     echo '           -r[--recheck]<recheck>] '
     echo '           -e[-exe] <exe path> [-a[--arg] <arg>]...'
     echo '           -v[-verbose]'
     echo '           -h[--help]'
     echo '          ]'
     echo " where,"
     echo "      -f[--file]    -> Fully Qualified File Path."
     echo "      -w[--waitfor] -> Max watch time in minutes (default : 480 mins)"
     echo "      -s[--sleepfor]-> sleep time between lookup intervals in seconds (default: 3 seconds)"
     echo "      -r[--recheck] -> Number of times to Rechecks the file size before ending (default 2)"
     echo "      -e[--exe]     -> Command to execute when the file is available( default : noExe)."
     echo "      -a[--arg]     -> Argument(s) to be passed. (If multiple arguments needs to be passed, add -a[--arg] for each argument)."
     echo "      -v[--verbose] -> verbose mode. Logs remaining wait time (default : inactive)"
     echo "      -h[--help]    -> Displays the usage."

     echo
     exit 1
}
func_DeriveTimes() {
    sDTcymd=`date '+%Y-%m-%d %H:%M:%S'`
    eDTcymdHMS=`perl -MPOSIX -e 'my ($mins) = @ARGV;\
                                 print strftime("%Y-%m-%d %H:%M:%S",localtime(time + $mins * 60));'\
                                 $wTime`
    if [ $? -ne 0 ]; then
      echo failed to calculate the end timestamp
      exit $?
    fi
    eTime=`perl -MPOSIX -e 'my ($mins) = @ARGV;\
                            print strftime("%Y%m%d%H%M%S", localtime(time + $mins * 60));\
                            ' $wTime`
    if [ $? -ne 0 ]; then
      echo failed to calculate the end timestamp
      exit $?
    fi    
}

func_echoDtls() {

    echo `date '+%Y-%m-%d %H:%M:%S'`", Parent pid : $PPID  Current pid :$$"
    echo `date '+%Y-%m-%d %H:%M:%S'`", Input"
    echo `date '+%Y-%m-%d %H:%M:%S'`",      File Path       : " "$pth"
    echo `date '+%Y-%m-%d %H:%M:%S'`",      Max Wait time   : " $wTime "(in min)"
    echo `date '+%Y-%m-%d %H:%M:%S'`",      Sleep interval  : " $si "(in secs)"
    echo `date '+%Y-%m-%d %H:%M:%S'`",      Recheck Count   : " $MaxReChk 
    echo `date '+%Y-%m-%d %H:%M:%S'`",      Execute Command : " $exe $args
    echo `date '+%Y-%m-%d %H:%M:%S'`",      Job Started at  : " $sDTcymd
    echo `date '+%Y-%m-%d %H:%M:%S'`",      Job Ends at     : " $eDTcymdHMS\
                                            "( if the file is not catalogued...)"
}
func_fw() {
    cDTcymd=`date '+%Y%m%d%H%M%S'`
    echo `date '+%Y-%m-%d %H:%M:%S'`", Looking for the file(s) : $pth"
    echo `date '+%Y-%m-%d %H:%M:%S'`",      Watcher ends in (D:H:M:S) : "`perl ./DateDiff.pl $eTime $cDTcymd`
    cmd=`ls -l $pth 2>/dev/null | wc -l`
   
    if [ -n $(ls $pth 2>/dev/null) ] ; then
        cmdRes=${cmd}
    else
        cmdRes=""
    fi 

    while [ ! $cmdRes ]; do
        sleep $si
        cDTcymd=`date '+%Y%m%d%H%M%S'`
        ((diff = $eTime - $cDTcymd))
        if [ $diff -le 0 ]; then
            echo " out of wait time" $eTime  "-" $cDTcymd "=" $diff
            rc=16
            break
        fi
        if [ $vflag -eq 1 ]; then
            echo `date '+%Y-%m-%d %H:%M:%S'`",      Watcher ends in (days:hrs:mins:secs) : "\
                 `perl ./DateDiff.pl $eTime $cDTcymd`
        fi        
        if [ -n $(ls $pth 2>/dev/null) ] ; then
           cmdRes=${cmd}
        fi
    done
}
func_runls() {
    if [ $rc -eq 0 ]; then
    echo `date '+%Y-%m-%d %H:%M:%S'`", File(s) found: "
    for file in $pth ; do
        echo `date '+%Y-%m-%d %H:%M:%S'`",     " `ls -eth $file |grep ^-`
    done
    else
    echo `date '+%Y-%m-%d %H:%M:%S'`", File was not catalogued since " $sDTcymd
    fi
}
func_wait4AllFlsDL() {
    for file in $pth ; do 
        func_wait4singleFl $file
    done
}

func_wait4singleFl() {
    szHld=-1
    rchk=0
    echo `date '+%Y-%m-%d %H:%M:%S'`", Waiting for download completion of the file : $1"
    while true ; do      
       if [ $vflag -eq 1 ] ; then 
          ls -et $1
       fi 	
       sz=`ls -et $1 |grep ^- | awk '{print $5}'`       
       if [ "$sz" == "$szHld" ]; then 
           (( rchk += 1 ))
       else
          rchk=0
          szHld=$sz
       fi  
	   sleep $si
	   
       if [ $rchk -gt $MaxReChk ]; then 
            if [ $vflag -eq 1 ] ; then 
                echo `date '+%Y-%m-%d %H:%M:%S'`",      Stopping the wait as the counter reached max limit ($MaxReChk)"
            fi    
          break
       fi	   
       if [ $vflag -eq 1 ] ; then 
	      if [ $sz -lt 1232896 ] ; then 
		     sz1="$(awk -v sz=$sz 'BEGIN { printf "%.2f",(sz/1024)}' )K"
		  else 	
             sz1="$(awk -v sz=$sz 'BEGIN { printf "%.2f",(sz/1232896)}' )M"
		  fi
		  echo `date '+%Y-%m-%d %H:%M:%S'`",      Current file size: $sz1. Re-check count: $rchk"
       fi
    done
}

func_runEXE() {

  if [ "$exe" == "noExe" ]; then
   :
  else 
    exe="$exe $args"
	
	echo $exe
    ${exe} >"/temp/fw_res_$PPID_$$.out" &
	pid=$!
	echo `date '+%Y-%m-%d %H:%M:%S'`", Started the command $exe with pid : $pid"
    wait $!      
	rc=$?
	echo `date '+%Y-%m-%d %H:%M:%S'`", Results from child process starts ----------------------------------"
	while read -r LINE ; do  
	   echo `date '+%Y-%m-%d %H:%M:%S'`",  >$LINE"
	done <"/temp/fw_res_$PPID_$$.out"
	echo `date '+%Y-%m-%d %H:%M:%S'`", Results from child process ends ------------------------------------"
	echo `date '+%Y-%m-%d %H:%M:%S'`", Command $exe  ended with RC : $rc"
	rm -f "/temp/fw_res_$PPID_$$.out"
  fi 
}
#
## Execution Starts from here... ##
#
 echo `date '+%Y-%m-%d %H:%M:%S'`", CommandLine >$0 $@"
 rc=0
 pth=.
 vflag=0
 MaxReChk=2
 exe=noExe
 args=
 wTime=480
 si=3
 if [ $# -eq 0 ]; then 
    func_helpInfo
	exit 1
 fi
 while [ $# -gt 0 ]; do
    case "$1" in
        -v | --verbose)  vflag=1
                         echo `date '+%Y-%m-%d %H:%M:%S'`", Running in verbose mode" ;;
	    -f | --file)     pth=$(echo $2 | tr -d '"');
                         shift;;
	    -w | --waitfor)  wTime=$2;
                         shift;;
	    -s | --sleepfor) si=$2;
                         shift;;
        -r | --recheck)  MaxReChk=$2;
                         shift;;
        -e | --exe)      exe=$(echo $2 | tr -d '"');
                         shift;;
        -a | --arg)      args+="$(echo $2 | tr -d '"') ";
                         shift;;						 
	    -h | --help)     func_helpInfo
	                     exit 0;;
	    -*)              func_helpInfo
	                     exit 1;;
         *)              break;;	# terminate while loop
    esac
    shift
 done
 if  [ "$pth"  == "." ]; then 
     func_helpInfo
	 exit 1
 fi
 arg=${arg: -1} 
 func_DeriveTimes
 func_echoDtls
 func_fw
 func_runls
 func_wait4AllFlsDL
 func_runEXE
 
 echo `date '+%Y-%m-%d %H:%M:%S'`", Ending script $0 with RC : $rc"
 exit $rc
 
