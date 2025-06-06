#!/bin/bash

# ubuntuable.sh - GUI based script to customize Ubuntu

# ----- Constants and Globals -----

RED=$(tput setaf 1 2>/dev/null || echo '\033[0;31m')
GREEN=$(tput setaf 2 2>/dev/null || echo '\033[0;32m')
YELLOW=$(tput setaf 3 2>/dev/null || echo '\033[1;33m')
NC=$(tput sgr0 2>/dev/null || echo '\033[0m') 

LOG_FILE="$HOME/ubuntuable.log"
# Use a temporary file to collect logs from subshells reliably
TEMP_INSTALLED_LOG="$HOME/.ubuntuable_installed_temp.log"

# ----- Utility Functions -----

print_message() {
    local color="${2:-$NC}"
    echo -e "${color}[ubuntuable] $1${NC}" | tee -a "$LOG_FILE"
}

log_installed() {
    # Appends message to the temporary log file, which will be merged later
    echo "$1" >> "$TEMP_INSTALLED_LOG"
    print_message "$1" "$GREEN"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

confirm_zenity() {
    zenity --question --title="Ubuntuable" --text="$1" --width=400 2>>"$LOG_FILE"
}

progress_dialog() {
    local cmd="$1"
    local message="$2"
    local exit_status=0

    # Execute the command in a subshell, capturing its output to LOG_FILE, and for Zenity progress.
    ( eval "$cmd" 2>&1 | tee -a "$LOG_FILE" ) | \
        zenity --progress --title="Ubuntuable" --text="$message" --pulsate --auto-close --width=400 2>>"$LOG_FILE"

    if [ $? -ne 0 ]; then
        zenity --error --title="Ubuntuable" --text="Operation cancelled or failed during: $message\nCheck $LOG_FILE for details." --width=400
        print_message "Operation cancelled or failed during: $message. Check $LOG_FILE." "$RED"
        return 1
    fi
    return 0
}

task_selected() {
    local task="$1"
    for t in "${TASK_ARRAY[@]}"; do
        [[ "$t" == "$task" ]] && return 0
    done
    return 1
}

prompt_sudo() {
    if ! sudo -v -p "Enter your password for sudo: " 2>>"$LOG_FILE"; then
        zenity --error --title="Ubuntuable" --text="Sudo authentication failed. Exiting." --width=400 2>>"$LOG_FILE"
        print_message "Sudo authentication failed. Exiting." "$RED"
        exit 1
    fi
}

# ----- Installation Functions -----

install_zsh_with_plugins() {
    (
    set -e # Exit on errors in this subshell

    echo "10"; echo "# Checking and installing zsh..."
    print_message "Checking and installing zsh..." "$YELLOW"
    if ! command_exists zsh; then
        print_message "zsh not found, installing zsh..." "$YELLOW"
        sudo apt install -y zsh >> "$LOG_FILE" 2>&1
        log_installed "Installed zsh"
    else
        print_message "zsh already installed" "$GREEN"
    fi

    echo "35"; echo "# Checking and installing git..."
    print_message "Checking and installing git..." "$YELLOW"
    if ! command_exists git; then
        print_message "git not found, installing git..." "$YELLOW"
        sudo apt install -y git >> "$LOG_FILE" 2>&1
        log_installed "Installed git"
    else
        print_message "git already installed" "$GREEN"
    fi

    echo "60"; echo "# Installing Oh My Zsh (if missing)..."
    print_message "Installing Oh My Zsh (if missing)..." "$YELLOW"
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        if command_exists curl; then
            print_message "Downloading Oh My Zsh installer using curl..." "$YELLOW"
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> "$LOG_FILE" 2>&1
            log_installed "Installed Oh My Zsh"
        elif command_exists wget; then
            print_message "Downloading Oh My Zsh installer using wget..." "$YELLOW"
            sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> "$LOG_FILE" 2>&1
            log_installed "Installed Oh My Zsh"
        else
            echo "0"; echo "# curl or wget is required to install Oh My Zsh"
            print_message "curl or wget not found. Cannot install Oh My Zsh." "$RED"
            exit 1
        fi
    else
        print_message "Oh My Zsh already installed" "$GREEN"
    fi

    echo "75"; echo "# Installing zsh-autosuggestions plugin..."
    print_message "Installing zsh-autosuggestions plugin..." "$YELLOW"
    local ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" >> "$LOG_FILE" 2>&1
        log_installed "Installed zsh-autosuggestions plugin"
    else
        print_message "zsh-autosuggestions plugin already installed" "$GREEN"
    fi

    echo "85"; echo "# Installing zsh-syntax-highlighting plugin..."
    print_message "Installing zsh-syntax-highlighting plugin..." "$YELLOW"
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" >> "$LOG_FILE" 2>&1
        log_installed "Installed zsh-syntax-highlighting plugin"
    else
        print_message "zsh-syntax-highlighting plugin already installed" "$GREEN"
    fi

    echo "95"; echo "# Updating plugins in .zshrc..."
    print_message "Updating plugins in ~/.zshrc..." "$YELLOW"
    local ZSHRC="$HOME/.zshrc"

    if [ -f "$ZSHRC" ]; then
        # Ensure plugins line exists and add if not
        if ! grep -q "plugins=(" "$ZSHRC"; then
            sed -i "/source \$ZSH\/oh-my-zsh.sh/i plugins=(git)" "$ZSHRC"
            print_message "Added default plugins line to ~/.zshrc" "$GREEN"
        fi

        for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
            if ! grep -q "plugins=(.*$plugin.*)" "$ZSHRC"; then
                sed -i "s/^plugins=(\(.*\))/plugins=(\1 $plugin)/" "$ZSHRC"
                print_message "Added $plugin to ~/.zshrc plugins" "$GREEN"
            else
                print_message "$plugin already in ~/.zshrc plugins" "$GREEN"
            fi
        done
    else
        print_message "~/.zshrc not found, creating minimal config..." "$YELLOW"
        {
            echo "export ZSH=\"$HOME/.oh-my-zsh\""
            echo "ZSH_THEME=\"robbyrussell\""
            echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"
            echo "source \$ZSH/oh-my-zsh.sh"
        } > "$ZSHRC"
        log_installed "Created minimal ~/.zshrc with plugins configured"
    fi

    echo "100"; echo "# Installation complete!"
    print_message "Zsh and Oh My Zsh plugins setup complete!" "$GREEN"

    ) | zenity --progress --title="Installing Zsh + Oh My Zsh plugins" --percentage=0 --auto-close --width=400

    if [ $? -eq 0 ]; then
        zenity --info --title="Installation Complete" --text="Zsh with oh-my-zsh and plugins installed!\nPlease restart your terminal or run:\nexec zsh" --width=400 2>>"$LOG_FILE"
    else
        zenity --error --title="Installation Failed" --text="An error occurred during installation.\nPlease check $LOG_FILE for details." --width=400 2>>"$LOG_FILE"
    fi
}

install_flatpak_and_apps() {
    (
    set -e # Exit on errors in this subshell

    echo 10; echo "# Installing Flatpak..."
    sudo apt install -y flatpak >> "$LOG_FILE" 2>&1
    log_installed "Installed Flatpak"

    echo 30; echo "# Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >> "$LOG_FILE" 2>&1
    log_installed "Added Flathub repository"

    echo 40; echo "# Updating Flatpak repository..."
    flatpak update --appstream --assumeyes >> "$LOG_FILE" 2>&1 || true
    print_message "Updated Flatpak appstream" "$GREEN"

    echo 50; echo "# Installing selected Flatpak applications..."

    local selected_zenity_items=("$@")
    declare -a FLATPAK_IDS_TO_INSTALL

    for item in "${selected_zenity_items[@]}"; do
        local flatpak_id=$(echo "$item" | cut -d ':' -f 2 | xargs)
        if [[ -n "$flatpak_id" ]]; then
            FLATPAK_IDS_TO_INSTALL+=("$flatpak_id")
        fi
    done

    local total_apps=${#FLATPAK_IDS_TO_INSTALL[@]}
    local current_app_num=0

    if [[ "$total_apps" -eq 0 ]]; then
        echo "100"; echo "# No Flatpak apps identified for installation."
        print_message "No Flatpak apps were identified for installation from your selection." "$YELLOW"
        exit 0 # Exit successfully if no apps to install
    fi

    for app_id in "${FLATPAK_IDS_TO_INSTALL[@]}"; do
        current_app_num=$((current_app_num + 1))
        local progress=$(( 50 + (current_app_num * 50 / total_apps) ))
        echo "$progress"; echo "# Installing $app_id..."
        print_message "Attempting to install Flatpak app: $app_id" "$YELLOW"
        if ! flatpak install -y flathub "$app_id" >> "$LOG_FILE" 2>&1; then
            print_message "WARNING: Could not install Flatpak app: $app_id. Check $LOG_FILE." "$YELLOW"
        else
            log_installed "Installed Flatpak app: $app_id"
        fi
    done

    echo 100; echo "# Flatpak apps installation complete!"
    print_message "Flatpak and selected apps installation process completed." "$GREEN"

    ) | zenity --progress --title="Installing Flatpak and Apps" --percentage=0 --auto-close --width=450

    if [ $? -eq 0 ]; then
        zenity --info --title="Installation Complete" --text="Flatpak and selected applications installed." --width=400 2>>"$LOG_FILE"
    else
        zenity --error --title="Installation Failed" --text="An error occurred during Flatpak installation.\nPlease check $LOG_FILE for details." --width=400 2>>"$LOG_FILE"
        return 1
    fi
    return 0
}

# ----- Main Script Execution -----

# Prevent running as root
if [[ $EUID -eq 0 ]]; then
    if command_exists zenity; then
        zenity --error --title="Ubuntuable" --text="Do not run this script as root! Use a standard user with sudo privileges." --width=400 2>>"$LOG_FILE"
    else
        print_message "Do not run this script as root! Use a standard user with sudo privileges." "$RED"
    fi
    exit 1
fi

# Init log files
echo "[ubuntuable] Script started at $(date)" > "$LOG_FILE"
> "$TEMP_INSTALLED_LOG" # Clear the temporary log file at start

# Ensure zenity installed
if ! command_exists zenity; then
    print_message "Zenity not found. Installing..." "$YELLOW"
    if ! sudo apt update -y 2>>"$LOG_FILE"; then
        print_message "Failed apt update. Check connection or sources." "$RED"
        exit 1
    fi
    if ! sudo apt install -y zenity 2>>"$LOG_FILE"; then
        print_message "Failed to install zenity. Please install manually." "$RED"
        exit 1
    fi
    log_installed "Installed package: zenity"
fi

# Check terminal color support
if ! tput setaf 1 >/dev/null 2>&1 && [[ "$TERM" != @(xterm|xterm-256color) ]]; then
    print_message "Warning: Terminal may not support colors." "$YELLOW"
fi

# Welcome message
zenity --info --title="Ubuntuable" --text="Welcome to Ubuntuable - Customizing your Ubuntu setup!" --width=400 2>>"$LOG_FILE"

# Task selection dialog
TASKS=$(zenity --list --checklist \
    --title="Ubuntuable - Select Tasks" \
    --text="Choose the tasks to perform:" \
    --column="Select" --column="Task" \
    FALSE "Update and upgrade system packages" \
    FALSE "Install core utilities (git, curl, vim, htop, build-essential)" \
    FALSE "Install developer tools (Node.js, Python, VS Code)" \
    FALSE "Install GNOME Tweaks and set up themes/extensions" \
    FALSE "Set up Flatpak and install selected Flatpak apps" \
    FALSE "Install and configure zsh with Oh My Zsh" \
    FALSE "Install Starship prompt" \
    FALSE "Apply Hyper Snazzy theme to GNOME Terminal" \
    FALSE "Clean up unused packages and cache" \
    FALSE "Reboot after setup" \
    --separator=":" --width=500 --height=400 2>>"$LOG_FILE")

if [[ -z "$TASKS" ]]; then
    zenity --error --title="Ubuntuable" --text="No tasks selected. Exiting." --width=400 2>>"$LOG_FILE"
    print_message "No tasks selected. Exiting." "$RED"
    exit 1
fi

IFS=":" read -r -a TASK_ARRAY <<< "$TASKS"

prompt_sudo

# Update system
if task_selected "Update and upgrade system packages"; then
    progress_dialog \
    "sudo apt update -y && sudo apt upgrade -y && sudo apt install -y software-properties-common apt-transport-https curl" \
    "Updating system..." && log_installed "Updated system and installed core APT dependencies"
fi

# Core utilities
if task_selected "Install core utilities (git, curl, vim, htop, build-essential)"; then
    progress_dialog \
    "sudo apt install -y git curl vim htop build-essential" \
    "Installing core utilities..." && log_installed "Installed core utilities: git, curl, vim, htop, build-essential"
fi

# Developer tools
if task_selected "Install developer tools (Node.js, Python, VS Code)"; then
    progress_dialog "bash -c '
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - >> \"$LOG_FILE\" 2>&1 &&
        sudo apt install -y nodejs python3 python3-pip python3-venv >> \"$LOG_FILE\" 2>&1 &&
        if ! command -v code >/dev/null 2>&1; then
            curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg >> \"$LOG_FILE\" 2>&1 &&
            echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main\" | sudo tee /etc/apt/sources.list.d/vscode.list >> \"$LOG_FILE\" 2>&1 &&
            sudo apt update >> \"$LOG_FILE\" 2>&1 &&
            sudo apt install -y code >> \"$LOG_FILE\" 2>&1
        fi
    '" "Installing developer tools..." && {
        local DEV_TOOLS="Installed developer tools: nodejs, python3, python3-pip, python3-venv"
        command_exists code && DEV_TOOLS+=", VS Code"
        log_installed "$DEV_TOOLS"
    }
fi

# Flatpak and apps
if task_selected "Set up Flatpak and install selected Flatpak apps"; then
    FLATPAK_APPS_SELECTION=$(zenity --list --checklist \
        --title="Ubuntuable - Select Flatpak Apps" \
        --text="Choose Flatpak applications to install:" \
        --column="Select" --column="Flatpak ID" --column="Application Name" \
        TRUE "org.mozilla.firefox" "Firefox" \
        TRUE "org.videolan.VLC" "VLC" \
        TRUE "org.gimp.GIMP" "GIMP" \
        TRUE "org.libreoffice.LibreOffice" "LibreOffice" \
        TRUE "org.onlyoffice.desktopeditors" "ONLYOFFICE Desktop Editors" \
        --separator=":" --width=600 --height=400 2>>"$LOG_FILE")

    if [[ -n "$FLATPAK_APPS_SELECTION" ]]; then
        IFS=$'\n' read -r -d '' -a FLATPAK_APPS_ARRAY <<< "$FLATPAK_APPS_SELECTION"
        if install_flatpak_and_apps "${FLATPAK_APPS_ARRAY[@]}"; then
            true # No-op if function succeeds, log_installed is called within the function
        fi
    else
        print_message "No Flatpak apps selected from the dialog, skipping Flatpak app installation." "$YELLOW"
    fi
fi

# GNOME tweaks
if task_selected "Install GNOME Tweaks and set up themes/extensions"; then
    progress_dialog "bash -c '
        sudo apt install -y gnome-tweaks gnome-shell-extensions yaru-theme-gtk yaru-theme-icon gnome-shell-extension-manager >> \"$LOG_FILE\" 2>&1 &&
        gsettings set org.gnome.desktop.interface gtk-theme \"Yaru-dark\" &&
        gsettings set org.gnome.desktop.interface icon-theme \"Yaru\"
    '" "Installing GNOME customization tools..." && log_installed "Installed GNOME Tweaks, extensions, and applied Yaru-dark theme"
fi

# Zsh & Oh My Zsh with plugins
if task_selected "Install and configure zsh with Oh My Zsh"; then
    install_zsh_with_plugins
fi

# Starship prompt
if task_selected "Install Starship prompt"; then
    (
    set -e # Exit on errors in this subshell

    echo "10"; echo "# Checking curl..."
    if ! command_exists curl; then
        zenity --error --title="Starship" --text="curl not found. Please install curl to proceed with Starship installation." --width=400 2>>"$LOG_FILE"
        print_message "curl not found. Please install curl." "$RED"
        exit 1
    fi

    echo "50"; echo "# Installing Starship..."
    if ! curl -sS https://starship.rs/install.sh | bash -s -- -y >> "$LOG_FILE" 2>&1; then
        zenity --error --title="Starship" --text="Failed to install Starship. See $LOG_FILE." --width=400 2>>"$LOG_FILE"
        print_message "Failed to install Starship." "$RED"
        exit 1
    fi
    log_installed "Installed Starship prompt"

    echo "80"; echo "# Configuring Starship for zsh..."
    local ZSHRC="$HOME/.zshrc"
    if [ -f "$ZSHRC" ]; then
        if ! grep -q "starship init zsh" "$ZSHRC"; then
            echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
            log_installed "Configured Starship prompt in ~/.zshrc"
        else
            log_installed "Starship prompt already configured in ~/.zshrc"
        fi
    else
        echo 'eval "$(starship init zsh)"' > "$ZSHRC"
        log_installed "Created ~/.zshrc with Starship configuration"
    fi

    echo "100"
    print_message "Starship prompt installation and configuration complete!" "$GREEN"
    ) | zenity --progress --title="Installing Starship prompt" --percentage=0 --auto-close --width=400

    if [ $? -ne 0 ]; then
        zenity --error --title="Starship" --text="Starship installation canceled or failed. See $LOG_FILE." --width=400 2>>"$LOG_FILE"
    fi
fi

# Apply Hyper Snazzy theme
if task_selected "Apply Hyper Snazzy theme to GNOME Terminal"; then
    (
    set -e # Exit on errors in this subshell

    echo "10"; echo "# Checking dconf..."
    if ! command_exists dconf; then
        print_message "dconf not found. Installing dconf-cli..." "$YELLOW"
        sudo apt install -y dconf-cli >> "$LOG_FILE" 2>&1 || {
            zenity --error --title="Hyper Snazzy" --text="Failed to install dconf-cli. Please install it manually." --width=400 2>>"$LOG_FILE"
            exit 1
        }
        log_installed "Installed dconf-cli"
    fi

    echo "30"; echo "# Preparing Hyper Snazzy profile..."

    PROFILE_NAME="Hyper Snazzy"
    PROFILE_ID=""
    CURRENT_LIST=$(dconf read /org/gnome/terminal/legacy/profiles:/list | tr -d '[]' | sed "s/, / /g")

    if [[ -n "$CURRENT_LIST" ]]; then
        for id in $(echo "$CURRENT_LIST" | tr -d "'" | tr " " "\n"); do
            id="${id// }"
            local name
            name=$(dconf read /org/gnome/terminal/legacy/profiles:/:$id/visible-name | tr -d "'")
            [[ "$name" == "$PROFILE_NAME" ]] && PROFILE_ID="$id" && break
        done
    fi

    if [[ -z "$PROFILE_ID" ]]; then
        PROFILE_ID=$(uuidgen)
        PROFILE_ID=$(echo "$PROFILE_ID" | tr '[:upper:]' '[:lower:]')

        if [[ -n "$CURRENT_LIST" ]]; then
            NEW_LIST="['$(echo "$CURRENT_LIST" | tr -d "'")', '$PROFILE_ID']"
        else
            NEW_LIST="['$PROFILE_ID']"
        fi
        dconf write /org/gnome/terminal/legacy/profiles:/list "$NEW_LIST" >> "$LOG_FILE" 2>&1 || { exit 1; }
        dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/visible-name "'$PROFILE_NAME'" >> "$LOG_FILE" 2>&1 || { exit 1; }
        print_message "Created GNOME Terminal profile: $PROFILE_NAME ($PROFILE_ID)" "$GREEN"
    else
        print_message "Found existing GNOME Terminal profile: $PROFILE_NAME ($PROFILE_ID)" "$GREEN"
    fi

    local BASE_KEY="/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID"

    dset() {
        local key="$1"; shift
        local val="$1"; shift
        dconf write "$BASE_KEY/$key" "$val" >>"$LOG_FILE" 2>&1 || exit 1
    }

    echo "50"; echo "# Applying theme settings..."

    dset use-theme-colors "false"
    dset background-color "'#282a36'"
    dset foreground-color "'#eff0eb'"
    dset palette "['#282a36', '#ff5c57', '#5af78e', '#f3f99d', '#57c7ff', '#ff6ac1', '#9aedfe', '#eff0eb', '#282a36', '#ff5c57', '#5af78e', '#f3f99d', '#57c7ff', '#ff6ac1', '#9aedfe', '#eff0eb']"
    dset bold-color-same-as-fg "true"
    dset visible-name "'$PROFILE_NAME'"
    dset use-transparent-background "false"
    dset use-theme-transparency "true"

    echo "80"; echo "# Setting default profile..."

    dconf write /org/gnome/terminal/legacy/profiles:/default "'$PROFILE_ID'" >> "$LOG_FILE" 2>&1 || exit 1
    print_message "Set Hyper Snazzy as default GNOME Terminal profile" "$GREEN"

    echo "100"
    print_message "Hyper Snazzy theme applied successfully!" "$GREEN"
    ) | zenity --progress --title="Applying Hyper Snazzy theme" --percentage=0 --auto-close --width=400

    if [ $? -ne 0 ]; then
        zenity --error --title="Hyper Snazzy" --text="Failed to apply theme. See $LOG_FILE." --width=400 2>>"$LOG_FILE"
    fi
