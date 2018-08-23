#!/bin/bash
# cd /usr/lib/nagios/plugins/
# wget 
# chmod +x check_apt_wrapper.sh
# Purpose: Script wrapper for the ITL check_yum plugin to add additional output (names of the packages to be updated)
# as well give the ability to handle states as you please
# Note: This is also meant as kind of a "beginner's tutorial" for script wrappers with Icinga.
# Feel free to ask me (@Watermelon) for any tips or questions you might have after you read through this script's functions. Enjoy!
# Exit codes: OK(0), WARNING(1), CRITICAL(2), UNKNOWN(3)

# function to help the user out with the usage of this script

usage() {
        exit 3;
        }
 
 # check for command line arguments
 while getopts ":t:s:h:" option; do
         case "${option}" in
                 t) timeout=${OPTARG};;
                 s) security=${OPTARG};;
                 h) usage;;
                 *) usage;;
          esac
 done
 
 # Resets position of first non-option argument
       shift "$((OPTIND-1))"
 
 # ensures the timeout is set as default 60 seconds if not supplied via command
 if [ -z "${timeout}" ]; then
            timeout=60
 fi
 
 CMD=""
 
 # handle "s" flag
    if [ -z "${security}" ]; then
              security="off"
     elif [[ "$security" == "on" ]]; then
                CMD="--security"
     elif [[ "$security" == "off" ]]; then
                  :
          else
                    usage
    fi
 
    EXITCODE="0"
 

# gets the number of updates from the original check_apt command
    NUMUPDATES="$(/usr/lib/nagios/plugins/check_apt -t ${timeout} 2>/dev/null | awk '{print $1 ";" $5}')"

# handle check_yum plugin timeout
           if [[ ${NUMUPDATES} == "APT;self" ]]; then
                     echo "Error: Timeout exceeded (${timeout} seconds)"
                       exit 3
               fi

# separates the numbers into variables
    NUMSECURITYUPDATES="$(echo $NUMUPDATES |cut -d';' -f1)"
    NUMOTHERUPDATES="$(echo $NUMUPDATES |cut -d';' -f2)"

# regex for numbers
               numcheck='^[0-9]+$'

# checks to see if the number of updates is actually a number
          if ! [[ ${NUMSECURITYUPDATES} =~ ${numcheck} ]]; then
                         OUTPUT="$(/usr/lib/nagios/plugins/check_apt 2>/dev/null)"
                         echo "Error - Plugin output: ${OUTPUT}"
                            exit 3
          fi

# if there are security updates, then exit with critical
          if [[ ${NUMSECURITYUPDATES} > "0" ]]; then
                                EXITCODE="2"
          else
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
