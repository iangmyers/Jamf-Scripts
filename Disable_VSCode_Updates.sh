#!/bin/bash

# Get the user settings file for VS Code
settings_file="$HOME/Library/Application Support/Code/User/settings.json"

# Check if the settings file exists
if [ -f "$settings_file" ]; then
    # Check if the update.mode setting is already present, and modify it if it exists
    if grep -q '"update.mode":' "$settings_file"; then
        # Update the existing update.mode setting to disable auto-updates
        sed -i '' 's/"update.mode":.*/"update.mode": "none",/' "$settings_file"
    else
        # If update.mode setting does not exist, add it to disable auto-updates
        echo '{"update.mode": "none"}' >> "$settings_file"
    fi

    echo "VS Code update settings have been modified. Auto-updates are disabled."
else
    # If the settings file does not exist, create it and add the update mode setting
    echo '{"update.mode": "none"}' > "$settings_file"
    echo "VS Code will no longer auto-update."
fi