fi

# Clean up
if task_selected "Clean up unused packages and cache"; then
    progress_dialog "sudo apt autoremove -y && sudo apt autoclean" "Cleaning up..." && log_installed "Cleaned up unused packages and cache"
fi

# Final summary (reads from temporary log)
if [[ -f "$TEMP_INSTALLED_LOG" ]]; then
    INSTALLED_LOG=$(cat "$TEMP_INSTALLED_LOG")
fi

if [[ -n "${INSTALLED_LOG//[[:space:]]/}" ]]; then
    zenity --info --title="Ubuntuable - Summary" --text="Setup complete! Items installed:\n$INSTALLED_LOG" --width=500 --height=300 2>>"$LOG_FILE"
else
    zenity --info --title="Ubuntuable - Summary" --text="Setup complete! No new items were installed." --width=400 2>>"$LOG_FILE"
fi

print_message "Setup completed successfully." "$GREEN"

# Reboot prompt
if task_selected "Reboot after setup"; then
    if confirm_zenity "The setup is complete. It is recommended to reboot your system for all changes to take effect. Do you want to reboot now?"; then
        zenity --info --title="Ubuntuable" --text="Rebooting now..." --width=400 2>>"$LOG_FILE"
        print_message "Rebooting system..." "$YELLOW"
        sudo reboot
    fi
fi

# Clean up temporary log file at the very end
rm -f "$TEMP_INSTALLED_LOG" >> "$LOG_FILE" 2>&1