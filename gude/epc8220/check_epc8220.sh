"#!/bin/bash
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
plglastmodi='29.08.2018 - 10:28'

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
        echo "   systemuptime | system Uptime " 		
        echo "   sysinfo      | system Information "
        echo "   ABC          | A - Bank - Power active W Current"
	echo 
	echo " not yet finished "
        echo "   BBC          | B - Bank - Power active W Current"
	echo "   ABT          | A - Bank - Power Total "
	echo "   BBT          | B - Bank - Power Total "
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
# snmpwalk -v 2c -c public 10.147.42.31 1.3.6.1.2.1.1.1.0  | awk '{print $4,$5,$6,$7}'
if [ "$strpart" == "sysinfo" ]; then
	model=$(snmpget -v2c -c "$strCommunity" "$strHostname" 1.3.6.1.2.1.1.1.0  | awk '{print $4,$5,$6,$7}')
	
	echo Model $model
	exit 0

# Current A-bank------------------------------------------------------------------------------------------------------------------------------------------
# snmpwalk -v 2c -c public 10.147.42.31 iso.3.6.1.4.1.28507.38.1.5.1.2.1.4.1 | awk '{print $4}'
elif [ "$strpart" == "ABC" ]; then
      ABankC=$(snmpget -v 2c -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.28507.38.1.5.1.2.1.4.1 | awk '{print $4}')
      
      OUTPUT="ABankcurrent="$ABankC"|ABank="$ABankC";$strWarning;$strCritical;0;90"
      exit 0
      
# System Uptime----------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "systemuptime" ]; then
    	sysuptime=$(snmpget -v2c -c "$strCommunity" "$strHostname"  .1.3.6.1.2.1.1.3.0  | awk '{print $5,$6,$7}' | cut -d . -f 1) 
    	
	echo Uptime $sysuptime
	exit 0


# DISKUSED ---------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "diskused" ]; then
	disk=$(snmpget -v2c -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.4.1 | awk '{print $4}' | sed 's/.\(.*\)/\1/')
	free=$(snmpget -v2c -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.5.1 | awk '{print $4}' | sed 's/.\(.*\)/\1/')
	UNITtest=$(snmpget -v2c -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.4.1 | awk '{print $5}' | sed 's/.*\(.B\).*/\1/')
	UNITtest2=$(snmpget -v2c -c "$strCommunity" "$strHostname" 1.3.6.1.4.1.24681.1.2.17.1.5.1 | awk '{print $5}' | sed 's/.*\(.B\).*/\1/')
        #echo $disk - $free - $UNITtest - $UNITtest2 

	if [ "$UNITtest" == "TB" ]; then
	 factor=$(echo "scale=0; 1000" | bc -l)
	elif [ "$UNITtest" == "GB" ]; then
	 factor=$(echo "scale=0; 100" | bc -l)	 
	else
	 factor=$(echo "scale=0; 1" | bc -l)
	fi

	if [ "$UNITtest2" == "TB" ]; then
	 factor2=$(echo "scale=0; 1000" | bc -l)
	elif [ "$UNITtest2" == "GB" ]; then
	 factor2=$(echo "scale=0; 100" | bc -l)
	else
	 factor2=$(echo "scale=0; 1" | bc -l)
	fi
	
	#echo $factor - $factor2
	disk=$(echo "scale=0; $disk*$factor" | bc -l)
	free=$(echo "scale=0; $free*$factor2" | bc -l)
	
	#debug used=$(echo "scale=0; 9000*1000" | bc -l) 
	used=$(echo "scale=0; $disk-$free" | bc -l)
	
	#echo $disk - $free - $used
	PERC=$(echo "scale=0; $used*100/$disk" | bc -l)
	
	diskF=$(echo "scale=0; $disk/$factor" | bc -l)
	freeF=$(echo "scale=0; $free/$factor" | bc -l)
	usedF=$(echo "scale=0; $used/$factor" | bc -l)

	#wdisk=$(echo "scale=0; $strWarning*$disk/100" | bc -l)
	#cdisk=$(echo "scale=0; $strCritical*$disk/100" | bc -l)
	
        OUTPUT="Total:"$diskF"$UNITtest - Used:"$usedF"$UNITtest - Free:"$freeF"$UNITtest2 - Used Space: $PERC%|Used=$PERC;$strWarning;$strCritical;0;100"
	
	if [ $PERC -ge $strCritical ]; then
		echo "CRITICAL: "$OUTPUT
		exit 2
	elif [ $PERC -ge $strWarning ]; then
		echo "WARNING: "$OUTPUT
		exit 1
	else
		echo "OK: "$OUTPUT
		exit 0
	fi

	
# CPU ----------------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "cpu" ]; then
        CPU=$(snmpget -v2c -Ln -c "$strCommunity" $strHostname 1.3.6.1.4.1.24681.1.2.1.0 -Oqv | sed -E 's/"|\s%//g')

        OUTPUT="CPU Load="$CPU"%|CPU load="$CPU"%;$strWarning;$strCritical;0;100"

        if (( $(echo "$CPU > $strCritical" | bc -l) )); then
               echo "CRITICAL: "$OUTPUT
               exit 2
        elif ((  $(echo "$CPU > $strWarning" | bc -l) )); then
                echo "WARNING: "$OUTPUT
                exit 1
        else
                echo "OK: "$OUTPUT
                exit 0
        fi
	
# CPUTEMP ----------------------------------------------------------------------------------------------------------------------------------------------
elif [ "$strpart" == "cputemp" ]; then
    	TEMP0=$(snmpget -v2c -c "$strCommunity" $strHostname  .1.3.6.1.4.1.24681.1.2.5.0 | awk '{print $4}' | cut -c2-3)
	OUTPUT="CPU Temperature="$TEMP0"C|NAS CPUtermperature="$TEMP0"C;$strWarning;$strCritical;0;90"

    	if [ "$TEMP0" -ge "89" ]; then
            	echo "Cpu temperatur to high!: "$OUTPUT
            	exit 2
    	else
            	if [ $TEMP0 -ge "$strCritical" ]; then
                    	echo "CRITICAL: "$OUTPUT
                    	exit 2
            	fi
            	if [ $TEMP0 -ge "$strWarning" ]; then
                    	echo "WARNING: "$OUTPUT
                    	exit 1
            	fi
            	echo "OK: "$OUTPUT
            	exit 0
    	fi

#----------------------------------------------------------------------------------------------------------------------------------------------------
else
    	echo -e "\nUnknown Part!" && exit "3"
fi
exit 0
