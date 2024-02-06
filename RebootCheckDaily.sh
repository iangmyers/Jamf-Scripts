#!/bin/bash

##############
#Created by Ian Myers
#This script is designed to either be triggered with a Launch Daemon or via Jamf Policy on a time bases that works for your environment. 
#It will check up time and propmt/ force restarts if parameters are met. 
#Created 12/20/2023
#Run as sudo when testing outside of Jamf
##############

### Variables ### 
restarttime="6" #Frequency in days of desired restart
RebootMinutes="5" #Reboot timer text in minutes for prompt
Rebootdelay="300" #Reboot timer in seconds for prompt timer. Convert RebootMinutes to seconds.
#IconPath="Your Icon Path Here" #Jamf Helper Icon (Optional)


# Get Uptime
Uptime=$(uptime | awk '{print $3}')

# Sanity Check
echo "Days without reboot: $Uptime"

# Jamf Helper prompt with timer
if [[ $Uptime -ge $restarttime ]]; then
	#JH for user warning
	RebootPrompt=$(/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
	-windowType utility \
	-lockHUD \
	-title "Restart needed" \
	-heading "ALERT: Your Mac has not been restarted for $Uptime days" \
	-description "Your Mac will automatically restart in $RebootMinutes minutes. Please save anything you are working on. To restart now click Restart Now" \
	-button1 "Restart Now" \
	-defaultButton 1 \
	-countdown \
	-timeout $Rebootdelay \
	-alignCountdown right\
	-icon $IconPath)
	
	# Reboot if timer runs out or if button clicked
	if [[ "$RebootPrompt" == "0" ]];then
		# Reboot Command
		shutdown -r now
  
    		# Sanity Check
		echo "Time to reboot"
        
	fi
	exit 0
	
fi

# If not time do something (Optional)		
if [[ $Uptime -le $restarttime ]]; then
	echo "Not time to reboot"

	exit 0
fi
