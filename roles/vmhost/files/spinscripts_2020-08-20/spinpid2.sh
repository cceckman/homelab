#!/usr/local/bin/bash

# spinpid2.sh for dual fan zones.
VERSION="2020-08-20"
# Run as superuser. See notes at end.

##############################################
#
#  Settings sourced from spinpd2.config
#  in same directory as the script
#
##############################################

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/spinpid2.config"

##############################################
# function get_disk_name
# Get disk name from current LINE of DEVLIST
##############################################
# The awk statement works by taking $LINE as input,
# setting '(' as a _F_ield separator and taking the second field it separates
# (ie after the separator), passing that to another awk that uses
# ',' as a separator, and taking the first field (ie before the separator).
# In other words, everything between '(' and ',' is kept.

# camcontrol output for disks on HBA seems to change every version,
# so need 2 options to get ada/da disk name.
function get_disk_name {
   if [[ $LINE == *",p"* ]] ; then     # for ([a]da#,pass#)
      DEVID=$(echo "$LINE" | awk -F '(' '{print $2}' | awk -F ',' '{print$1}')
   else                                # for (pass#,[a]da#)
      DEVID=$(echo "$LINE" | awk -F ',' '{print $2}' | awk -F ')' '{print$1}')
   fi
}

############################################################
# function print_header
# Called when script starts and each quarter day
############################################################
function print_header {
   DATE=$(date +"%A, %b %d")
   let "SPACES = DEVCOUNT * 5 + 42"  # 5 spaces per drive
   printf "\n%-*s %3s %16s %29s \n" $SPACES "$DATE" "CPU" "New_Fan%" "New_RPM_____________________"
   echo -n "          "
   while read -r LINE ; do
      get_disk_name
      printf "%-5s" "$DEVID"
   done <<< "$DEVLIST"             # while statement works on DEVLIST
   printf "%4s %5s %6s %6s %6s %3s %-7s %s %-4s %5s %5s %5s %5s %5s" "Tmax" "Tmean" "ERRc" "P" "D" "TEMP" "MODE" "CPU" "PER" "FANA" "FAN1" "FAN2" "FAN3" "FAN4"
}

#################################################
# function read_fan_data
#################################################
function read_fan_data {

   # If set by user, read duty cycles, convert to decimal.  Otherwise,
   # the script will assume the duty cycles are what was last set.
	if [ $HOW_DUTY == 1 ] ; then
		DUTY_CPU=$($IPMITOOL raw 0x30 0x70 0x66 0 $ZONE_CPU) # in hex with leading space
		DUTY_CPU=$((0x$(echo $DUTY_CPU)))  # strip leading space and decimalize
		DUTY_PER=$($IPMITOOL raw 0x30 0x70 0x66 0 $ZONE_PER)
		DUTY_PER=$((0x$(echo $DUTY_PER)))
	fi
	
   # Read fan mode, convert to decimal, get text equivalent.
   MODE=$($IPMITOOL raw 0x30 0x45 0) # in hex with leading space
   MODE=$((0x$(echo $MODE)))  # strip leading space and decimalize
   # Text for mode
   case $MODE in
      0) MODEt="Standard" ;;
      1) MODEt="Full" ;;
      2) MODEt="Optimal" ;;
      4) MODEt="HeavyIO" ;;
   esac

   # Get reported fan speed in RPM from sensor data repository.
   # Takes the pertinent FAN line, then 3 to 5 consecutive digits
   SDR=$($IPMITOOL sdr)
   FAN1=$(echo "$SDR" | grep "FAN1" | grep -Eo '[0-9]{3,5}')
   FAN2=$(echo "$SDR" | grep "FAN2" | grep -Eo '[0-9]{3,5}')
   FAN3=$(echo "$SDR" | grep "FAN3" | grep -Eo '[0-9]{3,5}')
   FAN4=$(echo "$SDR" | grep "FAN4" | grep -Eo '[0-9]{3,5}')
   FANA=$(echo "$SDR" | grep "FANA" | grep -Eo '[0-9]{3,5}')

}

