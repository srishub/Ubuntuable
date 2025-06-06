
---
# Ubuntuable

## Effortless Ubuntu Customization with a User-Friendly GUI

Ubuntuable is a powerful Bash script designed to streamline and simplify customizing your Ubuntu desktop. Inspired by the Fedora customization script [Fedorable](https://github.com/smittix/fedorable), Ubuntuable provides a user-friendly graphical interface (GUI) via **Zenity** to guide you through various system updates, software installations, and aesthetic tweaks.

Say goodbye to hunting down commands and copy-pasting; Ubuntuable makes personalizing your Ubuntu experience as simple as a few clicks.

**Disclaimer** : _This script modifies your system. While it has been tested, use it at your own risk. It's always a good idea to back up important data before running any system modification scripts._

---

## Features

  * **System Update & Upgrade:** Keeps your Ubuntu system packages up-to-date.
  * **Core Utilities Installation:** Installs essential tools like `git`, `curl`, `vim`, `htop`, and `build-essential`.
  * **Developer Tools Setup:** Quickly sets up [Node.js](https://nodejs.org/en), [Python](https://www.python.org/), and [Visual Studio Code](https://code.visualstudio.com/).
  * **GNOME Customization:** Installs [GNOME Tweaks](https://wiki.gnome.org/Apps/Tweaks) `gnome-tweaks gnome-shell-extensions yaru-theme-gtk yaru-theme-icon gnome-shell-extension-manager` and applies a Yaru-dark theme for a sleek look. (`User Themes` need to be enabled in `extensions`)
  * **Flatpak Integration:** Sets up [Flatpak](https://flatpak.org/) and lets you select and install popular Flatpak applications from [Flathub](https://flathub.org/).
  * **Zsh & Oh My Zsh Configuration:** Installs [Zsh](https://www.zsh.org/) as your default shell, sets up [Oh My Zsh](https://ohmyz.sh/) (GitHub: [ohmyzsh/ohmyzsh](https://github.com/ohmyzsh/ohmyzsh)), and includes popular plugins like [`zsh-autosuggestions`](https://www.google.com/search?q=%5Bhttps://github.com/zsh-users/zsh-autosuggestions%5D\(https://github.com/zsh-users/zsh-autosuggestions\)) and [`zsh-syntax-highlighting`](https://www.google.com/search?q=%5Bhttps://github.com/zsh-users/zsh-syntax-highlighting%5D\(https://github.com/zsh-users/zsh-syntax-highlighting\)).
  * **Starship Prompt:** Installs and configures the cross-shell customizable [Starship prompt](https://starship.rs/) (GitHub: [starship/starship](https://github.com/starship/starship)).
  * **Hyper Snazzy Terminal Theme:** Applies the popular [Hyper Snazzy theme](https://github.com/sindresorhus/hyper-snazzy) to your GNOME Terminal for a vibrant, modern aesthetic.
  * **System Cleanup:** Removes unused packages and cleans up your APT cache.
  * **Optional Reboot:** Offers to reboot your system upon completion to ensure all changes take effect.

---

## Getting Started

### Prerequisites

* **Ubuntu Desktop:** This script is specifically designed for Ubuntu.
* **Internet Connection:** Required for downloading packages and applications.
* **`sudo` privileges:** The script will prompt you for your password via Zenity to perform necessary system-level operations.
* **Zenity:** The script will attempt to install Zenity if it's not found on your system.

### Installation & Usage

1.  **Download the script:**

    Copy the entire script content into a file named `ubuntuable.sh` on your Ubuntu system.

    ```bash
    nano ubuntuable.sh
    # Paste the script content here
    # Save and exit nano (Ctrl+S, Ctrl+X)
    ```

2.  **Make the script executable:**

    ```bash
    chmod +x ubuntuable.sh
    ```

3.  **Run the script:**

    ```bash
    ./ubuntuable.sh
    ```

    A graphical welcome message will appear, followed by a list of customization options. Select the tasks you wish to perform and click **"OK."** The script will then guide you through the process with progress dialogs.

---

## Contributing

Ubuntuable is open-source, and we welcome contributions! If you have ideas for new features, improvements, or bug fixes, feel free to:

* **Open an issue:** For bug reports or feature requests.
* **Submit a Pull Request:** With your proposed changes.

Please ensure your contributions stick to the existing code style and include clear, concise commit messages.

---

## License

This project is licensed under the MIT License. See the `LICENSE` file in the repository for full details.

---

