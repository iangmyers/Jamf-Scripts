#!/bin/bash

##############
#Created by Ian Myers
#This script is designed to either be triggered daily with a Launch Daemon or via Jamf Policy on a daily bases to check up time and propmt/ force restarts. 
#Created 12/20/2023
#Run as sudo when testing outside of Jamf
##############

### Variables ### 
restarttime="7" #Frequency in days of desired restart
RebootMinutes="5" #Reboot timer text for prompt
Rebootdelay="300" #Reboot timer in seconds for prompt timer

# Get Uptime
Uptime=$(uptime | awk '{print $3}')

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
	-alignCountdown right)
	
	# Reboot if timer runs out or if button clicked
	if [[ "$RebootPrompt" == "0" ]];then
		#Reboot Command
		shutdown -r now
  
    #Sanity Check
		#Say "Reboot!"
        
	fi
	exit 0
	
fi

# If not time do something (Optional)		
if [[ $Uptime -le $restarttime ]]; then
	echo "Not time to reboot"

	exit 0
fi