##############################################
# function CPU_check_adjust
# Get CPU temp.  Calculate a new DUTY_CPU.
# Send to function adjust_fans.
##############################################
function CPU_check_adjust {
   #   Another IPMITOOL method of checking CPU temp:
   #   CPU_TEMP=$($IPMITOOL sdr | grep "CPU Temp" | grep -Eo '[0-9]{2,5}')
   if [[ $CPU_TEMP_SYSCTL == 1 ]]; then    
       # Find hottest CPU core
       MAX_CORE_TEMP=0
       for CORE in $(seq 0 $CORES)
       do
           CORE_TEMP="$(sysctl -n dev.cpu.${CORE}.temperature | awk -F '.' '{print$1}')"
           if [[ $CORE_TEMP -gt $MAX_CORE_TEMP ]]; then MAX_CORE_TEMP=$CORE_TEMP; fi
       done
       CPU_TEMP=$MAX_CORE_TEMP
   else
       CPU_TEMP=$($IPMITOOL sensor get "CPU Temp" | awk '/Sensor Reading/ {print $4}')
   fi

   DUTY_CPU_LAST=$DUTY_CPU

   # This will break if settings have non-integers
   let DUTY_CPU="$(( (CPU_TEMP - CPU_REF) * CPU_SCALE + DUTY_CPU_MIN ))"

   # Don't allow duty cycle outside min-max
   if [[ $DUTY_CPU -gt $DUTY_CPU_MAX ]]; then DUTY_CPU=$DUTY_CPU_MAX; fi
   if [[ $DUTY_CPU -lt $DUTY_CPU_MIN ]]; then DUTY_CPU=$DUTY_CPU_MIN; fi
      
   adjust_fans $ZONE_CPU $DUTY_CPU $DUTY_CPU_LAST

   # Use this short CPU cycle to also allow PER fans to come down 
   # if PD < 0 and drives are at least 1 C below setpoint 
   # (e.g, after high demand or if 100% at startup).
   # With multiple CPU cycles and no new drive temps, this will
   # drive fans to DUTY_PER_MIN, but that's ok if drives are that cool.
   # However, this is experimental.
	if [[ PD -lt 0 && (( $(bc <<< "scale=2; $Tmean < ($SP-1)") == 1 )) ]]; then
		DUTY_PER_LAST=$DUTY_PER
		DUTY_PER=$(( DUTY_PER + PD ))
		# Don't allow duty cycle below min
		if [[ $DUTY_PER -lt $DUTY_PER_MIN ]]; then DUTY_PER=$DUTY_PER_MIN; fi
		# pass to the function adjust_fans
		adjust_fans $ZONE_PER $DUTY_PER $DUTY_PER_LAST
	fi

	sleep $CPU_T
	
	if [ $CPU_LOG_YES == 1 ] ; then
		print_interim_CPU | tee -a $CPU_LOG >/dev/null
	fi
	
	# This will call user-defined function if it exists (see config).
	declare -f -F Post_CPU_check_adjust >/dev/null && Post_CPU_check_adjust
}

