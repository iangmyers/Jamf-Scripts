#!/bin/bash

############
# Created by Ian Myers
# 3/20/2023
# Simple Jamf Helper templete. Currently set to install Slack. Change the varables to fit your needs
############

#Var
EventTrigger=InstallSlack
Title1="Slack"
Header1="Install Slack?"
Header2="Are you sure?"
Description1="Would you like to install the latest version of Slack?"
Description2="Slack is an important tool in the workplace. Are you sure you don't want to install it?"
Icon="/Applications/Slack.app/Contents/Resources/app.icns"


# Prompt user with a Jamf helper window asking if they want to install application
result=$( /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
-windowType hud -title "$Title1" -heading "$Header1" \
-description "$Description1?" \
-button1 "Yes" -button2 "No" -defaultButton 1 -cancelButton 2 -icon $Icon )

if [ "$result" == "0" ]; then
    # User chose to install, so let's trigger the application installation policy
    /usr/local/bin/jamf policy -event $EventTrigger
elif [ "$result" == "2" ]; then
    # User chose not to install, prompt again to confirm
    confirm=$( /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
    -windowType hud -title "$Title1" -heading "$Header2" \
    -description "$Description2" \
    -button1 "Yes, I'm sure" -button2 "No, let me install it" -defaultButton 1 -cancelButton 2 -icon $Icon )
    if [ "$confirm" == "2" ]; then
        # User changed their mind, let's trigger the application installation policy
        /usr/local/bin/jamf policy -event $EventTrigger
    fi
fi
