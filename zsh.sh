#!/usr/bin/env zsh

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ================================ PATH =====================================
_detect_brew_prefix() {
  # Check for Apple Silicon Homebrew first
  if [[ -d /opt/homebrew ]]; then
    echo /opt/homebrew
  # Check for Intel Homebrew
  elif [[ -d /usr/local/Homebrew ]]; then
    echo /usr/local
  else
    echo ""
  fi
}
HOMEBREW_PREFIX="$(_detect_brew_prefix)"
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
fi
export PATH="$HOME/.local/bin:$PATH"

# ================================ chruby/Ruby ===============================
for _chruby_path in \
  "/opt/homebrew/opt/chruby/share/chruby/chruby.sh" \
  "/usr/local/opt/chruby/share/chruby/chruby.sh" \
  "/usr/local/share/chruby/chruby.sh" \
  "$HOME/.local/share/chruby/chruby.sh"
do
  [[ -f "$_chruby_path" ]] && { . "$_chruby_path" 2>/dev/null || true; break; }
done
unset _chruby_path
for _chruby_auto in \
  "/opt/homebrew/opt/chruby/share/chruby/auto.sh" \
  "/usr/local/opt/chruby/share/chruby/auto.sh" \
  "/usr/local/share/chruby/auto.sh"
do
  [[ -f "$_chruby_auto" ]] && { . "$_chruby_auto" 2>/dev/null || true; break; }
done
unset _chruby_auto

_chruby_latest_installed() {
  command -v chruby >/dev/null 2>&1 || return 1
  chruby 2>/dev/null | sed -E 's/^[* ]+//' | grep -E '^ruby-[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1
}
_chruby_install_latest() {
  command -v chruby >/dev/null 2>&1 || return 1
  command -v ruby-install >/dev/null 2>&1 || return 1
  local latest
  latest="$(ruby-install --list ruby 2>/dev/null | awk '/^ruby [0-9]+\.[0-9]+\.[0-9]+$/ {print $2}' | sort -V | tail -n1)"
  [[ -n "$latest" ]] || return 1
  if ! chruby 2>/dev/null | sed -E 's/^[* ]+//' | grep -qx "ruby-$latest"; then
    ruby-install ruby "$latest" || return 1
  fi
  echo "ruby-$latest"
}
if command -v chruby >/dev/null 2>&1; then
  _ruby_target="$(_chruby_latest_installed)"
  if [[ -z "$_ruby_target" ]]; then
    if command -v ruby-install >/dev/null 2>&1; then
      _ruby_target="$(_chruby_install_latest || true)"
    fi
  fi
  [[ -n "$_ruby_target" ]] && chruby "$_ruby_target" 2>/dev/null || true
  unset _ruby_target
fi
_setup_gem_path() {
  if ! command -v ruby >/dev/null 2>&1; then return 0; fi
  local engine api
  engine=$(ruby -e 'print defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"' 2>/dev/null)
  api=$(ruby -e 'require "rbconfig"; print RbConfig::CONFIG["ruby_version"]' 2>/dev/null)
  [[ -z "$engine" || -z "$api" ]] && return 0
  export GEM_HOME="$HOME/.gem/$engine/$api"
  export GEM_PATH="$GEM_HOME"
  export PATH="$GEM_HOME/bin:$PATH"
}
_setup_gem_path
autoload -Uz add-zsh-hook
add-zsh-hook precmd _setup_gem_path

# ================================== pyenv ==================================
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Fix corrupted pyenv shim if it exists
if [[ -f "$PYENV_ROOT/shims/.pyenv-shim" ]]; then
  rm -f "$PYENV_ROOT/shims/.pyenv-shim" 2>/dev/null || true
fi

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)" 2>/dev/null
  if [[ -s "$PYENV_ROOT/plugins/pyenv-virtualenv/bin/pyenv-virtualenv" ]]; then
    eval "$(pyenv virtualenv-init -)" 2>/dev/null
  fi
fi
_pyenv_latest_available() {
  pyenv install --list 2>/dev/null | sed 's/^[[:space:]]*//' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1
}
_pyenv_latest_installed() {
  pyenv versions --bare 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1
}
_pyenv_activate_latest() {
  command -v pyenv >/dev/null 2>&1 || return 1
  local target="${1:-$(_pyenv_latest_available)}"
  [[ -n "$target" ]] || return 1
  if ! pyenv versions --bare | grep -qx "$target"; then
    pyenv install -s "$target" || return 1
    pyenv rehash 2>/dev/null || true
  fi
  pyenv global "$target" || return 1
  pyenv rehash >/dev/null 2>&1 || true
  printf "%s" "$target"
}

# ================================== nvm ====================================
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
command -v nvm >/dev/null 2>&1 && nvm use default >/dev/null 2>&1 || true

# ================================= Rust ====================================
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ================================ ALIASES ==================================
if command -v colorls >/dev/null 2>&1; then
  alias ls='colorls'
else
  alias ls='ls -G'
fi
alias myip="curl -s ifconfig.me"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias reloadzsh="source ~/.zshrc"
alias change="cot ~/.zshrc"