##############################################
# function DRIVES_check_adjust
# Print time on new log line.
# Go through each drive, getting and printing
# status and temp.  Calculate max and mean
# temp, then calculate PID and new duty.
# Call adjust_fans.
##############################################
function DRIVES_check_adjust {
   Tmax=0; Tsum=0  # initialize drive temps for new loop through drives
   i=0             # initialize count of spinning drives
   while read -r LINE ; do
      get_disk_name
      /usr/local/sbin/smartctl -a -n standby "/dev/$DEVID" > /var/tempfile
      RETURN=$?  # have to preserve return value or it changes
      BIT0=$(( RETURN & 1 ))
      BIT1=$(( RETURN & 2 ))
      if [ $BIT0 -eq 0 ]; then
         if [ $BIT1 -eq 0 ]; then
            STATUS="*"  # spinning
         else  # drive found but no response, probably standby
            STATUS="_"
         fi
      else   # smartctl returns 1 (00000001) for missing drive
         STATUS="?"
      fi

      TEMP=""
      # Update temperatures each drive; spinners only
      if [ "$STATUS" == "*" ] ; then
         # Taking 10th space-delimited field for most SATA:
         if grep -Fq "Temperature_Celsius" /var/tempfile ; then
         	TEMP=$( cat /var/tempfile | grep "Temperature_Celsius" | awk '{print $10}')
         # Else assume SAS, their output is:
         #     Transport protocol: SAS (SPL-3) . . .
         #     Current Drive Temperature: 45 C
         else
         	TEMP=$( cat /var/tempfile | grep "Drive Temperature" | awk '{print $4}')
         fi
         let "Tsum += $TEMP"
         if [[ $TEMP > $Tmax ]]; then Tmax=$TEMP; fi;
         let "i += 1"
      fi
      printf "%s%-2d  " "$STATUS" "$TEMP"
   done <<< "$DEVLIST"

   DUTY_PER_LAST=$DUTY_PER
   
   # if no disks are spinning
	if [ $i -eq 0 ]; then
		Tmean=""; Tmax=""; P=""; D=""; ERRc=""
		DUTY_PER=$DUTY_PER_MIN
	else
	# summarize, calculate PD and print Tmax and Tmean
		# Need ERRc value if all drives had been spun down last time
		if [[ $ERRc == "" ]]; then ERRc=0; fi
      
		Tmean=$(bc <<< "scale=2; $Tsum / $i" )
		ERRp=$ERRc		# save previous error before calculating current
		ERRc=$(bc <<< "scale=2; ($Tmean - $SP) / 1" )
		P=$(bc <<< "scale=3; ($Kp * $ERRc) / 1" )
		D=$(bc <<< "scale=4; $Kd * ($ERRc - $ERRp) / $DRIVE_T" )
		PD=$(bc <<< "$P + $D" )  # add corrections

		# round for printing
		Tmean=$(printf %0.2f "$Tmean")
		ERRc=$(printf %0.2f "$ERRc")
		P=$(printf %0.2f "$P")
		D=$(printf %0.2f "$D")
		PD=$(printf %0.f "$PD")  # must be integer for duty

		let "DUTY_PER = $DUTY_PER_LAST + $PD"

		# Don't allow duty cycle outside min-max
		if [[ $DUTY_PER -gt $DUTY_PER_MAX ]]; then DUTY_PER=$DUTY_PER_MAX; fi
		if [[ $DUTY_PER -lt $DUTY_PER_MIN ]]; then DUTY_PER=$DUTY_PER_MIN; fi
	fi

   # DIAGNOSTIC variables - uncomment for troubleshooting:
   # printf "\n DUTY_PER=%s, DUTY_PER_LAST=%s, DUTY=%s, Tmean=%s, ERRp=%s \n" "${DUTY_PER:---}" "${DUTY_PER_LAST:---}" "${DUTY:---}" "${Tmean:---}" $ERRp

   # pass to the function adjust_fans
   adjust_fans $ZONE_PER $DUTY_PER $DUTY_PER_LAST
   
   # DIAGNOSTIC variables - uncomment for troubleshooting:
   # printf "\n DUTY_PER=%s, DUTY_PER_LAST=%s, DUTY=%s, Tmean=%s, ERRp=%s \n" "${DUTY_PER:---}" "${DUTY_PER_LAST:---}" "${DUTY:---}" "${Tmean:---}" $ERRp

   # print current Tmax, Tmean
   printf "^%-3s %5s" "${Tmax:---}" "${Tmean:----}"
	
	# This will call user-defined function if it exists (see config).
	declare -f -F Post_DRIVES_check_adjust >/dev/null && Post_DRIVES_check_adjust
}

##############################################
# function adjust_fans
# Zone, new duty, and last duty are passed as parameters
##############################################
function adjust_fans {
   # parameters passed to this function
   ZONE=$1
   DUTY=$2
   DUTY_LAST=$3

   # Change if different from last duty, or the first time.
   if [[ $DUTY -ne $DUTY_LAST ]] || [[ FIRST_TIME -eq 1 ]]; then
      # Set new duty cycle. "echo -n ``" prevents newline generated in log
      echo -n "$($IPMITOOL raw 0x30 0x70 0x66 1 "$ZONE" "$DUTY")"
   fi
   FIRST_TIME=0
}

##############################################
# function print_interim_CPU 
# Sent to a separate file by the call
# in CPU_check_adjust{}
##############################################
function print_interim_CPU {
   RPM=$($IPMITOOL sdr | grep  "$RPM_CPU" | grep -Eo '[0-9]{2,5}')
   # print time on each line
   TIME=$(date "+%H:%M:%S"); echo -n "$TIME  "
   printf "%7s %5d %5d \n" "${RPM:----}" "$CPU_TEMP" "$DUTY"
}

##############################################
# function mismatch_test 
# Tests for mismatch
# between fan duty and fan RPMs
##############################################

