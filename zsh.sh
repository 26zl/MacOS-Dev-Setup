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
  if [[ -d /opt/homebrew ]]; then
    echo /opt/homebrew
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

alias mysqlstart="sudo /usr/local/mysql/support-files/mysql.server start"
alias mysqlstop="sudo /usr/local/mysql/support-files/mysql.server stop"
alias mysqlstatus="sudo /usr/local/mysql/support-files/mysql.server status"
alias mysqlrestart="sudo /usr/local/mysql/support-files/mysql.server restart"
alias mysqlconnect="mysql -u root -p"

if [[ -d "/opt/homebrew/opt/openjdk/bin" ]]; then
  export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
fi

# ================================ UPDATE ===================================

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

unalias update 2>/dev/null
update() {
  echo "==> Update started $(date)"

  if command -v brew >/dev/null 2>&1; then
    echo "[Homebrew] update/upgrade/cleanup..."
    brew update
    brew upgrade
    brew cleanup
    brew cleanup -s
    brew doctor || echo "[Homebrew] brew doctor reported warnings (see above)."
  fi

  if command -v port >/dev/null 2>&1; then
    echo "[MacPorts] sudo required; you may be prompted..."
    sudo port -v selfupdate
    sudo port -N upgrade outdated
    sudo port reclaim -f --disable-reminders
    (cd /tmp && sudo port clean --all installed) 2>/dev/null || true
  fi

  local pybin=""
  local pyenv_target=""
  if command -v pyenv >/dev/null 2>&1; then
    echo "[pyenv] Activating latest Python..."
    if pyenv_target="$(_pyenv_activate_latest 2>/dev/null)"; then
      echo "[pyenv] Using $pyenv_target"
      pybin="$(pyenv which python 2>/dev/null || true)"
    else
      echo "[pyenv] Could not activate latest Python (continuing)."
      pybin="$(pyenv which python 2>/dev/null || true)"
    fi
  fi
  [[ -z "$pybin" ]] && pybin="$(command -v python3 || command -v python || true)"
  if [[ -n "$pybin" ]]; then
    echo "[Python] Upgrading pip/setuptools/wheel and global packages..."
    "$pybin" -m ensurepip --upgrade || true
    "$pybin" -m pip install --upgrade pip setuptools wheel || true
    if command -v pipx >/dev/null 2>&1; then
      export PIPX_DEFAULT_PYTHON="$pybin"
      
      local need_recreate=false
      
      local pipx_envs_json="$(pipx list --json 2>/dev/null)"
      if [[ -n "$pipx_envs_json" ]]; then
        local current_python_version=""
        if command -v "$pybin" >/dev/null 2>&1; then
          current_python_version="$("$pybin" -c "import sys;print('.'.join(map(str,sys.version_info[:3])))" 2>/dev/null || echo "")"
        fi
        
        local venv_count=0
        local mismatch_count=0
        
        while IFS= read -r line; do
          [[ -z "$line" ]] && continue
          local env_name="$(echo "$line" | jq -r '.key // empty' 2>/dev/null)"
          local env_version="$(echo "$line" | jq -r '.value.metadata.python_version // empty' 2>/dev/null)"
          
          if [[ -n "$env_name" ]]; then
            ((venv_count++))
            
            if [[ -n "$current_python_version" && -n "$env_version" ]]; then
              if [[ "$env_version" != *"$current_python_version"* ]]; then
                ((mismatch_count++))
              fi
            else
              ((mismatch_count++))
            fi
          fi
        done < <(echo "$pipx_envs_json" | jq -c '.venvs | to_entries[]' 2>/dev/null)
        
        if [[ $venv_count -gt 0 && $mismatch_count -gt 0 ]]; then
          need_recreate=true
        fi
      else
        need_recreate=false
      fi
      
      if [[ "$need_recreate" == "true" ]]; then
        echo "[pipx] Recreating environments with $PIPX_DEFAULT_PYTHON..."
        local pipx_packages=()
        while IFS= read -r pkg; do
          [[ -n "$pkg" ]] && pipx_packages+=("$pkg")
        done < <(pipx list --short 2>/dev/null | awk '{print $1}')
        for pkg in "${pipx_packages[@]}"; do
          pipx uninstall "$pkg" >/dev/null 2>&1 || true
          pipx install --python "$pybin" "$pkg" || echo "[pipx] Failed to install $pkg (see output above)."
        done
      else
        echo "[pipx] Environments already use $PIPX_DEFAULT_PYTHON (skipping)."
      fi
    fi
    "$pybin" -m pip list --outdated --format=freeze 2>/dev/null \
      | cut -d= -f1 | xargs -n1 "$pybin" -m pip install -U || true
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
      nvm list --no-colors 2>/dev/null | sed -n 's/^[^v]*\(v[0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p' | while read -r ver; do
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
  fi

  local chruby_target=""
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
      local active="$(chruby | awk '/\*/{print $2; exit}')"
      local latest="$(_chruby_latest_installed)"
      [[ -n "$latest" && "$active" == "$latest" ]] && ok "chruby" "active $active" || warn "chruby" "active ${active:-system}; latest ${latest:-unknown}"
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
  command -v mysql>/dev/null 2>&1 && ok "MySQL" "$(mysql --version)" || warn "MySQL" "not found"

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
