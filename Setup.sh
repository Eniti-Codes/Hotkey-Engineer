#!/bin/bash

# Hotkey Engineer - Advanced hotkey automation using Python.
#
# Copyright (C) 2025 Eniti-Codes
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

# --- Configuration for the Hotkey Engineer ---
APP_DIR="$HOME/.local/share/hotkey_engineer"
VENV_DIR="$APP_DIR/venv"

SERVICE_NAME="hotkey-engineer"
SERVICE_FILE="$HOME/.config/systemd/user/${SERVICE_NAME}.service"

MAIN_SCRIPT_NAME="Hotkey-Engineer.py"
CONFIG_FILE_NAME="config.json"
UI_SCRIPT_NAME="Config-Editor.py"

DOWNLOADS_DIR="$HOME/Downloads"
MAIN_SCRIPT_SOURCE_PATH="$DOWNLOADS_DIR/$MAIN_SCRIPT_NAME"
CONFIG_SOURCE_PATH="$DOWNLOADS_DIR/$CONFIG_FILE_NAME"
UI_SCRIPT_SOURCE_PATH="$DOWNLOADS_DIR/$UI_SCRIPT_NAME"

SYSTEM_DEPENDENCIES="python3-venv python3-tk python3-dev scrot xclip xsel python3-pip"

# --- Function to clean up existing installation components ---
cleanup_existing_installation() {
    echo "Stopping existing ${SERVICE_NAME} user service..."
    systemctl --user stop "${SERVICE_NAME}.service" 2>/dev/null
    echo "Disabling existing ${SERVICE_NAME} user service..."
    systemctl --user disable "${SERVICE_NAME}.service" 2>/dev/null

    if [ -f "$SERVICE_FILE" ]; then
        echo "Removing old user service file: $SERVICE_FILE"
        rm "$SERVICE_FILE"
    fi
    echo "Existing user service components cleaned up."
}

# --- Function to check for required files in Downloads folder ---
check_download_files() {
    echo "Checking for '${CONFIG_FILE_NAME}', '${MAIN_SCRIPT_NAME}', and '${UI_SCRIPT_NAME}' in your Downloads folder..."
    if [ ! -f "$CONFIG_SOURCE_PATH" ] || [ ! -f "$MAIN_SCRIPT_SOURCE_PATH" ] || [ ! -f "$UI_SCRIPT_SOURCE_PATH" ]; then
        echo "--- IMPORTANT: Files Not Found! ---"
        echo "Please ensure '${CONFIG_FILE_NAME}', '${MAIN_SCRIPT_NAME}', and '${UI_SCRIPT_NAME}' are in your Downloads folder: $DOWNLOADS_DIR"
        return 1
    fi
    echo "All required files found in Downloads folder."
    return 0
}

# --- Function to install system-level and Python dependencies ---
install_dependencies() {
    echo "Installing system-level dependencies (requires your sudo password)..."
    sudo apt-get update
    sudo apt-get install -y $SYSTEM_DEPENDENCIES || { echo "ERROR: Failed to install system dependencies. Aborting."; exit 1; }
    echo "System dependencies installed."

    if [ ! -d "$VENV_DIR" ]; then
        echo "Creating Python virtual environment at $VENV_DIR..."
        python3 -m venv "$VENV_DIR" || { echo "ERROR: Failed to create virtual environment. Aborting."; exit 1; }
        echo "Virtual environment created."
    else
        echo "Virtual environment already exists at $VENV_DIR. Skipping recreation."
    fi

    echo "Installing/Updating Python packages into virtual environment via pip..."
    "$VENV_DIR/bin/pip" install --upgrade pynput pyautogui || { echo "ERROR: Failed to install/update Python packages. Aborting."; exit 1; }
    echo "Python packages installed/updated into virtual environment."
}

