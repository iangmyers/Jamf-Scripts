#!/bin/bash

##############
# Created by Ian Myers
# Sets the computer name in the format: "Prefix-SerialNumber-Username"
# Uses the Jamf Pro API (v1) with bearer token auth
#
# Jamf Parameters:
#   $4 - Jamf Pro API Username
#   $5 - Jamf Pro API Password
#   $6 - Jamf Pro URL (e.g. https://yourinstance.jamfcloud.com)
#
# Updated: 04/2026
# Run as sudo when testing outside of Jamf
#
# Notes:
#   - Uses /api/v1/computers-inventory with section=USER_AND_LOCATION
#   - JSON parsed with osascript JXA — no python3 / Xcode CLI tools required
#   - Falls back to Prefix-SN if no username is assigned in Jamf
##############

set -euo pipefail

# ---------------------------------------------------------------------------
# Parameters
# ---------------------------------------------------------------------------
jUsername="${4}"
jPassword="${5}"
jUrl="${6%/}"   # Strip trailing slash if present

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
PREFIX="Jamf-"   # Set to your desired prefix
JAMF_BINARY="/usr/local/bin/jamf"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ---------------------------------------------------------------------------
# Get bearer token — parsed with osascript JXA (no python3 dependency)
# ---------------------------------------------------------------------------
log "Requesting bearer token from $jUrl"
tokenJSON=$(curl -sf --request POST \
    --url "$jUrl/api/v1/auth/token" \
    --user "$jUsername:$jPassword" \
    --header "Accept: application/json")

token=$(osascript -l JavaScript -e "JSON.parse(\`$tokenJSON\`).token")

if [[ -z "$token" ]]; then
    log "ERROR: Failed to obtain bearer token. Check credentials and Jamf URL."
    exit 1
fi
log "Bearer token obtained."

# ---------------------------------------------------------------------------
# Cleanup: invalidate token on exit (success or failure)
# ---------------------------------------------------------------------------
cleanup() {
    log "Invalidating bearer token."
    curl -sf --request POST \
        --url "$jUrl/api/v1/auth/invalidate-token" \
        --header "Authorization: Bearer $token" > /dev/null 2>&1 || true
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Get serial number
# ---------------------------------------------------------------------------
SN=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')

if [[ -z "$SN" ]]; then
    log "ERROR: Could not retrieve serial number."
    exit 1
fi
log "Serial number: $SN"

# ---------------------------------------------------------------------------
# Look up assigned username from Jamf Pro API
# Uses /api/v1/computers-inventory with section=USER_AND_LOCATION
# Filter uses URL-encoded == operator (%3D%3D) as required by the API
# ---------------------------------------------------------------------------
log "Looking up username for serial number $SN"
inventoryJSON=$(curl -sf --request GET \
    --url "$jUrl/api/v1/computers-inventory?section=USER_AND_LOCATION&filter=hardware.serialNumber%3D%3D%22${SN}%22" \
    --header "Authorization: Bearer $token" \
    --header "Accept: application/json" || true)

Suffix=$(osascript -l JavaScript -e "
var data = JSON.parse(\`$inventoryJSON\`);
var results = data.results;
if (results && results.length > 0) {
    var u = results[0].userAndLocation;
    u && u.username ? u.username : '';
} else { ''; }
" 2>/dev/null || true)

# ---------------------------------------------------------------------------
# Build computer name — fallback gracefully if no username is assigned
# ---------------------------------------------------------------------------
if [[ -n "$Suffix" ]]; then
    COMPUTER_NAME="${PREFIX}${SN}-${Suffix}"
    log "Username found: $Suffix"
else
    COMPUTER_NAME="${PREFIX}${SN}"
    log "WARNING: No username found in Jamf. Setting name without username suffix."
fi

log "Setting computer name to: $COMPUTER_NAME"

# ---------------------------------------------------------------------------
# Set all three macOS name records for full consistency
# ---------------------------------------------------------------------------
# ComputerName  - Friendly name shown in Finder / About This Mac
# HostName      - Used for Bonjour and network identification
# LocalHostName - mDNS / .local hostname (no spaces, no special chars)
# ---------------------------------------------------------------------------
LocalHostName=$(echo "$COMPUTER_NAME" | tr ' ' '-' | tr -cd '[:alnum:]-')

/usr/sbin/scutil --set ComputerName  "$COMPUTER_NAME"
/usr/sbin/scutil --set HostName      "$COMPUTER_NAME"
/usr/sbin/scutil --set LocalHostName "$LocalHostName"

log "scutil names set."

# Also set via Jamf binary for Jamf inventory sync
"$JAMF_BINARY" setComputerName -name "$COMPUTER_NAME"
log "Jamf setComputerName complete."

# ---------------------------------------------------------------------------
# Update inventory (remove if an Update Inventory step is in your policy)
# ---------------------------------------------------------------------------
"$JAMF_BINARY" recon
log "Recon complete. Done."
