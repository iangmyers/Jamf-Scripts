#!/bin/bash
##########
# Created by Ian Myers
# Updated: 2026
# Prompts user if Jamf thinks FileVault encryption is not enabled.
# Checks actual encryption status and either triggers a recon
# or prompts the user to enable encryption via Self Service.
#
# Parameters:
#   $4 - Self Service policy URL to open if encryption is off
##########

# --- Configuration ---
POLICY_URL="$4"
LOG_TAG="FileVaultCheck"

# --- Logging ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$LOG_TAG] $1"
    /usr/bin/logger -t "$LOG_TAG" "$1"
}

# --- Resolve Self Service icon (supports SS+, classic, and system fallback) ---
SELF_SERVICE_ICON=$(find /Applications -maxdepth 2 -name "AppIcon.icns" -path "*Self Service*" 2>/dev/null | head -1)
[[ -z "$SELF_SERVICE_ICON" ]] && SELF_SERVICE_ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
log "Using icon: $SELF_SERVICE_ICON"

SWIFT_DIALOG="/usr/local/bin/dialog"

# --- Check FileVault Status ---
FV_STATUS=$(fdesetup status | awk '{print $NF}' | tr -d '.')
log "FileVault status reported as: $FV_STATUS"

# --- Handle Status ---
if [[ "$FV_STATUS" == "On" ]]; then
    log "FileVault is enabled. Triggering recon to update inventory."
    /usr/local/jamf/bin/jamf recon
    log "Recon complete."

elif [[ "$FV_STATUS" == "Off" ]]; then
    log "FileVault is disabled. Prompting user."

    if [[ -e "$SWIFT_DIALOG" ]]; then
        "$SWIFT_DIALOG" \
            --title "Encryption Required" \
            --message "Your Mac needs to be encrypted. Please open Self Service and run the Encryption policy." \
            --icon "$SELF_SERVICE_ICON" \
            --button1text "Open Self Service" \
            --button2text "Dismiss" \
            --ontop \
            --moveable
        DIALOG_EXIT=$?

        if [[ "$DIALOG_EXIT" == "0" ]]; then
            log "User clicked 'Open Self Service'. Opening policy URL."
            open "$POLICY_URL"
        else
            log "User dismissed the dialog without action."
        fi

    else
        log "swiftDialog not found. Falling back to jamfHelper."
        JAMF_HELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
        "$JAMF_HELPER" \
            -icon "$SELF_SERVICE_ICON" \
            -title "Computer needs to be encrypted" \
            -button1 "OK" \
            -defaultButton 1 \
            -windowType hud \
            -description "Please begin the encryption in Self Service"
        HELPER_EXIT=$?

        if [[ "$HELPER_EXIT" == "0" ]]; then
            log "User acknowledged jamfHelper prompt. Opening policy URL."
            open "$POLICY_URL"
        fi
    fi

else
    log "ERROR: Unexpected FileVault status value: '$FV_STATUS'. No action taken."
    exit 1
fi

exit 0
