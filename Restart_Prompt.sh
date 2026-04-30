#!/bin/bash
##########
# Created by Ian Myers
# Updated: 2026
# Displays last boot time to the user and offers an optional restart.
# Restart is handled via a Jamf policy event.
#
# Parameters:
#   $4 - (Optional) Jamf policy custom trigger for restart. Defaults to "restart".
##########

# --- Configuration ---
RESTART_TRIGGER="${4:-restart}"
LOG_TAG="BootTimePrompt"
SWIFT_DIALOG="/usr/local/bin/dialog"

# --- Logging ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$LOG_TAG] $1"
    /usr/bin/logger -t "$LOG_TAG" "$1"
}

# --- Resolve Self Service icon (supports SS+, classic, and system fallback) ---
SELF_SERVICE_ICON=$(find /Applications -maxdepth 2 -name "AppIcon.icns" -path "*Self Service*" 2>/dev/null | head -1)
[[ -z "$SELF_SERVICE_ICON" ]] && SELF_SERVICE_ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
log "Using icon: $SELF_SERVICE_ICON"

# --- Get boot time ---
BOOT_EPOCH=$(sysctl -n kern.boottime | awk '{print $4}' | tr -d ',')
BOOT_TIME_FORMATTED=$(date -jf "%s" "$BOOT_EPOCH" "+%B %d, %Y at %I:%M %p")
log "Last boot time: $BOOT_TIME_FORMATTED"

# --- Prompt user ---
if [[ -e "$SWIFT_DIALOG" ]]; then
    "$SWIFT_DIALOG" \
        --title "Restart Recommended" \
        --message "Your Mac was last restarted on **$BOOT_TIME_FORMATTED**.\n\nRegular restarts help keep your Mac running smoothly. Would you like to restart now?" \
        --icon "$SELF_SERVICE_ICON" \
        --button1text "Restart Now" \
        --button2text "Not Now" \
        --ontop \
        --moveable
    DIALOG_EXIT=$?
else
    log "swiftDialog not found. Falling back to jamfHelper."
    JAMF_HELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
    DIALOG_EXIT=$("$JAMF_HELPER" \
        -icon "$SELF_SERVICE_ICON" \
        -title "Restart Recommended" \
        -button1 "Restart" \
        -button2 "Cancel" \
        -defaultButton 1 \
        -windowType hud \
        -description "Your Mac was last restarted on: $BOOT_TIME_FORMATTED")
fi

# --- Handle response ---
if [[ "$DIALOG_EXIT" == "0" ]]; then
    log "User chose to restart. Triggering Jamf policy event: $RESTART_TRIGGER"
    /usr/local/jamf/bin/jamf policy -event "$RESTART_TRIGGER"
else
    log "User declined restart."
fi

exit 0
