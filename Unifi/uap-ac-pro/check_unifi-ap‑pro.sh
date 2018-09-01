#!/bin/bash
############################# Written and Manteined by Vincent Kocher     ###############
#
#	copyright (c) 2018 vincent kocher 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; 
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# contact the author directly for more information at: vkocher@kozo.ch
##########################################################################################
#Version 0.0.1e
plgVer=0.0.1fa
plglastmodi='29.08.2018 - 21:01 line 76-78'

if [ ! "$#" == "5" ]; then
        echo "==========================================================================================="
	echo "some information about this plugin:"
	echo "-----------------------------------"
	echo
        echo "  check_epc8220.sh - Version/Last change: "$plgVer" / "$plglastmodi
        echo
	echo "  Plugin will show some Information about the Gude Expert Power Controll 8220-1"
	echo
	echo
	echo "  Example for systemuptim: ./check_epc8220.sh 10.147.42.31 public systemuptime 0 0"
	echo "                   critical and warning musst not be empty"
	echo
	echo " working is:"		
	echo 
	echo " not yet finished "
        echo " user Connected"    .1.3.6.1.4.1.41112.1.6.1.2.1.8
	echo
	echo
	echo 
	echo "============================================================================================="
        exit 3
fi

strHostname=$1
strCommunity=$2
strpart=$3
strWarning=$4
strCritical=$5

# Check if Power Control is online
TEST=$(snmpstatus -v2c $strHostname -c "$strCommunity" -t 5 -r 0 2>&1) 
# echo "Test: $TEST"; 
if [ "$TEST" == "Timeout: No Response from $strHostname" ]; then 
echo "CRITICAL: SNMP to $strHostname is not available or wrong community string"; 
exit 2; 
fi

# System Info------------------------------------------------------------------------------------------------------------------------------------------
# snmpwalk -v 2c -c public 10.147.42.54 .1.3.6.1.4.1.41112.1.6.3.3.0  | awk '{print $4}'
# snmpwalk -v 2c -c public 10.147.42.54 .1.3.6.1.4.1.41112.1.6.3.6.0  | awk '{print $4}'
if [ "$strpart" == "sysinfo" ]; then
	  model=$(snmpget -v2c -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.41112.1.6.3.3.0  | awk '{print $4}')
	version=$(snmpget -v2c -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.41112.1.6.3.6.0  | awk '{print $4}')
	
	echo Model $model
	echo Version $version
	exit 0

# Current A-bank------------------------------------------------------------------------------------------------------------------------------------------
# snmpwalk -v 2c -c public 10.147.42.31 iso.3.6.1.4.1.28507.38.1.5.1.2.1.4.1 | awk '{print $4}'
elif [ "$strpart" == "ABC" ]; then
      ABankC=$(snmpget -v 2c -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.28507.38.1.5.1.2.1.4.1 | awk '{print $4}')
      
       OUTPUT="ABankcurrent="$ABankC"|A-Bank - Power active current watt="$ABankC";$strWarning;$strCritical;"
       echo ABankC $ABankC
       echo test $OUTPUT
 
 	exit 0
      
# System Uptime----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "systemuptime" ]; then
    	sysuptime=$(snmpget -v2c -c "$strCommunity" "$strHostname"  .1.3.6.1.2.1.1.3.0  | awk '{print $5,$6,$7}' | cut -d . -f 1) 
    	
	echo Uptime $sysuptime
	exit 0

#----------------------------------------------------------------------------------------------------------------------------------------------------
else
    	echo -e "\nUnknown Part! " && exit "3"
fi
exit 0
