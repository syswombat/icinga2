#!/bin/bash
############################# Written and Manteined by vincent kocher     ###############
# wget https://raw.githubusercontent.com/syswombat/icinga2/master/gude/epc8220/check_epc8220.sh
# chmod +x check_epc8220.sh
#	copyright (c) 2018 Vincent Kocher 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; 
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
##########################################################################################
#Version 0.0.1
plgVer=0.0.1b

if [ ! "$#" == "5" ]; then
        echo
        echo "check_epc8220 - Version: "$plgVer
        echo
      	echo
        echo " Example for fans: ./check_epc8220.sh 10.147.42.31 public systemuptime"
	echo
        exit 3
fi

strHostname=$1
strCommunity=$2
strpart=$3
strWarning=$4
strCritical=$5

# Check if EPC8220 is online
TEST=$(snmpstatus -v2c $strHostname -c "$strCommunity" -t 5 -r 0 2>&1) 
# echo "Test: $TEST"; 
if [ "$TEST" == "Timeout: No Response from $strHostname" ]; then 
echo "CRITICAL: SNMP to $strHostname is not available or wrong community string"; 
exit 2; 
fi


# System Uptime----------------------------------------------------------------------------------------------------------------------------------------
#                             snmpget -v 2c -c public 10.147.42.31  1.3.6.1.2.1.1.3.0  | awk '{print $5,$6,$7}' | cut -d . -f 1
if [ "$strpart" == "systemuptime" ]; then
    	sysuptime=$(snmpget -v 2c -c "$strCommunity" "$strHostname" 1.3.6.1.2.1.1.3.0  | awk '{print $5,$6,$7}' | cut -d . -f 1
    	
    	
	echo System Uptime $sysuptime
	exit 0
fi
# System Info------------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "sysinfo" ]; then
	model=$(snmpget -v2c -c "$strCommunity" "$strHostname"  .1.3.6.1.4.1.24681.1.2.12.0 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/')
	hdnum=$(snmpget -v2c -c "$strCommunity" "$strHostname"  .1.3.6.1.4.1.24681.1.2.10.0 | awk '{print $4}')
	VOLCOUNT=$(snmpget -v2c -c "$strCommunity" "$strHostname" .1.3.6.1.4.1.24681.1.2.16.0 | awk '{print $4}')
	name=$(snmpget -v2c -c "$strCommunity" "$strHostname"  .1.3.6.1.4.1.24681.1.2.13.0  | awk '{print $4}' | sed 's/^"\(.*\)$/\1/')
	firmware=$(snmpget -v2c -c "$strCommunity" "$strHostname"  .1.3.6.1.2.1.47.1.1.1.1.9.1 | awk '{print $4}' | sed 's/^"\(.*\)$/\1/')

	echo NAS $name, Model $model, Firmware $firmware, Max HD number $hdnum, No. Volume $VOLCOUNT
	exit 0

#----------------------------------------------------------------------------------------------------------------------------------------------------
else
    	echo -e "\nUnknown Part!" && exit "3"
fi
exit 0
