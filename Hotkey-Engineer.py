#!/usr/bin/python3
import json
import subprocess
import time
import os
import sys
from datetime import datetime
from pynput import keyboard
from functools import partial

# --- Configuration Paths ---
MODULE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(MODULE_DIR, "config.json")

# --- Global State ---
running_processes = {}
automation_config = {}
script_configs_by_name = {}

# Global file handle for the Module Manager's own log file
_module_manager_log_file_handle = None
_is_terminal_attached = False

# --- Helper Functions ---
def log_message(level, message, module_name="Module Manager"):
    """Prints a timestamped log message to stdout/stderr and to a file."""
    timestamped_message = f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] [{module_name}] {level}: {message}"

    # Print to terminal if one is attached
    if _is_terminal_attached:
        if level == "ERROR" or level == "WARN":
            print(timestamped_message, file=sys.stderr)
        else:
            print(timestamped_message, file=sys.stdout)

    # Always write to the log file if it's open
    if _module_manager_log_file_handle:
        try:
            _module_manager_log_file_handle.write(timestamped_message + "\n")
            _module_manager_log_file_handle.flush() # Ensure it's written immediately
        except Exception as e:
            # Fallback print if file logging fails (e.g., disk full, permissions)
            if _is_terminal_attached:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] [Module Manager] ERROR: Failed to write to log file: {e}", file=sys.stderr)

def load_config(config_path):
    """Loads and validates the configuration from the JSON file."""
    log_message("INFO", f"Loading configuration from {config_path}")
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        log_message("INFO", "Configuration loaded successfully. Performing validation...")

        global_settings = config.get("global_settings", {})
        if "log_directory" not in global_settings:
            log_message("ERROR", "Missing 'log_directory' in 'global_settings' in config.json. This is a mandatory setting. Exiting.")
            sys.exit(1)

        validated_modules = []
        for module_def in config.get("scripts", []):
            module_name = module_def.get("name", "Unnamed Module")
            module_path = module_def.get("path")
            is_enabled = module_def.get("enabled", False)
            run_on_startup = module_def.get("run_on_startup", False)
            run_hotkey = module_def.get("run_hotkey", False)

            if not is_enabled:
                log_message("INFO", f"Module '{module_name}' is disabled. It will not be launched or have hotkeys registered.")
                validated_modules.append(module_def)
                continue

            if not module_path:
                log_message("ERROR", f"Module '{module_name}' is enabled but 'path' is missing. Disabling module.", module_name)
                module_def["enabled"] = False
            elif not os.path.isabs(module_path):
                log_message("ERROR", f"Module '{module_name}' is enabled but 'path' ('{module_path}') is not an absolute path. Disabling module.", module_name)
                module_def["enabled"] = False

            if module_def["enabled"]:
                if run_on_startup and run_hotkey:
                    log_message("ERROR", f"Module '{module_name}' is configured for both 'run_on_startup' and 'run_hotkey'. This is not allowed. Disabling module.", module_name)
                    module_def["enabled"] = False
                elif not run_on_startup and not run_hotkey:
                    log_message("WARN", f"Module '{module_name}' is enabled but has neither 'run_on_startup' nor 'run_hotkey' set to true. It will not be launched automatically or via hotkey.", module_name)

            validated_modules.append(module_def)

        config["scripts"] = validated_modules
        return config
    except FileNotFoundError:
        log_message("ERROR", f"Config file not found at {config_path}. Exiting.")
        sys.exit(1)
    except json.JSONDecodeError as e:
        log_message("ERROR", f"Invalid JSON in config file at {config_path}: {e}. Exiting.")
        sys.exit(1)
    except Exception as e:
        log_message("ERROR", f"An unexpected error occurred while loading config: {e}. Exiting.")
        sys.exit(1)

