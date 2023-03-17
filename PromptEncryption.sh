#!/bin/bash

##########
# Created by Ian Myers
# 3/17/2023
# Prompts user if Jamf thinks encryption is not enabled
# Computer checks if it is and either updates the inventory in Jamf or Prompts user to enable it via JSS
##########

#Check filevault status
status=$(fdesetup status | awk '{print $NF}' | tr -d .) 
#Pass URL from Jamf policy
PolicyURL=$4

#Sanaity Check
echo $status

#If On
if [[ $status == "On" ]]; then
	#echo "it worked"
	/usr/local/jamf/bin/jamf recon
#If Off
elif [[ $status == "Off" ]]; then
	JamfHelper=$(/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -icon "/Applications/Self Service.app/Contents/Resources/AppIcon.icns" -title "Computer needs to be encrypted" -button1 "OK" -defaultButton 1 -windowType hud -description "Please begin the encryption in Self Service")
	if [[ "$JamfHelper" == "0" ]]; then
		#Opens JSS to encryption policy
		open $PolicyURL
	fi
fi




