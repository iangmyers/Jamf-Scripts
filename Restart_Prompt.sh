#!/bin/bash

# Created by: Ian Myers
# Finds boot time and displays it the users with Jamf Helper to encourage more frequent restart

# Store boot time in variable
boottime=$(sysctl kern.boottime | awk '{print $5}' | tr -d ,)

echo $boottime

# Format in a way Jamf Pro can understand
bootTimeFormatted=$(date -jf %s $boottime +%F\ %T)

# Basic Prompt with Jamf Helper
response=$(/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -icon "/Applications/Self Service.app/Contents/Resources/AppIcon.icns" -title "Computer needs a restart" -button2 "Cancel" -button1 "Restart" -defaultButton 1 -windowType hud -description "Your computer has not restarted since: $bootTimeFormatted")

# Test Expression based on answer
if [[ "$response" == "0" ]];then
	/usr/local/jamf/bin/jamf policy -event restart 
elif [[ "$response" == "2" ]];then
	echo "The user chose not restart"
fi
