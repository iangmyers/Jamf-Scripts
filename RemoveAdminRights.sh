#!/bin/bash
##########
# Created by Ian Myers
# Updated: 2026
# Demotes all admin accounts to standard users, excluding a specified IT account.
# Designed to be used with an EA that identifies admin accounts and a Smart Group.
#
# Parameters:
#   $4 - Username of the IT/service account to exclude from demotion
##########

# --- Configuration ---
IT_ACCOUNT="$4"
LOG_TAG="DemoteAdmins"

# --- Logging ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$LOG_TAG] $1"
    /usr/bin/logger -t "$LOG_TAG" "$1"
}

# --- Validate parameter ---
if [[ -z "$IT_ACCOUNT" ]]; then
    log "WARNING: No IT account exclusion specified via \$4. Proceeding without exclusion."
fi

# --- Get list of admin users, excluding the IT account ---
ADMIN_USERS=$(dscl . -read /Groups/admin GroupMembership | tr ' ' '\n' | tail -n +2 | grep -v "^${IT_ACCOUNT}$")

if [[ -z "$ADMIN_USERS" ]]; then
    log "No admin users found to demote."
    exit 0
fi

# --- Demote each admin to standard user ---
while IFS= read -r user; do
    dseditgroup -o edit -d "$user" -t user admin
    log "Set user '$user' to standard."
done <<< "$ADMIN_USERS"

log "Admin demotion complete."
exit 0
