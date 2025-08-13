# ===============================
# SYSTEM MAINTENANCE FUNCTIONS
# ===============================

# Function: update_all
# Updates Homebrew packages, App Store apps, macOS system updates,
# and checks for third-party app updates
update_all() {
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
    if mas upgrade; then
      echo "✓ App Store apps updated successfully."
    else
      # Don't mark as failure if no updates are available
      if [[ $? -ne 0 && $? -ne 20 ]]; then
        success=false
        errors+=("App Store update failed")
        echo -e "\033[1;31m✗ Error updating App Store apps.\033[0m"
      fi
    fi
  else
    echo -e "\033[1;33m⚠ The 'mas' CLI tool is not installed. Skipping App Store updates.\033[0m"
  fi

  # 3. Check and install macOS system updates
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