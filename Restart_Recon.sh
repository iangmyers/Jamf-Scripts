#!/bin/bash

# Designed to created a Launch Deamon to run the Jamf recon command once at load in order to reestablish a conection 

# LaunchDaemon Path
lDPath="/Library/LaunchDaemons/com.jamf.restartRecon.plist"

# Verify the file isn't already there
if [[ -f "$lDPath" ]]; then
	# Bootout the launchdaemon, ignoring erros
	/bin/launchctl bootout system "$lDPath" 2> /dev/null
	rm "$lDPath"
fi

# Write out the launchdaemon
# No quotes around LaunchDaemon so variables and commands are expanded as the file is written
tee "$lDPath" << LaunchDaemon
<?xml version="1.0" encoding="UTF-8"?> 
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0"> 
<dict> 
	<key>Label</key> 
	<string>$(basename $lDPath | sed 's/.plist//')</string> 
	<key>ProgramArguments</key> 
	<array> 
		<string>/usr/local/bin/jamf</string> 
		<string>recon</string> 
	</array> 
	<key>RunAtLoad</key>
	<true/>
	<key>LaunchOnlyOnce</key>
	<true/>
</dict> 
</plist>
LaunchDaemon

# Change Owner:Group to root:wheel
/usr/sbin/chown root:wheel "$lDPath"

# Change Permisssions to 644
/bin/chmod 644 "$lDPath"

# Bootstrap the launchdaemon
/bin/launchctl bootstrap system "$lDPath"
