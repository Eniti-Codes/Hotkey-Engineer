#!/bin/bash

# --- Configuration for the Hotkey Engineer ---
# APP_DIR is the base directory for the entire application, including the venv
APP_DIR="/opt/hotkey_engineer"
# VENV_DIR is the specific path to the virtual environment within APP_DIR
VENV_DIR="$APP_DIR/venv"

SERVICE_NAME="hotkey-engineer" # Service name for systemd
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

MAIN_SCRIPT_NAME="Hotkey-Engineer.py"
CONFIG_FILE_NAME="config.json"
MODULES_SUBDIR="modules" # Directory where user's individual Python modules will reside

# Paths where the installer expects to find the main script and config file in Downloads
USER_HOME=$(eval echo "~$SUDO_USER") # Get the actual user's home directory
DOWNLOADS_DIR="$USER_HOME/Downloads"
MAIN_SCRIPT_SOURCE_PATH="$DOWNLOADS_DIR/$MAIN_SCRIPT_NAME"
CONFIG_SOURCE_PATH="$DOWNLOADS_DIR/$CONFIG_FILE_NAME"

# List of system-level packages installed by this script
SYSTEM_DEPENDENCIES="python3-venv python3-tk python3-dev scrot xclip xsel python3-pip"

# --- Function to clean up existing installation components ---
cleanup_existing_installation() {
    echo "Stopping existing ${SERVICE_NAME} service..."
    sudo systemctl stop "${SERVICE_NAME}.service" 2>/dev/null
    echo "Disabling existing ${SERVICE_NAME} service..."
    sudo systemctl disable "${SERVICE_NAME}.service" 2>/dev/null

    # Only remove the service file, not the application directory itself during cleanup for updates
    if [ -f "$SERVICE_FILE" ]; then
        echo "Removing old systemd service file: $SERVICE_FILE"
        sudo rm "$SERVICE_FILE"
    fi
    sudo systemctl daemon-reload 2>/dev/null
    echo "Existing service components cleaned up."
}

# --- Function to check for required files in Downloads folder ---
check_download_files() {
    echo "Checking for '${CONFIG_FILE_NAME}' and '${MAIN_SCRIPT_NAME}' in your Downloads folder..."
    if [ ! -f "$CONFIG_SOURCE_PATH" ] || [ ! -f "$MAIN_SCRIPT_SOURCE_PATH" ]; then
        echo "--- IMPORTANT: Files Not Found! ---"
        echo "It looks like '${CONFIG_FILE_NAME}' or '${MAIN_SCRIPT_NAME}' are not in your Downloads folder:"
        echo "Expected location for ${CONFIG_FILE_NAME}: $CONFIG_SOURCE_PATH"
        echo "Expected location for ${MAIN_SCRIPT_NAME}: $MAIN_SCRIPT_SOURCE_PATH"
        echo ""
        echo "Please ensure both files are in your Downloads folder: $DOWNLOADS_DIR"
        echo "Once moved, please run this script again."
        echo ""
        return 1
    fi
    echo "Both files found in Downloads folder."
    return 0
}

# --- Function to install system-level and Python dependencies ---
install_dependencies() {
    echo "Installing system-level dependencies (may require your sudo password)..."
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
    # Install pynput and pyautogui into the virtual environment
    "$VENV_DIR/bin/pip" install --upgrade pynput pyautogui || { echo "ERROR: Failed to install/update Python packages into virtual environment. Aborting."; exit 1; }
    echo "Python packages installed/updated into virtual environment."
}

# --- Function to uninstall system-level dependencies ---
uninstall_dependencies() {
    echo "--- Uninstall System Dependencies ---"
    read -p "This will attempt to remove system packages installed by Hotkey Engineer: ${SYSTEM_DEPENDENCIES}. Continue? (y/N): " confirm_uninstall_deps
    if [[ "$confirm_uninstall_deps" =~ ^[Yy]$ ]]; then
        echo "Uninstalling system dependencies..."
        # Using purge to remove config files too, and autoremove to clean up packages no longer needed by anything else
        sudo apt-get purge -y $SYSTEM_DEPENDENCIES && sudo apt-get autoremove -y || { echo "WARNING: Failed to uninstall some system dependencies. You may need to remove them manually."; }
        echo "System dependencies uninstallation attempted."
    else
        echo "Skipping system dependency uninstallation."
    fi
}