alias mysqlstart="sudo /usr/local/mysql/support-files/mysql.server start"
alias mysqlstop="sudo /usr/local/mysql/support-files/mysql.server stop"
alias mysqlstatus="sudo /usr/local/mysql/support-files/mysql.server status"
alias mysqlrestart="sudo /usr/local/mysql/support-files/mysql.server restart"
alias mysqlconnect="mysql -u root -p"

if [[ -d "/opt/homebrew/opt/openjdk/bin" ]]; then
  export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
fi

# ================================ SYSTEM COMPATIBILITY ====================

_check_macos_compatibility() {
  # Verify we're running on macOS
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "ERROR: This script is designed for macOS only"
    return 1
  fi
  
  # Detect architecture
  local arch=""
  case "$(uname -m)" in
    x86_64) arch="Intel" ;;
    arm64) arch="Apple Silicon" ;;
    *) arch="Unknown" ;;
  esac
  
  echo "[macOS] Detected: macOS ($arch)"
  
  # Check for Homebrew
  if [[ -z "$HOMEBREW_PREFIX" ]]; then
    echo "  WARNING: Homebrew not detected - some features may not work"
  else
    echo "  Homebrew found at: $HOMEBREW_PREFIX"
  fi
  
  # Check available disk space
  if command -v df >/dev/null 2>&1; then
    local available_space=$(df -h . | awk 'NR==2 {print $4}' | sed 's/[^0-9.]//g')
    if [[ -n "$available_space" && "$available_space" -lt 1 ]]; then
      echo "  WARNING: Low disk space detected ($available_space GB available)"
    fi
  fi
}

# ================================ UPDATE ===================================

# ================================ RUBY GEM COMPATIBILITY ===================

