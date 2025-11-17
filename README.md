# My macOS Setup

A simple and basic quick guide for macOS with focus on a clean environment for both development and cybersecurity, with ZSH configuration and Ghostty terminal config that keeps development tools updated and the system clean.

![Terminal preview](1.png)

## What does zsh.sh do?

The ZSH configuration file makes updating and handling versions easier by providing:
- **Update commands** - `update` to update all tools, `verify` to check status, `versions` to show versions
- **Tool management** - Easy setup for Python (pyenv), Node.js (nvm), Ruby (chruby), Rust, Go, Java
- **Database support** - MySQL, MongoDB, PostgreSQL status monitoring
- **Useful aliases** and commands for daily use
- **Oh My Zsh** with Powerlevel10k theme for better terminal experience 

## Installation

```bash
# Backup existing config
cp ~/.zshrc ~/.zshrc.backup

# Copy new config
cp zsh.sh ~/.zshrc

# Reload shell
source ~/.zshrc
# Then you can use: reloadzsh
```

## Usage

```bash
update    # Update all tools
verify    # Check status of all tools  
versions  # Show versions of all tools
```

## Supported Tools

### Built-in macOS Development Tools
- **C/C++** - Install Clang compiler and development tools with: `xcode-select --install`
- **Xcode** - Apple's IDE for C/C++ development (available from App Store)

### Package Managers
- Homebrew, MacPorts

### Language Runtimes
- **Python (pyenv)** - Completely isolated from macOS system Python
- **Ruby (chruby)** - Completely isolated from macOS system Ruby
- **Node.js (nvm)** - Node version management
- **Rust (rustup)** - Rust toolchain management
- **Go, Java** - Additional language support

### Databases & Services
- Docker, MySQL, MongoDB, PostgreSQL

---

## Useful Programs I Use

### Cybersecurity & CTF Tools
All tools for cybersec and CTF practice are installed through Homebrew & MacPorts for easy maintenance and upgrades.

### Virtualization
- **VMware Fusion 13 Pro** - For Kali Linux and Windows 11 VMs
  - [Download Link](https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Fusion&displayGroup=VMware%20Fusion%2013&release=13.6.4&os=&servicePk=533271&language=EN&freeDownloads=true) (requires account)
- **UTM** - For x86 processor emulation on ARM-based Macs

---

## Mac Security

### Security Guide
Follow this comprehensive guide: [macOS Security and Privacy Guide](https://github.com/drduh/macOS-Security-and-Privacy-Guide)

### Security Tools
Install and use tools from [Objective-See](https://objective-see.org/tools.html):

- **Lulu** - Firewall hardening and notification popups
- **KnockKnock** - Scanning and matching hashes on VirusTotal
- **Dylib Scanner** - Scans programs for dylib hijacking vulnerabilities
- **Oversight** - Monitors microphone and camera access

All tools are open source: [Objective-See GitHub](https://github.com/objective-see)

---

## System Maintenance & Useful Programs

### macOS System Cleanup
macOS has issues with handling system data and resources after removing/uninstalling programs. Here's how to keep it clean:

1. **Clear system cache**: 
   - Go to Finder > Go > Go to Folder
   - Type `~/Library/Caches` and hit enter
   - Select all folders inside and delete them

2. **Clear system logs**:
   - Go to Finder > Go > Go to Folder  
   - Type `/var/log` and hit enter
   - Select all files inside and delete them

3. **Remove unused language files**:
   - Go to Finder > Go > Go to Folder
   - Type `/Library/Languages` and hit enter
   - Delete language folders you don't need

4. **Uninstall unused apps**:
   - Go to Applications folder and delete unused apps

5. **Clean up system files**:
   - Use CleanMyMac (with blocked network connections) to scan and remove unnecessary files
   - Note: CleanMyMac is known as bloatware, but with blocked connections it's effective for just the system cleanup function

### Useful Utilities

- **[Pearcleaner](https://github.com/alienator88/Pearcleaner)** - For properly uninstalling programs
- **[Keka](https://github.com/aonez/Keka)** - For zipping and extracting files
- **[Maccy](https://github.com/p0deje/Maccy)** - Clipboard history manager
- **[Ice](https://github.com/jordanbaird/Ice)** - Menu bar modification tool
- **[Ghostty](https://github.com/mitchellh/ghostty)** - Terminal emulator (see config section below)
- **CleanMyMac** - System cleaner (use with blocked network connections)
- **[BetterDisplay](https://github.com/waydabber/BetterDisplay)** - Better control of display scaling and resolution

## Terminal Configuration

### ZSH Plugins
```bash
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
```

### Ghostty (terminal)
- Config file in this repo: `Ghostty config.txt`
- In Ghostty settings, open the config file and paste in the contents of `Ghostty config.txt`.
- The background image `1.png` is included in this folder; use it as your Ghostty background or point `background-image` to your own image.

### Useful Tools
- [FZF](https://github.com/junegunn/fzf) - Fuzzy finder
- [ZSH Syntax Highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [ZSH Autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - ZSH theme
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) - ZSH framework

---

**Note**: This configuration works on both Intel and Apple Silicon Macs.
**Note**: This is a very basic quick guide and you should always do your own research. 