# ===============================
# SYSTEM MAINTENANCE FUNCTIONS
# ===============================

# Function: update_nodejs
# Updates Node.js to latest LTS via nvm and enables corepack
update_nodejs() {
  # Check if nvm function exists (nvm is a shell function, not a binary)
  if ! type nvm &>/dev/null; then
    echo -e "\033[1;33m⚠ nvm not found. Skipping Node.js update.\033[0m"
    return 1
  fi

  echo -e "\033[1;32m◆ Updating Node.js via nvm...\033[0m"

  local current_version=$(nvm current)
  if nvm install --lts --latest-npm; then
    echo "✓ Node.js LTS installed successfully."

    # Enable corepack for pnpm/yarn (only if not already enabled)
    if ! zdotfiles_has_command corepack && zdotfiles_has_command node; then
      echo -e "\033[1;32m◆ Enabling corepack...\033[0m"
      if corepack enable; then
        echo "✓ Corepack enabled successfully."
      else
        echo -e "\033[1;31m✗ Failed to enable corepack.\033[0m"
        return 1
      fi
    fi

    # Set as default and migrate packages
    local new_version=$(nvm current)
    if [[ "$current_version" != "$new_version" ]]; then
      nvm alias default "$new_version"
      echo "✓ Set Node.js $new_version as default."
    fi
    return 0
  else
    echo -e "\033[1;31m✗ Error updating Node.js.\033[0m"
    return 1
  fi
}

# Function: update_pnpm
# Updates pnpm to latest version via corepack
update_pnpm() {
  if ! zdotfiles_has_command corepack; then
    echo -e "\033[1;33m⚠ corepack not found. Attempting to enable...\033[0m"
    if zdotfiles_has_command node && corepack enable 2>/dev/null; then
      echo "✓ corepack enabled successfully."
    else
      echo -e "\033[1;31m✗ Failed to enable corepack. Skipping pnpm update.\033[0m"
      return 1
    fi
  fi

  # Ensure pnpm shim exists (required after fresh Node install)
  corepack enable pnpm 2>/dev/null

  echo -e "\033[1;32m◆ Updating pnpm via corepack...\033[0m"
  if corepack prepare pnpm@latest --activate; then
    echo "✓ pnpm updated successfully."
    return 0
  else
    echo -e "\033[1;31m✗ Error updating pnpm.\033[0m"
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
# Updates: Homebrew, App Store, Node.js, pnpm, Sheldon plugins, and macOS
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

  # 3. Update Node.js via nvm
  echo ""
  if ! update_nodejs; then
    success=false
    errors+=("Node.js update failed")
  fi

  # 4. Update pnpm
  echo ""
  if ! update_pnpm; then
    success=false
    errors+=("pnpm update failed")
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