function mismatch_test {
	MISMATCH=0; MISMATCH_CPU=0; MISMATCH_PER=0

	# ${!RPM_*} gets updated value of the variable RPM_* points to
	if [[ (DUTY_CPU -ge 95 && ${!RPM_CPU} -lt RPM_CPU_MAX) || (DUTY_CPU -lt 25 && ${!RPM_CPU} -gt RPM_CPU_30) ]] ; then
		MISMATCH=1; MISMATCH_CPU=1
		printf "\n%s\n" "Mismatch between CPU Duty and RPMs -- DUTY_CPU=$DUTY_CPU; RPM_CPU=${!RPM_CPU}"
	fi
	if [[ (DUTY_PER -ge 95 && ${!RPM_PER} -lt RPM_PER_MAX) || (DUTY_PER -lt 25 && ${!RPM_PER} -gt RPM_PER_30) ]] ; then
		MISMATCH=1; MISMATCH_PER=1
		printf "\n%s\n" "Mismatch between PER Duty and RPMs -- DUTY_PER=$DUTY_PER; RPM_PER=${!RPM_PER}"
	fi
}

##############################################
# function force_set_fans 
# Used each cycle if a mismatch is detected and
# after BMC reset
##############################################
function force_set_fans {
	if [ $MISMATCH_CPU == 1 ]; then
		FIRST_TIME=1  # forces adjust_fans to do it
		adjust_fans $ZONE_CPU $DUTY_CPU $DUTY_CPU_LAST
		echo "Attempting to fix CPU mismatch  "
		sleep 5
	fi
	if [ $MISMATCH_PER == 1 ]; then
		FIRST_TIME=1
		adjust_fans $ZONE_PER $DUTY_PER $DUTY_PER_LAST
		echo "Attempting to fix PER mismatch  "
		sleep 5
	fi
}

##############################################
# function reset_bmc 
# Triggered after 2 attempts to fix mismatch
# between fan duty and fan RPMs
##############################################

function reset_bmc {
	TIME=$(date "+%H:%M:%S"); echo -n "$TIME  "
	echo -n "Resetting BMC after second attempt failed to fix mismatch -- "
	$IPMITOOL bmc reset cold
	sleep 120
	read_fan_data
}

#####################################################
# SETUP
# All this happens only at the beginning
# Initializing values, list of drives, print header
#####################################################
# Print settings at beginning of log
printf "\n****** SETTINGS ******\n"
printf "CPU zone %s; Peripheral zone %s\n" $ZONE_CPU $ZONE_PER
printf "CPU fans min/max duty cycle: %s/%s\n" $DUTY_CPU_MIN $DUTY_CPU_MAX
printf "PER fans min/max duty cycle: %s/%s\n" $DUTY_PER_MIN $DUTY_PER_MAX
printf "CPU fans - measured RPMs at 30%% and 100%% duty cycle: %s/%s\n" $RPM_CPU_30 $RPM_CPU_MAX
printf "PER fans - measured RPMs at 30%% and 100%% duty cycle: %s/%s\n" $RPM_PER_30 $RPM_PER_MAX
printf "Drive temperature setpoint (C): %s\n" $SP
printf "Kp=%s, Kd=%s\n" $Kp $Kd
printf "Drive check interval (main cycle; minutes): %s\n" $DRIVE_T
printf "CPU check interval (seconds): %s\n" $CPU_T
printf "CPU reference temperature (C): %s\n" $CPU_REF
printf "CPU scalar: %s\n" $CPU_SCALE

if [ $HOW_DUTY == 1 ] ; then
	printf "Reading fan duty from board \n"
else 
	printf "Assuming fan duty as set \n" ; fi
	
# Check if CPU Temp is available via sysctl (will likely fail in a VM)
CPU_TEMP_SYSCTL=$(($(sysctl -a | grep dev.cpu.0.temperature | wc -l) > 0))
if [[ $CPU_TEMP_SYSCTL == 1 ]]; then
	printf "Getting CPU temperatures via sysctl \n"
	# Get number of CPU cores to check for temperature
	# -1 because numbering starts at 0
	CORES=$(($(sysctl -n hw.ncpu)-1))
else
	printf "Getting CPU temperature via ipmitool (sysctl not available) \n"
fi

CPU_LOOPS=$( bc <<< "$DRIVE_T * 60 / $CPU_T" )  # Number of whole CPU loops per drive loop
I=0; ERRc=0  # Initialize errors to 0
FIRST_TIME=1

# Alter RPM thresholds to allow some slop
RPM_CPU_30=$(echo "scale=0; 1.2 * $RPM_CPU_30 / 1" | bc)
RPM_CPU_MAX=$(echo "scale=0; 0.8 * $RPM_CPU_MAX / 1" | bc)
RPM_PER_30=$(echo "scale=0; 1.2 * $RPM_PER_30 / 1" | bc)
RPM_PER_MAX=$(echo "scale=0; 0.8 * $RPM_PER_MAX / 1" | bc)

# Get list of drives
DEVLIST1=$(/sbin/camcontrol devlist)
# Remove lines with non-spinning devices; edit as needed
# You could use another strategy, e.g., find something in the camcontrol devlist 
# output that is unique to the drives you want, for instance only WDC drives:
# if [[ $LINE != *"WDC"* ]] . . .
DEVLIST="$(echo "$DEVLIST1"|sed '/KINGSTON/d;/ADATA/d;/SanDisk/d;/OCZ/d;/LSI/d;/EXP/d;/INTEL/d;/TDKMedia/d;/SSD/d;/VMware/d;/Enclosure/d;/Card/d;/Flash/d')"
DEVCOUNT=$(echo "$DEVLIST" | wc -l)

# These variables hold the name of the other variables, whose
# value will be obtained by indirect reference.  Don't ask.
if [[ ZONE_PER -eq 0 ]]; then
   RPM_PER=FAN1
   RPM_CPU=FANA
else
   RPM_PER=FANA
   RPM_CPU=FAN1
fi

read_fan_data

# If mode not Full, set it to avoid BMC changing duty cycle
# Need to wait a tick or it may not get next command
# "echo -n" to avoid annoying newline generated in log
if [[ MODE -ne 1 ]]; then
   echo -n "$($IPMITOOL raw 0x30 0x45 1 1)"
   sleep 1
fi

# Need to start fan duty at a reasonable value if fans are
# going fast or we didn't read DUTY_* in read_fan_data
# (second test is TRUE if DUTY_* is unset). 
if [[ ${!RPM_PER} -ge RPM_PER_MAX || -z ${DUTY_PER+x} ]]; then
   echo -n "$($IPMITOOL raw 0x30 0x70 0x66 1 $ZONE_PER 50)"
   DUTY_PER=50; sleep 1
fi
if [[ ${!RPM_CPU} -ge RPM_CPU_MAX || -z ${DUTY_CPU+x} ]]; then
   echo -n "$($IPMITOOL raw 0x30 0x70 0x66 1 $ZONE_CPU 50)"
   DUTY_CPU=50; sleep 1
fi

# Before starting, go through the drives to report if
# smartctl return value indicates a problem (>2).
# Use -a so that all return values are available.
while read -r LINE ; do
   get_disk_name
   /usr/local/sbin/smartctl -a -n standby "/dev/$DEVID" > /var/tempfile
   if [ $? -gt 2 ]; then
      printf "\n"
      printf "*******************************************************\n"
      printf "* WARNING - Drive %-4s has a record of past errors,   *\n" "$DEVID"
      printf "* is currently failing, or is not communicating well. *\n"
      printf "* Use smartctl to examine the condition of this drive *\n"
      printf "* and conduct tests. Status symbol for the drive may  *\n"
      printf "* be incorrect (but probably not).                    *\n"
      printf "*******************************************************\n"
   fi
done <<< "$DEVLIST"

printf "\n%s %36s %s \n" "Key to drive status symbols:  * spinning;  _ standby;  ? unknown" "Version" $VERSION
print_header

# for first round of printing
CPU_TEMP=$(echo "$SDR" | grep "CPU Temp" | grep -Eo '[0-9]{2,5}')

# Initialize CPU log
if [ $CPU_LOG_YES == 1 ] ; then
	printf "%s \n%s \n%17s %5s %5s \n" "$DATE" "Printed every CPU cycle" $RPM_CPU "Temp" "Duty" | tee $CPU_LOG >/dev/null
fi

###########################################
# Main loop through drives every DRIVE_T minutes
# and CPU every CPU_T seconds
###########################################
while true ; do
   # Print header every quarter day.  awk removes any
   # leading 0 so it is not seen as octal
   HM=$(date +%k%M)
   HM=$( echo $HM | awk '{print $1 + 0}' )
   R=$(( HM % 600 ))  # remainder after dividing by 6 hours
   if (( R < DRIVE_T )); then
      print_header;
   fi

#
# Main stuff
#
	echo                                         # start new line
	TIME=$(date "+%H:%M:%S"); echo -n "$TIME  "  # print time on each line
	
	DRIVES_check_adjust                          # prints drive data also
	
	sleep 5  # Let fans equilibrate to duty before reading them
	read_fan_data


   printf "%7s %6s %6.6s %4s %-7s %3d %3d %6s %5s %5s %5s %5s" "${ERRc:----}" "${P:----}" "${D:----}" "$CPU_TEMP" $MODEt $DUTY_CPU $DUTY_PER "${FANA:----}" "${FAN1:----}" "${FAN2:----}" "${FAN3:----}" "${FAN4:----}"

