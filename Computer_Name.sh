#!/bin/bash

##############
#Created by Ian Myers
#This uses a API call and the Jamf Biary commands to set the computer name with the format "Prefix-SN-Username"
#Created 3/16/2023
#Run as sudo when testing outside of Jamf
##############

#API Var
jUsername=$4
jPassword=$5
jUrl=$6

#Var Declaration
PREFIX="Jamf-" #Set to your Prefix
SN=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')
Suffix=$(curl -su "$jUsername:$jPassword" -X GET "$jUrl/computers/serialnumber/$SN" -H "accept: application/xml" | xmllint --xpath '/computer/location/username/text()' -)

#Sanity Check
#echo "$PREFIX, $SN, $Suffix"
#/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -button1 "Close" -description "$PREFIX$SN-$Suffix" -windowType hud -defaultButton 1

#Runs Jamf Bianary command to update name
jamf setComputerName -name "$PREFIX$SN-$Suffix"

#update inventory (not required if an undate inventory is included in the policy)
Jamf recon
