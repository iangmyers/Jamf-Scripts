#!/bin/bash
##########
# Created by Ian Myers
# Updated: 2026
# Checks system uptime and prompts the user to restart if the threshold is met.
# Forces a restart if the user dismisses or the countdown expires.
#
# Designed to run via Jamf Policy or LaunchDaemon on a schedule.
# Must run as root.
#
# Parameters:
#   $4 - (Optional) Restart threshold in days. Defaults to 6.
#   $5 - (Optional) Countdown time in seconds before forced restart. Defaults to 300.
##########

# --- Configuration ---
RESTART_THRESHOLD="${4:-6}"
COUNTDOWN_SECONDS="${5:-300}"
COUNTDOWN_MINUTES=$(( COUNTDOWN_SECONDS / 60 ))
LOG_TAG="UptimeRestartCheck"
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

# --- Get Uptime in Days ---
BOOT_TIME=$(sysctl -n kern.boottime | awk '{print $4}' | tr -d ',')
NOW=$(date +%s)
UPTIME_SECONDS=$(( NOW - BOOT_TIME ))
UPTIME_DAYS=$(( UPTIME_SECONDS / 86400 ))

log "System uptime: $UPTIME_DAYS day(s). Threshold: $RESTART_THRESHOLD day(s)."

# --- Check if restart is needed ---
if [[ "$UPTIME_DAYS" -lt "$RESTART_THRESHOLD" ]]; then
    log "Uptime below threshold. No action required."
    exit 0
fi

log "Uptime meets or exceeds threshold. Prompting user."

# --- Prompt user ---
if [[ -e "$SWIFT_DIALOG" ]]; then
    "$SWIFT_DIALOG" \
        --title "Restart Required" \
        --message "Your Mac hasn't been restarted in **$UPTIME_DAYS days**.\n\nYour Mac will restart automatically in $COUNTDOWN_MINUTES minutes. Please save your work before then." \
        --icon "$SELF_SERVICE_ICON" \
        --button1text "Restart Now" \
        --button2text "Remind Me Later" \
        --timer "$COUNTDOWN_SECONDS" \
        --ontop \
        --moveable
    DIALOG_EXIT=$?

    if [[ "$DIALOG_EXIT" == "0" ]] || [[ "$DIALOG_EXIT" == "4" ]]; then
        log "Restarting now. (Dialog exit: $DIALOG_EXIT)"
        /sbin/shutdown -r now
    else
        log "User chose to defer restart. (Dialog exit: $DIALOG_EXIT)"
        exit 0
    fi

else
    log "swiftDialog not found. Falling back to jamfHelper."
    JAMF_HELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

    REBOOT_PROMPT=$("$JAMF_HELPER" \
        -windowType utility \
        -lockHUD \
        -title "Restart Required" \
        -heading "Your Mac has not restarted in $UPTIME_DAYS days" \
        -description "Your Mac will restart automatically in $COUNTDOWN_MINUTES minutes. Please save your work. Click 'Restart Now' to restart immediately." \
        -button1 "Restart Now" \
        -defaultButton 1 \
        -countdown \
        -timeout "$COUNTDOWN_SECONDS" \
        -alignCountdown right)

    if [[ "$REBOOT_PROMPT" == "0" ]]; then
        log "Restarting now via jamfHelper prompt."
        /sbin/shutdown -r now
    fi
fi

exit 0