# Test loop for BMC reset.  Exit loop if no mismatch found between duty and rpm, 
# or after 2 attempts to fix lead to bmc reset and a third attempt to fix.  
# This should happen after reading fans so CPU loops don't result in false mismatch.

	ATTEMPTS=0  # Number of attempts to fix duties
	mismatch_test
	
	while true; do
		
		if [ $MISMATCH == 1 ]; then
			force_set_fans
			let "ATTEMPTS += 1"
			read_fan_data
			mismatch_test
		else
			break   # exit loop
		fi

		if [ ATTEMPTS == 2 ]; then
			if [ MISMATCH == 1 ]; then
				reset_bmc
				force_set_fans
				read_fan_data
				mismatch_test
			else
				break   # exit loop
			fi
		fi

		if [ $ATTEMPTS == 3 ]; then
			break
		fi
	done


	# CPU loop
	i=0
	while [ $i -lt "$CPU_LOOPS" ]; do
		CPU_check_adjust
		let i=i+1
	done
done

# For SuperMicro motherboards with dual fan zones.  
# Adjusts fans based on drive and CPU temperatures.
# Includes disks on motherboard and on HBA.
# Mean drive temp is maintained at a setpoint using a PID algorithm.  
# CPU temp need not and cannot be maintained at a setpoint, 
# so PID is not used; instead fan duty cycle is simply
# increased with temp using reference and scale settings.

# Drives are checked and fans adjusted on a set interval, such as 5 minutes.
# Logging is done at that point.  CPU temps can spike much faster,
# so are checked and logged at a shorter interval, such as 1-15 seconds.
# CPUs with high TDP probably require short intervals.

# Logs:
#   - Disk status (* spinning or _ standby)
#   - Disk temperature (Celsius) if spinning
#   - Max and mean disk temperature
#   - Temperature error and PID variables
#   - CPU temperature
#   - RPM for FANA and FAN1-4 before new duty cycles
#   - Fan mode
#   - New fan duty cycle in each zone
#   - In CPU log:
#        - RPM of the first fan in CPU zone (FANA or FAN1
#        - CPU temperature
#        - new CPU duty cycle

#  Relation between percent duty cycle, hex value of that number,
#  and RPMs for my fans.  RPM will vary among fans, is not
#  precisely related to duty cycle, and does not matter to the script.
#  It is merely reported.
#
#  Percent      Hex         RPM
#  10         A     300
#  20        14     400
#  30        1E     500
#  40        28     600/700
#  50        32     800
#  60        3C     900
#  70        46     1000/1100
#  80        50     1100/1200
#  90        5A     1200/1300
# 100        64     1300

################
# Tuning Advice
################
# PID tuning advice on the internet generally does not work well in this application.
# First run the script spincheck.sh and get familiar with your temperature and fan variations without any intervention.
# Choose a setpoint that is an actual observed Tmean, given the number of drives you have.  It should be the Tmean associated with the Tmax that you want.
# Start with Kp low.  Find the lowest ERRc (which is Tmean - setpoint) in the output other than 0 (don't worry about sign +/-).  Set Kp to 0.5 / ERRc, rounded up to an integer.  My lowest ERRc is 0.14.  0.5 / 0.14 is 3.6, and I find Kp = 4 is adequate.  Higher Kp will give a more aggressive response to error, but the downside may be overshooting the setpoint and oscillation.  Kd offsets that, but raising them both makes things unstable and harder to tune.
# Set Kd at about Kp*10
# Get Tmean within ~0.3 degree of SP before starting script.
# Start script and run for a few hours or so.  If Tmean oscillates (best to graph it), you probably need to reduce Kd.  If no oscillation but response is too slow, raise Kd.
# Stop script and get Tmean at least 1 C off SP.  Restart.  If there is overshoot and it goes through some cycles, you may need to reduce Kd.
# If you have problems, examine P and D in the log and see which is messing you up. 

# Uses joeschmuck's smartctl method for drive status (returns 0 if spinning, 2 in standby)
# https://forums.freenas.org/index.php?threads/how-to-find-out-if-a-drive-is-spinning-down-properly.2068/#post-28451
# Other method (camcontrol cmd -a) doesn't work with HBA