_fix_all_ruby_gems() {
  echo "[Ruby] Auto-fixing Ruby gems for compatibility..."
  
  if ! command -v ruby >/dev/null 2>&1; then
    echo "  ERROR: Ruby not found, skipping gem fix"
    return 1
  fi
  
  local current_ruby="$(ruby -v | cut -d' ' -f2)"
  echo "  Current Ruby version: $current_ruby"
  
  # Get all installed gems
  local installed_gems=($(gem list --no-versions 2>/dev/null || true))
  
  if [[ ${#installed_gems[@]} -eq 0 ]]; then
    echo "  No gems found to check"
    return 0
  fi
  
  echo "  Checking ${#installed_gems[@]} installed gems..."
  
  local fixed_count=0
  local problematic_gems=()
  local working_gems=0
  
  
  # Check each gem for issues
  for gem in "${installed_gems[@]}"; do
    # Skip default gems that can't be uninstalled
    if gem list "$gem" | grep -q "default"; then
      ((working_gems++))
      continue
    fi
    
    # Check if gem executable exists and works
    local gem_executable=""
    local executable_path=""
    if executable_path="$(gem contents "$gem" 2>/dev/null | grep -E "(bin/|exe/)" | head -n1)"; then
      gem_executable="$(basename "$executable_path")"
    fi
    
    # Check if gem is problematic
    local is_problematic=false
    
    # Check if gem has executables and test them
    if [[ -n "$gem_executable" ]]; then
      # Check if executable is in PATH
      if command -v "$gem_executable" >/dev/null 2>&1; then
        # Test if the executable actually works
        if ! "$gem_executable" --version >/dev/null 2>&1 && ! "$gem_executable" -v >/dev/null 2>&1 && ! "$gem_executable" --help >/dev/null 2>&1; then
          is_problematic=true
          echo "  DETECTED: $gem executable is broken"
        else
          ((working_gems++))
        fi
      else
        # Executable not in PATH - might be problematic
        is_problematic=true
        echo "  DETECTED: $gem executable not found in PATH"
      fi
    else
      # Gems without executables are considered working
      ((working_gems++))
    fi
    
    if [[ "$is_problematic" == true ]]; then
      # Check if gem is already in problematic_gems array
      local already_listed=false
      for existing_gem in "${problematic_gems[@]}"; do
        if [[ "$existing_gem" == "$gem" ]]; then
          already_listed=true
          break
        fi
      done
      
      if [[ "$already_listed" == false ]]; then
        problematic_gems+=("$gem")
      fi
      
      echo "  FIXING: $gem..."
      
      # Uninstall and reinstall (non-interactive)
      gem uninstall "$gem" --ignore-dependencies --force --no-user-install 2>/dev/null || true
      if gem install "$gem" --no-user-install 2>/dev/null; then
        ((fixed_count++))
        echo "    SUCCESS: Fixed $gem"
      else
        echo "    WARNING: Failed to fix $gem"
      fi
    fi
  done
  
  # Reinstall gems from Gemfile if it exists
  if [[ -f "Gemfile" ]]; then
    echo "  BUNDLE: Reinstalling gems from Gemfile..."
    bundle install 2>/dev/null || echo "    WARNING: Bundle install failed"
  fi
  
  # Clear gem cache
  echo "  CLEANUP: Clearing gem cache..."
  gem cleanup 2>/dev/null || true
  
  if [[ $fixed_count -gt 0 ]]; then
    echo "  SUCCESS: Fixed $fixed_count problematic gems ($working_gems working properly)"
  else
    echo "  SUCCESS: All $working_gems gems are working properly"
  fi
  
  # Refresh command hash table after gem changes
  hash -r 2>/dev/null || true
}

# ================================ PYTHON COMPATIBILITY =====================

_check_python_package_compatibility() {
  local current_python="$1"
  local target_python="$2"
  local package_name="$3"
  
  # Sjekk om pakken har Python-versjon krav
  local requirements=""
  if command -v pip >/dev/null 2>&1; then
    requirements="$(pip show "$package_name" 2>/dev/null | grep -i "requires-python" | cut -d: -f2 | tr -d ' ' || true)"
  fi
  
  if [[ -n "$requirements" ]]; then
    # Simple check for Python version requirements (can be extended for more complex parsing)
    if [[ "$requirements" == *"<"* ]] || [[ "$requirements" == *">"* ]] || [[ "$requirements" == *"!="* ]]; then
      echo "  WARNING: $package_name has Python version requirements: $requirements"
      return 1
    fi
  fi
  
  return 0
}

_check_pipx_package_compatibility() {
  local current_python="$1"
  local target_python="$2"
  local package_name="$3"
  
  # Sjekk pipx-pakke kompatibilitet
  local venv_path=""
  if command -v pipx >/dev/null 2>&1; then
    venv_path="$(pipx list --json 2>/dev/null | jq -r ".venvs.\"$package_name\".metadata.main_package.package" 2>/dev/null || true)"
  fi
  
  if [[ -n "$venv_path" ]]; then
    # Sjekk om pakken har spesifikke Python-versjon krav
    local package_info=""
    if [[ -f "$venv_path/bin/python" ]]; then
      package_info="$("$venv_path/bin/python" -c "
import pkg_resources
import sys
try:
    dist = pkg_resources.get_distribution('$package_name')
    if hasattr(dist, 'requires'):
        for req in dist.requires():
            if 'python' in str(req).lower():
                print(str(req))
                break
except:
    pass
" 2>/dev/null || true)"
    fi
    
    if [[ -n "$package_info" ]]; then
      echo "  WARNING: pipx package $package_name has Python version requirements: $package_info"
      return 1
    fi
  fi
  
  return 0
}

_check_python_upgrade_compatibility() {
  local current_python="$1"
  local target_python="$2"
  
  echo "[Python] Checking package compatibility before upgrade..."
  local incompatible_packages=()
  local incompatible_pipx_packages=()
  
  # Check regular pip packages
  if command -v pip >/dev/null 2>&1; then
    local installed_packages="$(pip list --format=freeze 2>/dev/null | cut -d= -f1 || true)"
    if [[ -n "$installed_packages" ]]; then
      echo "  Checking pip packages..."
      while IFS= read -r package; do
        [[ -z "$package" ]] && continue
        if ! _check_python_package_compatibility "$current_python" "$target_python" "$package"; then
          incompatible_packages+=("$package")
        fi
      done <<< "$installed_packages"
    fi
  fi
  
  # Check pipx packages
  if command -v pipx >/dev/null 2>&1; then
    local pipx_packages="$(pipx list --short 2>/dev/null | awk '{print $1}' || true)"
    if [[ -n "$pipx_packages" ]]; then
      echo "  Checking pipx packages..."
      while IFS= read -r package; do
        [[ -z "$package" ]] && continue
        if ! _check_pipx_package_compatibility "$current_python" "$target_python" "$package"; then
          incompatible_pipx_packages+=("$package")
        fi
      done <<< "$pipx_packages"
    fi
  fi
  
  # Report results
  if [[ ${#incompatible_packages[@]} -gt 0 ]] || [[ ${#incompatible_pipx_packages[@]} -gt 0 ]]; then
    echo "  ERROR: Incompatible packages found:"
    for package in "${incompatible_packages[@]}"; do
      echo "    - pip: $package"
    done
    for package in "${incompatible_pipx_packages[@]}"; do
      echo "    - pipx: $package"
    done
    echo "  WARNING: Python upgrade skipped to avoid breaking packages"
    return 1
  else
    echo "  SUCCESS: All packages are compatible with new Python version"
    return 0
  fi
}

unalias update 2>/dev/null
update() {
  echo "==> Update started $(date)"
  
  # Check macOS compatibility
  if ! _check_macos_compatibility; then
    echo "ERROR: This script requires macOS"
    return 1
  fi
  
  # Validate and fix PATH (integrated into update function)
  echo "[PATH] Validating and fixing PATH..."
  
  local path_issues=()
  local fixed_path="$PATH"
  
  # Check for common PATH issues
  if [[ "$PATH" == *"::"* ]]; then
    path_issues+=("Empty PATH entries (::)")
    fixed_path=$(echo "$fixed_path" | sed 's/::/:/g')
  fi
  
  # More comprehensive duplicate detection
  local path_array=($(echo "$fixed_path" | tr ':' '\n'))
  local unique_paths=()
  local seen_paths=()
  
  for path_entry in "${path_array[@]}"; do
    # Skip empty entries
    [[ -z "$path_entry" ]] && continue
    
    # Normalize path (resolve ~ and remove trailing slashes)
    local normalized_path="${path_entry/#\~/$HOME}"
    normalized_path="${normalized_path%/}"
    
    # Check if we've seen this path before
    local is_duplicate=false
    for seen_path in "${seen_paths[@]}"; do
      if [[ "$normalized_path" == "$seen_path" ]]; then
        is_duplicate=true
        break
      fi
    done
    
    if [[ "$is_duplicate" == false ]]; then
      unique_paths+=("$path_entry")
      seen_paths+=("$normalized_path")
    else
      # Track specific duplicate types for better reporting
      case "$path_entry" in
        "/usr/bin")
          path_issues+=("Duplicate /usr/bin entries")
          ;;
        "$HOME/.local/bin")
          path_issues+=("Duplicate ~/.local/bin entries")
          ;;
        *)
          path_issues+=("Duplicate $path_entry entries")
          ;;
      esac
    fi
  done
  
  # Rebuild PATH from unique entries
  fixed_path=$(printf "%s:" "${unique_paths[@]}" | sed 's/:$//')
  
  if [[ ${#path_issues[@]} -gt 0 ]]; then
    echo "  DETECTED: PATH issues found:"
    for issue in "${path_issues[@]}"; do
      echo "    - $issue"
    done
    export PATH="$fixed_path"
    echo "  FIXED: PATH cleaned up (removed ${#path_array[@]} - ${#unique_paths[@]} duplicates)"
  else
    echo "  SUCCESS: PATH is clean"
  fi
  
  # Check for Node.js symlink conflicts (integrated PATH validation)
  if command -v brew >/dev/null 2>&1 && brew list node >/dev/null 2>&1; then
    echo "[PATH] Checking Node.js symlink integrity..."
    
    local node_conflicts_found=false
    local conflicting_binaries=()
    
    # Check if brew upgrade would fail due to symlink conflicts
    local brew_output
    brew_output="$(brew upgrade --dry-run node 2>&1 || true)"
    if [[ "$brew_output" == *"Could not symlink"* ]] || [[ "$brew_output" == *"already exists"* ]]; then
      node_conflicts_found=true
      conflicting_binaries+=("upgrade_conflict")
    fi
    
    # Check common Node.js binaries for conflicts
    local node_binaries=("corepack" "npm" "npx")
    for binary in "${node_binaries[@]}"; do
      local brew_path="/opt/homebrew/bin/$binary"
      local homebrew_path="/usr/local/bin/$binary"
      
      # Check if file exists and is not a proper symlink to Homebrew
      if [[ -f "$brew_path" ]] || [[ -f "$homebrew_path" ]]; then
        local target_path=""
        if [[ -f "$brew_path" ]]; then
          target_path="$brew_path"
        else
          target_path="$homebrew_path"
        fi
        
        # Check if it's a broken symlink or conflicting file
        if [[ -L "$target_path" ]]; then
          local link_target
          link_target="$(readlink "$target_path" 2>/dev/null || true)"
          # Check if symlink is broken or doesn't point to Homebrew Cellar
          if [[ -z "$link_target" ]] || [[ ! -f "$target_path" ]] || [[ "$link_target" != *"Cellar/node"* ]]; then
            conflicting_binaries+=("$binary")
            node_conflicts_found=true
          fi
        elif [[ -f "$target_path" ]] && [[ ! -L "$target_path" ]]; then
          # Regular file instead of symlink - might be conflicting
          conflicting_binaries+=("$binary")
          node_conflicts_found=true
        fi
      fi
    done
    
    if [[ "$node_conflicts_found" == true ]]; then
      echo "  DETECTED: Node.js symlink conflicts: ${conflicting_binaries[*]}"
      echo "  FIXING: Resolving Node.js symlink conflicts..."
      
      # Try the recommended approach first
      if brew unlink node 2>/dev/null && brew link node 2>/dev/null; then
        echo "  SUCCESS: Node.js symlinks fixed"
      elif brew link --overwrite node 2>/dev/null; then
        echo "  SUCCESS: Node.js symlinks fixed (overwrite method)"
      else
        echo "  WARNING: Failed to fix Node.js symlinks automatically"
        echo "  MANUAL FIX: Run 'brew unlink node && brew link node' to resolve conflicts"
      fi
    else
      echo "  SUCCESS: Node.js symlinks are clean"
    fi
  fi
  
  # Check if we're in a good state to run updates
  if [[ -n "$ZSH_VERSION" ]]; then
    echo "[System] Using Zsh version: $ZSH_VERSION"
  else
    echo "[System] WARNING: Zsh version not detected"
  fi

  if command -v brew >/dev/null 2>&1; then
    echo "[Homebrew] update/upgrade/cleanup..."
    local brew_errors=()
    
    if brew update 2>/dev/null; then
      echo "  Homebrew updated successfully"
    else
      brew_errors+=("update")
      echo "  WARNING: Homebrew update failed"
    fi
    
    if brew upgrade 2>/dev/null; then
      echo "  Homebrew packages upgraded successfully"
    else
      brew_errors+=("upgrade")
      echo "  WARNING: Some Homebrew packages failed to upgrade"
    fi
    
    brew cleanup 2>/dev/null || brew_errors+=("cleanup")
    brew cleanup -s 2>/dev/null || true
    
    if brew doctor 2>/dev/null; then
      echo "  Homebrew doctor check passed"
    else
      brew_errors+=("doctor")
      echo "  WARNING: brew doctor reported issues"
    fi
    
    # Report summary of Homebrew issues
    if [[ ${#brew_errors[@]} -gt 0 ]]; then
      echo "  Homebrew issues: ${brew_errors[*]}"
      echo "  Consider running: brew doctor for detailed diagnostics"
    fi
  else
    echo "[Homebrew] Not installed, skipping..."
  fi

  if command -v port >/dev/null 2>&1; then
    echo "[MacPorts] sudo required; you may be prompted..."
    local port_errors=()
    
    if sudo port -v selfupdate 2>/dev/null; then
      echo "  MacPorts updated successfully"
    else
      port_errors+=("selfupdate")
      echo "  WARNING: MacPorts selfupdate failed"
    fi
    
    if sudo port -N upgrade outdated 2>/dev/null; then
      echo "  MacPorts packages upgraded successfully"
    else
      port_errors+=("upgrade")
      echo "  WARNING: Some MacPorts packages failed to upgrade"
    fi
    
    sudo port reclaim -f --disable-reminders 2>/dev/null || port_errors+=("reclaim")
    (cd /tmp && sudo port clean --all installed) 2>/dev/null || port_errors+=("clean")
    
    # Report summary of MacPorts issues
    if [[ ${#port_errors[@]} -gt 0 ]]; then
      echo "  MacPorts issues: ${port_errors[*]}"
    fi
  fi

  local pybin=""
  local pyenv_target=""
  local current_python=""
  
  # Get current Python version before upgrade
  if command -v pyenv >/dev/null 2>&1; then
    current_python="$(pyenv version-name 2>/dev/null || true)"
  else
    current_python="$(python3 -V 2>/dev/null | cut -d' ' -f2 || python -V 2>/dev/null | cut -d' ' -f2 || true)"
  fi
  
  if command -v pyenv >/dev/null 2>&1; then
    echo "[pyenv] Activating latest Python..."
    local latest_available="$(_pyenv_latest_available)"
    if [[ -n "$latest_available" && "$current_python" != "$latest_available" ]]; then
      echo "[pyenv] Current: $current_python, Latest available: $latest_available"
      
      # Check compatibility before upgrade
      if ! _check_python_upgrade_compatibility "$current_python" "$latest_available"; then
        echo ""
        echo "WARNING: Some packages may be broken by Python upgrade!"
        echo "   This may affect global pip packages and pipx packages."
        echo ""
        read -q "? Do you want to continue with Python upgrade? (y/N): " && echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          echo "[pyenv] Continuing with Python upgrade..."
          if pyenv_target="$(_pyenv_activate_latest 2>/dev/null)"; then
            echo "[pyenv] Using $pyenv_target"
            pybin="$(pyenv which python 2>/dev/null || true)"
          else
            echo "[pyenv] Could not activate latest Python (continuing)."
            pybin="$(pyenv which python 2>/dev/null || true)"
          fi
        else
          echo "[pyenv] Python upgrade cancelled by user"
          pyenv_target="$current_python"
          pybin="$(pyenv which python 2>/dev/null || true)"
        fi
      else
        echo "[pyenv] Activating latest Python..."
        if pyenv_target="$(_pyenv_activate_latest 2>/dev/null)"; then
          echo "[pyenv] Using $pyenv_target"
          pybin="$(pyenv which python 2>/dev/null || true)"
        else
          echo "[pyenv] Could not activate latest Python (continuing)."
          pybin="$(pyenv which python 2>/dev/null || true)"
        fi
      fi
    else
      echo "[pyenv] Already using latest Python: $current_python"
      pyenv_target="$current_python"
      pybin="$(pyenv which python 2>/dev/null || true)"
    fi
  fi
  [[ -z "$pybin" ]] && pybin="$(command -v python3 || command -v python || true)"
  if [[ -n "$pybin" ]]; then
    echo "[Python] Upgrading pip/setuptools/wheel and global packages..."
    local python_errors=()
    
    if "$pybin" -m ensurepip --upgrade 2>/dev/null; then
      echo "  ensurepip upgraded successfully"
    else
      python_errors+=("ensurepip")
      echo "  WARNING: ensurepip upgrade failed"
    fi
    
    if "$pybin" -m pip install --upgrade pip setuptools wheel 2>/dev/null; then
      echo "  pip/setuptools/wheel upgraded successfully"
    else
      python_errors+=("pip_upgrade")
      echo "  WARNING: pip/setuptools/wheel upgrade failed"
    fi
    
    if command -v pipx >/dev/null 2>&1; then
      echo "[pipx] Upgrading all packages..."
      
      # Set the default Python for pipx if needed
      if [[ -n "$pybin" ]]; then
        export PIPX_DEFAULT_PYTHON="$pybin"
        echo "  Using Python: $pybin"
      fi
      
      # Try to upgrade all pipx packages
      local pipx_output
      pipx_output="$(pipx upgrade-all --verbose 2>&1)"
      local pipx_exit_code=$?
      
      if [[ $pipx_exit_code -eq 0 ]]; then
        echo "  pipx packages upgraded successfully"
      else
        python_errors+=("pipx")
        echo "  WARNING: pipx upgrade failed (exit code: $pipx_exit_code)"
        
        # Try to identify specific issues
        if [[ "$pipx_output" == *"No packages to upgrade"* ]]; then
          echo "  INFO: No pipx packages need upgrading"
        elif [[ "$pipx_output" == *"error"* ]] || [[ "$pipx_output" == *"Error"* ]]; then
          echo "  ERROR: pipx encountered errors during upgrade"
          echo "  Consider running: pipx upgrade-all --force"
        else
          echo "  INFO: pipx upgrade completed with warnings"
        fi
        
        # Try force upgrade as fallback
        echo "  ATTEMPTING: Force upgrade as fallback..."
        if pipx upgrade-all --force 2>/dev/null; then
          echo "  SUCCESS: pipx packages upgraded with force"
          # Remove pipx from errors if force upgrade succeeded
          python_errors=(${python_errors[@]/pipx})
        else
          echo "  WARNING: Force upgrade also failed"
        fi
      fi
    fi
    
    # Upgrade global packages with better error handling
    local outdated_packages
    outdated_packages="$("$pybin" -m pip list --outdated --format=freeze 2>/dev/null | cut -d= -f1 || true)"
    if [[ -n "$outdated_packages" ]]; then
      echo "  Upgrading global packages..."
      local failed_packages=()
      while IFS= read -r package; do
        [[ -z "$package" ]] && continue
        if ! "$pybin" -m pip install -U "$package" 2>/dev/null; then
          failed_packages+=("$package")
        fi
      done <<< "$outdated_packages"
      
      if [[ ${#failed_packages[@]} -gt 0 ]]; then
        python_errors+=("global_packages")
        echo "  WARNING: Failed to upgrade: ${failed_packages[*]}"
      else
        echo "  Global packages upgraded successfully"
      fi
    fi
    
    # Report summary of Python issues
    if [[ ${#python_errors[@]} -gt 0 ]]; then
      echo "  Python issues: ${python_errors[*]}"
    fi
    
    # Refresh command hash table after Python package updates
    hash -r 2>/dev/null || true
  fi
  if command -v pyenv >/dev/null 2>&1 && [[ -n "$pyenv_target" ]]; then
    echo "[pyenv] Removing old versions (keeping $pyenv_target)..."
    pyenv versions --bare | while read -r ver; do
      [[ "$ver" == "$pyenv_target" || "$ver" == "system" || -z "$ver" ]] && continue
      echo "  removing $ver"
      pyenv uninstall -f "$ver" || true
    done
    pyenv rehash 2>/dev/null || true
  fi

  echo "[Node] Ensuring latest LTS..."
  if command -v nvm >/dev/null 2>&1; then
    local prev_nvm="$(nvm current 2>/dev/null || true)"
    nvm install --lts --latest-npm || true
    nvm alias default 'lts/*' || true
    nvm use default || true
    if [[ -n "$prev_nvm" && "$prev_nvm" != "system" ]]; then
      nvm reinstall-packages "$prev_nvm" || true
    fi
    local active_nvm="$(nvm current 2>/dev/null || true)"
    if [[ -n "$active_nvm" && "$active_nvm" != "system" ]]; then
      echo "[nvm] Removing older Node versions (keeping $active_nvm)..."
      nvm list --no-colors 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | while read -r ver; do
        [[ "$ver" == "$active_nvm" ]] && continue
        echo "  removing $ver"
        nvm uninstall "$ver" || true
      done
    fi
  elif command -v brew >/dev/null 2>&1 && brew list node >/dev/null 2>&1; then
    brew upgrade node || true
  fi
  if command -v npm >/dev/null 2>&1; then
    npm install -g npm || true
    npm update -g || true
    
    # Refresh command hash table after Node.js package updates
    hash -r 2>/dev/null || true
  fi

  local chruby_target=""
  local previous_ruby=""
  
  # Get current Ruby version before any changes
  if command -v ruby >/dev/null 2>&1; then
    previous_ruby="$(ruby -v | cut -d' ' -f2)"
  fi
  
  if command -v gem >/dev/null 2>&1; then
    echo "[RubyGems] Updating and cleaning gems..."
    gem update --silent || true
    gem cleanup || true
  fi
  if command -v chruby >/dev/null 2>&1; then
    echo "[chruby] Ensuring latest Ruby is active..."
    if chruby_target="$(_chruby_install_latest 2>/dev/null)"; then
      echo "[chruby] Installed and activated: $chruby_target"
    else
      chruby_target="$(_chruby_latest_installed 2>/dev/null || true)"
      if [[ -n "$chruby_target" ]]; then
        echo "[chruby] Activating existing: $chruby_target"
        chruby "$chruby_target" >/dev/null 2>&1 || echo "[chruby] Failed to activate $chruby_target"
      else
        echo "[chruby] No Ruby versions found, installing latest..."
        if command -v ruby-install >/dev/null 2>&1; then
          local latest_ruby="$(ruby-install --list ruby 2>/dev/null | awk '/^ruby [0-9]+\.[0-9]+\.[0-9]+$/ {print $2}' | sort -V | tail -n1)"
          if [[ -n "$latest_ruby" ]]; then
            echo "[chruby] Installing ruby-$latest_ruby..."
            ruby-install ruby "$latest_ruby" && chruby_target="ruby-$latest_ruby"
            chruby "$chruby_target" >/dev/null 2>&1 || echo "[chruby] Failed to activate $chruby_target"
          fi
        else
          echo "[chruby] ruby-install not found, cannot install Ruby"
        fi
      fi
    fi
    _setup_gem_path
    
    # Auto-fix Ruby gems as security measure to prevent compatibility issues
    _fix_all_ruby_gems
  fi
  if command -v chruby >/dev/null 2>&1 && [[ -n "$chruby_target" ]]; then
    local rubies_root="$HOME/.rubies"
    local keep_path="$rubies_root/$chruby_target"
    if [[ -d "$rubies_root" ]]; then
      echo "[chruby] Removing old rubies (keeping $chruby_target)..."
      for dir in "$rubies_root"/ruby-*; do
        [[ -d "$dir" ]] || continue
        [[ "$dir" == "$keep_path" ]] && continue
        echo "  removing ${dir##*/}"
        rm -rf "$dir" || true
      done
    fi
  fi

  if command -v rustup >/dev/null 2>&1; then
    echo "[Rust] Updating toolchains..."
    rustup update || true
    rustup default stable || true
  fi

  hash -r 2>/dev/null || true
  echo "==> Update finished $(date)"
}

# ================================ VERIFY ===================================
unalias verify 2>/dev/null
verify() {
  echo "==> Verify $(date)"
  local ok warn miss
  ok()   { printf "%-15s OK (%s)\n" "$1" "$2"; }
  warn() { printf "%-15s WARN (%s)\n" "$1" "$2"; }
  miss() { printf "%-15s Not installed\n" "$1"; }

  if command -v ruby >/dev/null 2>&1; then
    ok "Ruby" "$(ruby -v)"
    command -v gem >/dev/null 2>&1 && ok "Gem" "$(gem -v)"
    if command -v chruby >/dev/null 2>&1; then
      local chruby_version="$(chruby --version 2>/dev/null | head -n1)"
      if [[ -n "$chruby_version" ]]; then
        ok "chruby" "$chruby_version"
      else
        ok "chruby" "installed"
      fi
    fi
  else
    miss "Ruby"
  fi

  local pybin="$(command -v python3 || command -v python || true)"
  if [[ -n "$pybin" ]]; then
    ok "Python" "$("$pybin" -V 2>/dev/null)"
    command -v pip >/dev/null 2>&1 && ok "pip" "$(pip -V | head -n1)" || warn "pip" "not in PATH"
    if command -v pyenv >/dev/null 2>&1; then
      local active_py="$(pyenv version-name 2>/dev/null || true)"
      local latest_py="$(_pyenv_latest_installed)"
      [[ -n "$latest_py" && "$active_py" == "$latest_py" ]] && ok "pyenv" "active $active_py" || warn "pyenv" "active ${active_py:-unknown}; latest ${latest_py:-unknown}"
    fi
  else
    miss "Python"
  fi

  if command -v node >/dev/null 2>&1; then
    ok "Node" "$(node -v)"
    command -v npm >/dev/null 2>&1 && ok "npm" "$(npm -v)" || warn "npm" "not in PATH"
    if command -v nvm >/dev/null 2>&1; then
      local current="$(nvm current 2>/dev/null || true)"
      local defv="$(nvm version default 2>/dev/null || true)"
      [[ -n "$defv" && "$current" == "$defv" ]] && ok "nvm" "current $current" || warn "nvm" "current ${current:-N/A}; default ${defv:-N/A}"
    fi
  else
    miss "Node"
  fi

  command -v rustc >/dev/null 2>&1 && ok "Rust" "$(rustc -V)" || miss "Rust"
  if command -v rustup >/dev/null 2>&1; then
    local active="$(rustup show active-toolchain 2>/dev/null | head -n1)"
    [[ "$active" == stable* ]] && ok "rustup" "$active" || warn "rustup" "$active"
  fi

  command -v go   >/dev/null 2>&1 && ok "Go"   "$(go version)" || miss "Go"
  command -v java >/dev/null 2>&1 && ok "Java" "$(java -version 2>&1 | head -n1)" || miss "Java"
  command -v clang >/dev/null 2>&1 && ok "Clang" "$(clang --version | head -n1)" || miss "Clang"
  command -v gcc  >/dev/null 2>&1 && ok "GCC"  "$(gcc --version | head -n1)" || warn "GCC" "not found"
  
  if command -v mysql >/dev/null 2>&1; then
    ok "MySQL" "$(mysql --version)"
  elif [[ -x /usr/local/mysql/bin/mysql ]]; then
    ok "MySQL" "$(/usr/local/mysql/bin/mysql --version)"
  else
    warn "MySQL" "not found"
  fi

  if command -v docker >/dev/null 2>&1; then
    ok "Docker" "$(docker -v)"
    if command -v docker-compose >/dev/null 2>&1; then
      ok "Compose" "$(docker-compose -v)"
    elif docker compose version >/dev/null 2>&1; then
      ok "Compose" "$(docker compose version | head -n1)"
    else
      warn "Compose" "not found"
    fi
  else
    miss "Docker"
  fi

  command -v brew >/dev/null 2>&1 && ok "Homebrew" "$(brew --version | head -n1)" || miss "Homebrew"
  command -v port  >/dev/null 2>&1 && ok "MacPorts" "$(port version)" || warn "MacPorts" "not installed"
  
  if command -v mongod >/dev/null 2>&1; then
    local mongodb_version="$(mongod --version 2>/dev/null | head -n1 | sed 's/db version //' || echo "unknown")"
    local mongodb_status="stopped"
    if pgrep -x mongod >/dev/null 2>&1; then
      mongodb_status="running"
    fi
    ok "MongoDB" "$mongodb_version ($mongodb_status)"
  else
    miss "MongoDB"
  fi
  
  if command -v psql >/dev/null 2>&1; then
    local postgres_version="$(psql --version 2>/dev/null | sed 's/psql (PostgreSQL) //' | sed 's/ .*//' || echo "unknown")"
    local postgres_status="stopped"
    if pgrep -x postgres >/dev/null 2>&1; then
      postgres_status="running"
    fi
    ok "PostgreSQL" "$postgres_version ($postgres_status)"
  else
    miss "PostgreSQL"
  fi
  
  echo "==> Verify done"
}
# ================================ VERSIONS ===================================
unalias versions 2>/dev/null
versions() {
  echo "================== TOOL VERSIONS =================="
  command -v ruby >/dev/null 2>&1 && echo "Ruby ........... $(ruby -v)" || echo "Ruby ........... not installed"
  command -v gem  >/dev/null 2>&1 && echo "Gem ............ $(gem -v)" || true
  if command -v chruby >/dev/null 2>&1; then
    local chruby_version="$(chruby --version 2>/dev/null | head -n1)"
    if [[ -n "$chruby_version" ]]; then
      echo "chruby ......... $chruby_version"
    else
      echo "chruby ......... installed"
    fi
  fi

  if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    echo "Python ......... $(python3 -V 2>/dev/null || python -V 2>/dev/null)"
    command -v pip  >/dev/null 2>&1 && echo "pip ............ $(pip -V | awk '{print $2}')" || true
    command -v pyenv >/dev/null 2>&1 && echo "pyenv .......... $(pyenv version-name 2>/dev/null)" || true
  else
    echo "Python ......... not installed"
  fi

  if command -v node >/dev/null 2>&1; then
    echo "Node.js ........ $(node -v)"
    command -v npm >/dev/null 2>&1 && echo "npm ............ $(npm -v)" || true
    command -v nvm >/dev/null 2>&1 && echo "nvm ............ $(nvm current 2>/dev/null)" || true
  else
    echo "Node.js ........ not installed"
  fi

  command -v rustc >/dev/null 2>&1 && echo "Rust ........... $(rustc -V)" || echo "Rust ........... not installed"
  command -v rustup >/dev/null 2>&1 && echo "rustup ......... $(rustup show active-toolchain 2>/dev/null | head -n1)" || true
  command -v go   >/dev/null 2>&1 && echo "Go ............. $(go version)" || echo "Go ............. not installed"
  command -v java >/dev/null 2>&1 && echo "Java ........... $(java -version 2>&1 | head -n1)" || echo "Java ........... not installed"
  command -v clang >/dev/null 2>&1 && echo "Clang .......... $(clang --version | head -n1)" || echo "Clang .......... not installed"
  command -v gcc  >/dev/null 2>&1 && echo "GCC ............ $(gcc --version | head -n1)" || echo "GCC ............ not installed"

  if command -v mysql >/dev/null 2>&1; then
    echo "MySQL .......... $(mysql --version)"
  elif [[ -x /usr/local/mysql/bin/mysql ]]; then
    echo "MySQL .......... $(/usr/local/mysql/bin/mysql --version)"
  else
    echo "MySQL .......... not installed"
  fi

  if command -v docker >/dev/null 2>&1; then
    echo "Docker ......... $(docker -v)"
    if command -v docker-compose >/dev/null 2>&1; then
      echo "Compose ........ $(docker-compose -v)"
    elif docker compose version >/dev/null 2>&1; then
      echo "Compose ........ $(docker compose version | head -n1)"
    fi
  else
    echo "Docker ......... not installed"
  fi

  command -v brew >/dev/null 2>&1 && echo "Homebrew ....... $(brew --version | head -n1)" || echo "Homebrew ....... not installed"
  command -v port >/dev/null 2>&1 && echo "MacPorts ....... $(port version)" || echo "MacPorts ....... not installed"
  
  if command -v mongod >/dev/null 2>&1; then
    local mongodb_version="$(mongod --version 2>/dev/null | head -n1 | sed 's/db version //' || echo "unknown")"
    local mongodb_status="stopped"
    if pgrep -x mongod >/dev/null 2>&1; then
      mongodb_status="running"
    fi
    echo "MongoDB ........ $mongodb_version ($mongodb_status)"
  else
    echo "MongoDB ........ not installed"
  fi
  
  if command -v psql >/dev/null 2>&1; then
    local postgres_version="$(psql --version 2>/dev/null | sed 's/psql (PostgreSQL) //' | sed 's/ .*//' || echo "unknown")"
    local postgres_status="stopped"
    if pgrep -x postgres >/dev/null 2>&1; then
      postgres_status="running"
    fi
    echo "PostgreSQL ..... $postgres_version ($postgres_status)"
  else
    echo "PostgreSQL ..... not installed"
  fi
  
  echo "==================================================="
}

# ================================ FZF ======================================
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh