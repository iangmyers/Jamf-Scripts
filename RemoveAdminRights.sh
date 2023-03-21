#!/bin/bash

###########
# Created by Ian Myers
# 3/21/23
# This is designed to be used in conjusctions with an EA that identifies the admin account on the computer and a smart group.
# It will change their permissions from admin to standard exculding the choosen IT account. 
###########

# Var for account to exclude
ITAccount=$4

# get a list of all admin users on the Mac, excluding "Jamf_it"
adminUsers=$(dscl . -read /Groups/admin GroupMembership | cut -c18- | tr ' ' '\n' | grep -v "$ITAccount")

# loop through the list of admin users and set them to standard users
for user in $adminUsers
do
    dseditgroup -o edit -d $user -t user admin
    echo "Set user $user to standard"
done
