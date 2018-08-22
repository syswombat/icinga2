"/usr/lib/nagios/plugins/check_apt_wrapper.sh" 106L, 3262C
#!/bin/bash
# Purpose: Script wrapper for the ITL check_yum plugin to add additional output (names of the packages to be updated)
# as well give the ability to handle states as you please
# Note: This is also meant as kind of a "beginner's tutorial" for script wrappers with Icinga.
# Feel free to ask me (@Watermelon) for any tips or questions you might have after you read through this script's functions. Enjoy!
# Exit codes: OK(0), WARNING(1), CRITICAL(2), UNKNOWN(3)

# function to help the user out with the usage of this script

usage() {
        exit 3;
        }
 15
 16 # check for command line arguments
 17     while getopts ":t:s:h:" option; do
 18         case "${option}" in
 19                 t) timeout=${OPTARG};;
 20                 s) security=${OPTARG};;
 21                 h) usage;;
 22                 *) usage;;
 23         esac
 24 done
 25
 26 # Resets position of first non-option argument
 27       shift "$((OPTIND-1))"
 28
 29
 30 # ensures the timeout is set as default 60 seconds if not supplied via command
 31 if [ -z "${timeout}" ]; then
 32           timeout=60
 33 fi
 34
 35   CMD=""
 36
 37   # handle "s" flag
 38   if [ -z "${security}" ]; then
 39             security="off"
 40     elif [[ "$security" == "on" ]]; then
 41               CMD="--security"
 42       elif [[ "$security" == "off" ]]; then
 43                 :
 44         else
 45                   usage
 46    fi
 47
 48    EXITCODE="0"
 49
 50 # gets the number of updates from the original check_apt command
 51    NUMUPDATES="$(/usr/lib/nagios/plugins/check_apt -t ${timeout} 2>/dev/null | awk '{print $1 ";" $5}')"
 52
 53           # handle check_yum plugin timeout
 54           if [[ ${NUMUPDATES} == "APT;self" ]]; then
 55                     echo "Error: Timeout exceeded (${timeout} seconds)"
 56                       exit 3
 57               fi
 58
 59 # separates the numbers into variables
 60    NUMSECURITYUPDATES="$(echo $NUMUPDATES |cut -d';' -f1)"
 61    NUMOTHERUPDATES="$(echo $NUMUPDATES |cut -d';' -f2)"
 62
 63 # regex for numbers
 64               numcheck='^[0-9]+$'
 65
 66 # checks to see if the number of updates is actually a number
 67          if ! [[ ${NUMSECURITYUPDATES} =~ ${numcheck} ]]; then
 68                         OUTPUT="$(/usr/lib/nagios/plugins/check_apt 2>/dev/null)"
 69                           echo "Error - Plugin output: ${OUTPUT}"
 70                             exit 3
 71          fi
 72
 73 # if there are security updates, then exit with critical
 74         if [[ ${NUMSECURITYUPDATES} > "0" ]]; then
 75                               EXITCODE="2"
 76            else
 # if there are non-security updates, then exit with warning
                  if [[ ${NUMOTHERUPDATES} > "0" ]]; then
                                EXITCODE="1"
                          else
                              EXITCODE="0"
                  fi
          fi
 
 # output number of updates along with perf data and thresholds
          echo "${NUMSECURITYUPDATES} Security Updates Available,
                ${NUMOTHERUPDATES} Non-Security Updates Available | 'security_updates'=
                ${NUMSECURITYUPDATES};;1;; 'nonsecurity_updates'=
                ${NUMOTHERUPDATES};;1;;"
 
 # stores output of 'yum check-update' into an array (updateArr) using mapfile
         mapfile -t updateArr < <( apt list -u ${CMD})

 # iterate through output array
         for index in ${!updateArr[*]}
         do
         echo "${updateArr[${index}]}"
         done

         exit ${EXITCODE}

# Original script by watermelon at monitoring-portal.org
# Please report any bugs that you might find with this so that I can improve this script!

#monitoringlove