# --- Function to perform core installation/update steps ---
perform_installation_steps() {
    echo "Ensuring application directory exists: $APP_DIR"
    mkdir -p "$APP_DIR"

    echo "Moving ${CONFIG_FILE_NAME} to $APP_DIR/"
    mv "$CONFIG_SOURCE_PATH" "$APP_DIR/"
    echo "Moving ${MAIN_SCRIPT_NAME} to $APP_DIR/"
    mv "$MAIN_SCRIPT_SOURCE_PATH" "$APP_DIR/"
    
    echo "Moving ${UI_SCRIPT_NAME} to $APP_DIR/"
    mv "$UI_SCRIPT_SOURCE_PATH" "$APP_DIR/"

    echo "Making ${MAIN_SCRIPT_NAME} executable within the application directory"
    chmod +x "$APP_DIR/${MAIN_SCRIPT_NAME}"
    
    echo "Making ${UI_SCRIPT_NAME} executable within the application directory"
    chmod +x "$APP_DIR/${UI_SCRIPT_NAME}"

    LOG_DIR_FROM_CONFIG=$(grep -Po '"log_directory": "\K[^"]*' "$APP_DIR/$CONFIG_FILE_NAME")
    if [ -z "$LOG_DIR_FROM_CONFIG" ]; then
        echo "WARNING: Could not find 'log_directory' in config.json. Defaulting to a safe user-specific path."
        LOG_DIR_FROM_CONFIG="$APP_DIR/logs"
    fi
    echo "Ensuring log directory '$LOG_DIR_FROM_CONFIG' is writable by the user"
    mkdir -p "$LOG_DIR_FROM_CONFIG"

    echo "Creating systemd user service file: $SERVICE_FILE"
    mkdir -p "$(dirname "$SERVICE_FILE")"

    cat > "$SERVICE_FILE" <<EOL
[Unit]
Description=Hotkey Engineer: Central Automation Module Manager
After=network.target graphical-session.target dbus.service
Wants=graphical-session.target dbus.service

[Service]
ExecStart=$VENV_DIR/bin/python3 $APP_DIR/${MAIN_SCRIPT_NAME}
WorkingDirectory=$APP_DIR
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
Type=simple

[Install]
WantedBy=graphical-session.target
EOL

    echo "Reloading systemd user daemon to recognize changes..."
    systemctl --user daemon-reload

    echo "Enabling ${SERVICE_NAME}.service to start on boot..."
    systemctl --user enable "${SERVICE_NAME}.service"

    echo "Starting ${SERVICE_NAME}.service now..."
    systemctl --user start "${SERVICE_NAME}.service"
}

# --- Main Script Logic ---
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Please run this script as a normal user, not with sudo."
    echo "The script will ask for your sudo password when needed."
    exit 1
fi

echo "--- Hotkey Engineer Setup & Management ---"
echo "This script will install or update the Hotkey Engineer as a systemd user service."
echo "It requires 'Hotkey-Engineer.py' and 'config.json' to be in your Downloads folder."
echo ""
echo "Please choose an option:"
echo "1) Install / Update Hotkey Engineer"
echo "2) Uninstall Hotkey Engineer (removes application files and service)"
echo "3) Uninstall System Dependencies (removes python3-tk, scrot, etc.)"
read -p "Enter your choice (1, 2, or 3): " choice

case $choice in
    1)
        echo "You chose: Install / Update Hotkey Engineer."
        echo "Proceeding with installation/update..."
        if ! check_download_files; then
            exit 1
        fi
        install_dependencies
        perform_installation_steps
        echo "--- Installation/Update Complete! ---"
        echo "The Hotkey Engineer service should now be running."
        echo "You can check the service status with: systemctl --user status ${SERVICE_NAME}.service"
        echo "You can view the logs with: journalctl --user -u ${SERVICE_NAME}.service -f"
        ;;
    2)
        echo "You chose: Uninstall Hotkey Engineer."
        echo "Proceeding with uninstallation of application files and service..."
        cleanup_existing_installation
        if [ -d "$APP_DIR" ]; then
            echo "Removing application directory: $APP_DIR"
            rm -rf "$APP_DIR"
        fi
        echo "--- Application Uninstallation Complete! ---"
        ;;
    3)
        echo "You chose: Uninstall System Dependencies."
        uninstall_dependencies
        echo "--- System Dependency Uninstallation Attempted ---"
        ;;
    *)
        echo "Invalid choice. Please enter 1, 2, or 3."
        exit 1
        ;;
esac

exit 0