# --- Function to perform core installation/update steps ---
perform_installation_steps() {
    echo "Ensuring application directory exists: $APP_DIR"
    sudo mkdir -p "$APP_DIR"

    echo "Ensuring modules directory exists: $APP_DIR/$MODULES_SUBDIR"
    sudo mkdir -p "$APP_DIR/$MODULES_SUBDIR"

    # Move main script and config into the virtual environment's root (overwrites existing)
    echo "Moving ${CONFIG_FILE_NAME} to $VENV_DIR/${CONFIG_FILE_NAME}"
    sudo mv "$CONFIG_SOURCE_PATH" "$VENV_DIR/${CONFIG_FILE_NAME}"
    echo "Moving ${MAIN_SCRIPT_NAME} to $VENV_DIR/${MAIN_SCRIPT_NAME}"
    sudo mv "$MAIN_SCRIPT_SOURCE_PATH" "$VENV_DIR/${MAIN_SCRIPT_NAME}"

    echo "Making ${MAIN_SCRIPT_NAME} executable within the virtual environment"
    sudo chmod +x "$VENV_DIR/${MAIN_SCRIPT_NAME}"

    # Set ownership for the entire application directory (including venv) to the user
    echo "Setting ownership of $APP_DIR to $SUDO_USER"
    sudo chown -R "$SUDO_USER":"$SUDO_USER" "$APP_DIR"

    # Ensure the log directory (as specified in config.json) is writable by the user
    # Note: config.json is now inside the VENV_DIR
    LOG_DIR_FROM_CONFIG=$(grep -Po '"log_directory": "\K[^"]*' "$VENV_DIR/$CONFIG_FILE_NAME")
    if [ -z "$LOG_DIR_FROM_CONFIG" ]; then
        echo "WARNING: Could not find 'log_directory' in config.json. Please ensure it's set correctly in $VENV_DIR/$CONFIG_FILE_NAME."
        echo "Defaulting to /var/log/${SERVICE_NAME}_logs for permissions setup."
        LOG_DIR_FROM_CONFIG="/var/log/${SERVICE_NAME}_logs"
    fi
    echo "Ensuring log directory '$LOG_DIR_FROM_CONFIG' is writable by $SUDO_USER"
    sudo mkdir -p "$LOG_DIR_FROM_CONFIG"
    sudo chown -R "$SUDO_USER":"$SUDO_USER" "$LOG_DIR_FROM_CONFIG"


    echo "Creating systemd service file: $SERVICE_FILE"
    # Get the XAUTHORITY path for the user who ran sudo
    USER_XAUTHORITY=$(sudo -u "$SUDO_USER" printenv XAUTHORITY)
    if [ -z "$USER_XAUTHORITY" ]; then
        USER_XAUTHORITY="/home/$SUDO_USER/.Xauthority"
        echo "WARNING: XAUTHORITY not found in user's environment. Defaulting to $USER_XAUTHORITY. Verify this path if hotkeys/GUI modules fail."
    fi

    sudo bash -c "cat > \"$SERVICE_FILE\" <<EOL
[Unit]
Description=Hotkey Engineer: Central Automation Module Manager
After=network.target graphical.target # Wait for network and graphical session to be ready

[Service]
ExecStart=$VENV_DIR/bin/python3 $VENV_DIR/${MAIN_SCRIPT_NAME}
WorkingDirectory=$VENV_DIR
Restart=on-failure
StandardOutput=journal
StandardError=journal

User=$SUDO_USER
Group=$SUDO_USER

Environment=\"DISPLAY=:0\"
Environment=\"XAUTHORITY=$USER_XAUTHORITY\"

[Install]
WantedBy=multi-user.target graphical.target
EOL"

    echo "Reloading systemd daemon to recognize changes..."
    sudo systemctl daemon-reload

    echo "Enabling ${SERVICE_NAME}.service to start on boot..."
    sudo systemctl enable "${SERVICE_NAME}.service"

    echo "Starting ${SERVICE_NAME}.service now..."
    sudo systemctl start "${SERVICE_NAME}.service"
}

# --- Main Menu Presentation and Action Execution ---

echo "--- Hotkey Engineer Setup & Management ---"
echo "This script will install or update the Hotkey Engineer as a systemd service."
echo "It requires 'Hotkey-Engineer.py' and 'config.json' to be in your Downloads folder."
echo ""
echo "Please choose an option:"
echo "1) Install / Update Hotkey Engineer"
echo "2) Uninstall Hotkey Engineer (removes application files and service)"
echo "3) Uninstall System Dependencies (removes python3-tk, scrot, etc.)" # New option
read -p "Enter your choice (1, 2, or 3): " choice

case $choice in
    1) 
    # Install / Update Logic
        echo "You chose: Install / Update Hotkey Engineer."
        echo "Proceeding with installation/update..."

        if [ "$EUID" -ne 0 ]; then
            echo "Please run this script with sudo: sudo ./setup.sh"
            exit 1
        fi

        if ! check_download_files; then
            exit 1
        fi

        cleanup_existing_installation

        install_dependencies

        perform_installation_steps
        echo "--- Installation/Update Complete! ---"
        echo "The Hotkey Engineer service should now be running and will start automatically on future reboots."
        echo ""
        echo "NEXT STEPS:"
        echo "1. Place your individual Python modules (e.g., welcome_message.py, quick_note.py) into:"
        echo "   $APP_DIR/$MODULES_SUBDIR/"
        echo "   Ensure their paths in $VENV_DIR/${CONFIG_FILE_NAME} are absolute and correct (e.g., /opt/hotkey_engineer/modules/my_module.py)."
        echo "2. Verify the 'log_directory' in $VENV_DIR/${CONFIG_FILE_NAME} is set to a path writable by your user."
        echo "3. You can check the service status with: sudo systemctl status ${SERVICE_NAME}.service"
        echo "4. You can view the Hotkey Engineer's logs with: journalctl -u ${SERVICE_NAME}.service -f"
        echo "5. For detailed Hotkey Engineer logs, check the file: $(grep -Po '"log_directory": "\K[^"]*' "$VENV_DIR/$CONFIG_FILE_NAME")/hotkey_engineer.log"
        echo "6. For individual module logs, check their respective subdirectories within the global log directory."
        echo ""
        echo "IMPORTANT: If hotkeys or GUI modules don't work, verify 'XAUTHORITY' in the service file ($SERVICE_FILE) is correct."
        echo "   Your current XAUTHORITY (from your desktop session) is: $USER_XAUTHORITY"
        echo "   If this path is wrong, edit $SERVICE_FILE and restart the service."
        ;;

    2) 
    # Uninstall Logic (Application Files and Service Only)
        echo "You chose: Uninstall Hotkey Engineer."
        echo "Proceeding with uninstallation of application files and service..."
        
        if [ "$EUID" -ne 0 ]; then
            echo "Please run this script with sudo: sudo ./setup.sh"
            exit 1
        fi

        cleanup_existing_installation # Stops service, removes service file
        if [ -d "$APP_DIR" ]; then
            echo "Removing application directory: $APP_DIR (includes virtual environment and modules)"
            sudo rm -rf "$APP_DIR"
        fi
        echo "--- Application Uninstallation Complete! ---"
        echo "Hotkey Engineer application files and service have been removed."
        echo "It will no longer start automatically on boot."
        echo "Note: Log files in $(grep -Po '"log_directory": "\K[^"]*' "$VENV_DIR/$CONFIG_FILE_NAME" 2>/dev/null || echo "/var/log/${SERVICE_NAME}_logs") were NOT removed."
        echo "System dependencies (e.g., python3-tk, scrot) were NOT removed. Run option 3 to remove them."
        ;;

    3) 
    # Uninstall System Dependencies Logic
        echo "You chose: Uninstall System Dependencies."
        
        if [ "$EUID" -ne 0 ]; then
            echo "Please run this script with sudo: sudo ./setup.sh"
            exit 1
        fi
        
        uninstall_dependencies # Calls the function to uninstall system dependencies
        echo "--- System Dependency Uninstallation Attempted ---"
        ;;

    *) 
    # Invalid choice
        echo "Invalid choice. Please enter 1, 2, or 3."
        exit 1
        ;;
esac

exit 0