# ===============================
# SYSTEM MAINTENANCE FUNCTIONS
# ===============================

# Function: update_mise
# Updates mise-managed tools (Node, Python, pnpm, etc.)
update_mise() {
  if ! zdotfiles_has_command mise; then
    echo -e "\033[1;33m⚠ mise not found. Skipping tool updates.\033[0m"
    return 1
  fi

  echo -e "\033[1;32m◆ Updating mise and managed tools...\033[0m"
  mise self-update -y 2>/dev/null
  if mise upgrade; then
    echo "✓ mise tools updated successfully."
    return 0
  else
    echo -e "\033[1;31m✗ Error updating mise tools.\033[0m"
    return 1
  fi
}

# Function: update_sheldon
# Updates sheldon plugin lockfile
update_sheldon() {
  if ! zdotfiles_has_command sheldon; then
    echo -e "\033[1;33m⚠ sheldon not found. Skipping plugin update.\033[0m"
    return 1
  fi

  echo -e "\033[1;32m◆ Updating sheldon plugins...\033[0m"
  if sheldon lock --update; then
    echo "✓ Sheldon plugins updated successfully."
    return 0
  else
    echo -e "\033[1;31m✗ Error updating sheldon plugins.\033[0m"
    return 1
  fi
}

# Function: update
# Updates: Homebrew, App Store, mise tools, Rust, Sheldon plugins, and macOS
update() {
  echo -e "\033[1;34m╔═══════════════════════════════════════════════════════╗"
  echo -e "║          Starting update process on macOS...          ║"
  echo -e "╚═══════════════════════════════════════════════════════╝\033[0m"

  local success=true
  local errors=()

  # 1. Update Homebrew formulas and casks
  if zdotfiles_has_command brew; then
    echo -e "\n\033[1;32m◆ Updating Homebrew...\033[0m"
    if brew update && brew upgrade && brew cleanup; then
      echo "✓ Homebrew packages updated successfully."
    else
      success=false
      errors+=("Homebrew update failed")
      echo -e "\033[1;31m✗ Error updating Homebrew packages.\033[0m"
    fi
  else
    echo -e "\033[1;33m⚠ Homebrew not found. Skipping Homebrew updates.\033[0m"
  fi

  # 2. Update Mac App Store apps via 'mas'
  if zdotfiles_has_command mas; then
    echo -e "\n\033[1;32m◆ Upgrading Mac App Store apps...\033[0m"
    local outdated_apps
    outdated_apps=$(mas outdated 2>/dev/null)
    if [[ -z "$outdated_apps" ]]; then
      echo "✓ All App Store apps are up to date."
    else
      echo "$outdated_apps"
      # Try mas upgrade, fall back to App Store if it fails
      # (mas has a known bug: https://github.com/mas-cli/mas/issues/1029)
      if mas upgrade 2>&1 | grep -q "PKInstallErrorDomain"; then
        echo -e "\033[1;33m⚠ mas upgrade failed. Opening App Store for manual update.\033[0m"
        open "macappstore://showUpdatesPage"
      else
        echo "✓ App Store apps updated successfully."
      fi
    fi
  else
    echo -e "\033[1;33m⚠ The 'mas' CLI tool is not installed. Skipping App Store updates.\033[0m"
  fi

  # 3. Update mise-managed tools (Node, Python, pnpm, etc.)
  echo ""
  if ! update_mise; then
    success=false
    errors+=("mise tools update failed")
  fi

  # 4. Update Rust toolchain
  if zdotfiles_has_command rustup; then
    echo -e "\n\033[1;32m◆ Updating Rust toolchain...\033[0m"
    if rustup update; then
      echo "✓ Rust toolchain updated successfully."
    else
      success=false
      errors+=("Rust toolchain update failed")
      echo -e "\033[1;31m✗ Error updating Rust toolchain.\033[0m"
    fi
  fi

  # 5. Update sheldon plugins
  echo ""
  if ! update_sheldon; then
    success=false
    errors+=("Sheldon plugins update failed")
  fi

  # 6. Check and install macOS system updates
  echo -e "\n\033[1;32m◆ Checking for macOS system updates...\033[0m"
  if sudo softwareupdate --list-full-installers &>/dev/null; then
    if sudo softwareupdate -i -a --restart; then
      echo "✓ System updates installed successfully and will restart when ready."
    else
      success=false
      errors+=("System update failed")
      echo -e "\033[1;31m✗ Error installing system updates.\033[0m"
    fi
  else
    echo "✓ No system updates available."
  fi

  # Summary
  echo -e "\n\033[1;34m╔═══════════════════════════════════════════════════════╗"
  if $success; then
    echo -e "║          System update process completed!             ║"
    echo -e "║     System will restart if updates were installed     ║"
  else
    echo -e "║      Update process completed with some errors:       ║"
    for error in "${errors[@]}"; do
      printf "║ %-53s ║\n" "  • $error"
    done
  fi
  echo -e "╚═══════════════════════════════════════════════════════╝\033[0m"
} 