def terminate_child_module(module_name):
    """Terminates a running child module."""
    if module_name in running_processes:
        process = running_processes[module_name]
        if process.poll() is None:
            log_message("INFO", f"Terminating module '{module_name}' (PID: {process.pid})...")
            try:
                process.terminate()
                process.wait(timeout=5)
                if process.poll() is None:
                    log_message("WARN", f"Module '{module_name}' did not terminate gracefully. Killing (PID: {process.pid})...")
                    process.kill()
                log_message("INFO", f"Module '{module_name}' terminated.")
            except subprocess.TimeoutExpired:
                log_message("ERROR", f"Timeout while terminating module '{module_name}'. Killing it.")
                process.kill()
            except Exception as e:
                log_message("ERROR", f"Error terminating module '{module_name}': {e}")
        else:
            log_message("INFO", f"Module '{module_name}' was already stopped.")
        del running_processes[module_name]
    else:
        log_message("INFO", f"Module '{module_name}' is not currently running.")

def run_child_module(module_config, global_settings):
    """Executes a single child module."""
    module_name = module_config.get("name", "Unnamed Module")
    module_path = module_config.get("path")
    module_args = module_config.get("args", [])
    module_env = module_config.get("environment", {})
    needs_gui = module_config.get("needs_gui", False)
    is_external_app = module_config.get("is_external_app", False)

    log_dir = global_settings.get("log_directory")

    if not os.path.exists(module_path):
        log_message("WARN", f"Module '{module_name}' path '{module_path}' does not exist. Skipping launch.")
        return None

    log_message("INFO", f"Preparing to launch module '{module_name}' from '{module_path}'")

    module_specific_log_dir = os.path.join(log_dir, module_name.lower().replace(" ", "_"))
    os.makedirs(module_specific_log_dir, exist_ok=True)
    log_file_path = os.path.join(module_specific_log_dir, f"{datetime.now().strftime('%Y%m%d_%H%M%S')}.log")

    if is_external_app:
        command = [module_path] + module_args
    else:
        command = [sys.executable, module_path] + module_args

    env = os.environ.copy()
    env.update(module_env)

    # Required for GUI applications to run under a user service
    if needs_gui:
        if 'DISPLAY' not in env:
            env['DISPLAY'] = os.getenv('DISPLAY', ':0')
        if 'XAUTHORITY' not in env:
            user_home = os.getenv('HOME')
            if user_home:
                xauthority_path = os.path.join(user_home, '.Xauthority')
                if os.path.exists(xauthority_path):
                    env['XAUTHORITY'] = xauthority_path
                else:
                    log_message("WARN", f"HOME set but .Xauthority not found at {xauthority_path} for GUI module '{module_name}'. May fail.")
            else:
                log_message("WARN", f"HOME environment variable not set, cannot locate .Xauthority for GUI module '{module_name}'. May fail.")

    try:
        with open(log_file_path, 'w') as log_file:
            process = subprocess.Popen(command, stdout=log_file, stderr=log_file, env=env, close_fds=True)
            log_message("INFO", f"Module '{module_name}' launched with PID {process.pid}. Output logged to {log_file_path}")
            running_processes[module_name] = process
            return process
    except FileNotFoundError:
        log_message("ERROR", f"Command or module not found for '{module_name}': {command[0]}. Check path and executability.")
    except Exception as e:
        log_message("ERROR", f"Failed to launch module '{module_name}': {e}")
    return None

def hotkey_action_callback(module_name, action_type, global_settings):
    """Callback function executed when a hotkey is pressed."""
    log_message("INFO", f"Hotkey triggered for module '{module_name}' with action '{action_type}'.")

    module_config = script_configs_by_name.get(module_name)
    if not module_config or not module_config.get("enabled", False):
        log_message("WARN", f"Hotkey triggered for disabled or unknown module '{module_name}'. Ignoring.")
        return

    if action_type == "run":
        if module_config.get("is_external_app", False) and \
           module_name in running_processes and running_processes[module_name].poll() is None:
            log_message("INFO", f"External app '{module_name}' is already running. Not launching a new instance.")
        else:
            if module_name in running_processes and running_processes[module_name].poll() is not None:
                log_message("INFO", f"Cleaning up stale process entry for '{module_name}'.")
                del running_processes[module_name]
            run_child_module(module_config, global_settings)
    elif action_type == "toggle":
        is_running = module_name in running_processes and running_processes[module_name].poll() is None
        if is_running:
            log_message("INFO", f"Module '{module_name}' is running. Toggling off.")
            terminate_child_module(module_name)
        else:
            log_message("INFO", f"Module '{module_name}' is not running. Toggling on.")
            if module_name in running_processes and running_processes[module_name].poll() is not None:
                log_message("INFO", f"Cleaning up stale process entry for '{module_name}'.")
                del running_processes[module_name]
            run_child_module(module_config, global_settings)
    else:
        log_message("ERROR", f"Unknown hotkey action type '{action_type}' for module '{module_name}'.")

def setup_hotkeys(global_settings):
    """Sets up pynput HotKey objects based on configuration."""
    hotkey_listener = None
    hotkey_objects = []

    for module_name, module_config in script_configs_by_name.items():
        if not module_config.get("enabled", False):
            continue

        if not module_config.get("run_hotkey", False) or module_config.get("run_on_startup", False):
            continue

        hotkey_keys = module_config.get("hotkey")
        hotkey_action = module_config.get("hotkey_action")

        if not hotkey_keys:
            log_message("ERROR", f"Module '{module_name}' is marked 'run_hotkey: true' but 'hotkey' is not defined. Skipping hotkey registration.")
            continue
        if not isinstance(hotkey_keys, list) or not all(isinstance(k, str) for k in hotkey_keys):
            log_message("ERROR", f"Invalid 'hotkey' format for module '{module_name}'. Must be a list of strings (e.g., ['<ctrl>', 'a']). Skipping hotkey registration.")
            continue

        if hotkey_action not in ["run", "toggle"]:
            log_message("ERROR", f"Invalid 'hotkey_action' for module '{module_name}'. Must be 'run' or 'toggle'. Skipping hotkey registration.")
            continue

        pynput_keys = []
        for k in hotkey_keys:
            if k.startswith('<') and k.endswith('>'):
                key_name = k[1:-1]
                try:
                    if key_name == 'ctrl': pynput_keys.append(keyboard.Key.ctrl_l)
                    elif key_name == 'alt': pynput_keys.append(keyboard.Key.alt_l)
                    elif key_name == 'shift': pynput_keys.append(keyboard.Key.shift_l)
                    elif key_name == 'cmd': pynput_keys.append(keyboard.Key.cmd)
                    elif key_name == 'space': pynput_keys.append(keyboard.Key.space)
                    elif key_name == 'enter': pynput_keys.append(keyboard.Key.enter)
                    elif key_name == 'esc': pynput_keys.append(keyboard.Key.esc)
                    elif key_name.startswith('f') and key_name[1:].isdigit():
                        pynput_keys.append(getattr(keyboard.Key, key_name))
                    else:
                        pynput_keys.append(getattr(keyboard.Key, key_name))
                except AttributeError:
                    log_message("WARN", f"Unknown special key '{k}' in hotkey for module '{module_name}'. Skipping hotkey registration.")
                    pynput_keys = []
                    break
            else:
                pynput_keys.append(keyboard.KeyCode(char=k))

        if not pynput_keys:
            continue

        callback = partial(hotkey_action_callback, module_name, hotkey_action, global_settings)

        try:
            hotkey_obj = keyboard.HotKey(tuple(pynput_keys), callback)
            hotkey_objects.append(hotkey_obj)
            log_message("INFO", f"Registered hotkey: {hotkey_keys} for module '{module_name}' (action: {hotkey_action})")
        except Exception as e:
            log_message("ERROR", f"Failed to register hotkey {hotkey_keys} for module '{module_name}': {e}")
            log_message("ERROR", f"Common issues: Missing Xorg dependencies, Wayland session, or incorrect key string format for pynput.")


    if hotkey_objects:
        def on_press_dispatch(key):
            for hotkey_obj in hotkey_objects:
                hotkey_obj.press(key)

        def on_release_dispatch(key):
            for hotkey_obj in hotkey_objects:
                hotkey_obj.release(key)

        hotkey_listener = keyboard.Listener(on_press=on_press_dispatch, on_release=on_release_dispatch)
    else:
        log_message("INFO", "No hotkeys configured or enabled in the configuration.")

    return hotkey_listener


# --- Main Automation Module Manager Logic ---
def main():
    """Main function to orchestrate module execution and listen for hotkeys."""
    global automation_config, script_configs_by_name, _module_manager_log_file_handle, _is_terminal_attached

    # Check if a terminal is attached for conditional printing
    _is_terminal_attached = sys.stdout.isatty()

    # Load config dynamically from the same directory as the module
    automation_config = load_config(CONFIG_FILE)

    global_settings = automation_config.get("global_settings", {})
    log_dir = global_settings["log_directory"]

    # Ensure log directory exists
    os.makedirs(log_dir, exist_ok=True)

    # Open the Module Manager's own log file
    module_manager_log_path = os.path.join(log_dir, "module_manager.log")
    try:
        _module_manager_log_file_handle = open(module_manager_log_path, 'a')
        log_message("INFO", f"Module Manager log file opened at: {module_manager_log_path}")
    except Exception as e:
        # If we can't open the log file, we can only print to terminal if available
        if _is_terminal_attached:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] [Module Manager] ERROR: Could not open Module Manager log file at {module_manager_log_path}: {e}", file=sys.stderr)
        sys.exit(1) # Critical error, cannot proceed without logging

    log_message("INFO", "Automation Module Manager (Central Startup & Hotkey Orchestrator) starting...")
    log_message("INFO", f"Global log directory: {log_dir}")

    script_configs_by_name = {s['name']: s for s in automation_config.get("scripts", [])}

    # Launch 'run_on_startup' modules
    startup_modules_to_launch = [
        s for s in automation_config.get("scripts", [])
        if s.get("enabled", False) and s.get("run_on_startup", False)
    ]

    if not startup_modules_to_launch:
        log_message("INFO", "No enabled modules found configured to run on Module Manager startup.")
    else:
        log_message("INFO", f"Found {len(startup_modules_to_launch)} modules to launch on startup.")
        for module_config in startup_modules_to_launch:
            run_child_module(module_config, global_settings)
            time.sleep(0.1)

    # Set up Keyboard Listener for Hotkeys
    log_message("INFO", "Setting up keyboard listener for hotkeys...")
    hotkey_listener = setup_hotkeys(global_settings)

    # Determine if the Module Manager should stay alive
    should_module_manager_stay_alive = False
    if hotkey_listener:
        try:
            log_message("INFO", "Attempting to start hotkey listener thread...")
            hotkey_listener.start()
            time.sleep(1)
            if hotkey_listener.is_alive():
                should_module_manager_stay_alive = True
                log_message("INFO", "Hotkey listener started and is active. Module Manager will stay alive to listen for hotkeys.")
            else:
                log_message("ERROR", "Hotkey listener thread failed to become active after start(). Hotkey functionality will not work.")
                hotkey_listener = None
        except Exception as e:
            log_message("ERROR", f"Error during hotkey listener startup: {e}. Hotkey functionality will not work.")
            log_message("ERROR", "Ensure necessary permissions and display access are granted (e.g., Xorg, python3-tk/dev, scrot).")
            log_message("ERROR", "If using Wayland, global hotkeys are more complex and may require specific Wayland compositor APIs or workarounds.")
            hotkey_listener = None

    if startup_modules_to_launch and not should_module_manager_stay_alive:
        should_module_manager_stay_alive = True
        log_message("INFO", "Startup modules launched. Module Manager will stay alive to manage them (no active hotkey listener).")

    try:
        if should_module_manager_stay_alive:
            if hotkey_listener and hotkey_listener.is_alive():
                log_message("INFO", "Module Manager is now active and listening for hotkeys (via listener.join()).")
                hotkey_listener.join()
            else:
                log_message("INFO", "Module Manager is staying alive for launched startup modules (via sleep loop).")
                while True:
                    time.sleep(3600)
        else:
            log_message("INFO", "No active components configured. Automation Module Manager finished initial run and exiting.")
    except KeyboardInterrupt:
        log_message("INFO", "Module Manager received KeyboardInterrupt, initiating graceful shutdown.")
    except Exception as e:
        log_message("ERROR", f"Module Manager encountered an unexpected error in main loop: {e}")
    finally:
        # Clean up on exit
        log_message("INFO", "Automation Module Manager shutting down. Terminating any active child processes.")
        for module_name in list(running_processes.keys()):
            terminate_child_module(module_name)
        log_message("INFO", "All child modules terminated.")

        if _module_manager_log_file_handle:
            _module_manager_log_file_handle.close()
            log_message("INFO", "Module Manager log file closed.")
        log_message("INFO", "Automation Module Manager exited.")


if __name__ == "__main__":
    main()
