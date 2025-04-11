# ===============================
# PYTHON ENVIRONMENT FUNCTIONS
# ===============================

venv() {
  # Helper: convert a path to an absolute path.
  absolute_path() {
    case "$1" in
      /*) echo "$1" ;;
      *)  echo "$(pwd)/$1" ;;
    esac
  }

  # Defaults
  local venv_dir=".venv"
  local python_bin="python3"

  # Use Homebrew's Python if available.
  if command -v brew &>/dev/null; then
    local brew_prefix
    brew_prefix="$(brew --prefix python 2>/dev/null)"
    if [ -n "$brew_prefix" ] && [ -x "$brew_prefix/bin/python3" ]; then
      python_bin="$brew_prefix/bin/python3"
    fi
  fi

  local delete_flag=false

  # Process parameters: support -n/--name, -p/--python, and the subcommand "rm"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      rm)
        delete_flag=true
        shift
        ;;
      -n|--name)
        if [[ -n "$2" ]]; then
          venv_dir="$2"
          shift 2
        else
          echo "Error: Missing argument for $1" >&2
          return 1
        fi
        ;;
      -p|--python)
        if [[ -n "$2" ]]; then
          python_bin="$2"
          shift 2
        else
          echo "Error: Missing argument for $1" >&2
          return 1
        fi
        ;;
      *)
        echo "Usage: venv [rm] [-n|--name <venv_folder>] [-p|--python <python_bin>]" >&2
        return 1
        ;;
    esac
  done

  # Handle deletion if requested.
  if $delete_flag; then
    if [ -d "$venv_dir" ]; then
      echo "Deleting virtual environment '$venv_dir'..."
      rm -rf "$venv_dir"
      echo "Deleted."
    else
      echo "Virtual environment '$venv_dir' not found."
    fi

    # Compute absolute path for proper comparison.
    local abs_venv_dir
    abs_venv_dir="$(absolute_path "$venv_dir")"

    # If the deleted venv is currently activated, deactivate it.
    if [ "$VIRTUAL_ENV" = "$abs_venv_dir" ]; then
      if command -v deactivate >/dev/null 2>&1; then
        deactivate
      else
        unset VIRTUAL_ENV
      fi
      echo "Deactivated current virtual environment."
    fi
    return 0
  fi

  # Show the Python version to be used.
  echo "Using Python: $("$python_bin" --version 2>&1)"

  # Create the venv if it doesn't exist.
  if [ ! -d "$venv_dir" ]; then
    echo "Creating virtual environment '$venv_dir'..."
    if ! "$python_bin" -m venv "$venv_dir"; then
      echo "Error: Failed to create virtual environment '$venv_dir'" >&2
      return 1
    fi
  else
    echo "Virtual environment '$venv_dir' exists."
  fi

  # Activate the venv if not already active or if the active one is missing.
  if [ -z "$VIRTUAL_ENV" ] || [ ! -d "$VIRTUAL_ENV" ]; then
    if [ -f "$venv_dir/bin/activate" ]; then
      source "$venv_dir/bin/activate"
      echo "Activated virtual environment '$venv_dir'."
      echo "Upgrading pip install..."
      pip install --upgrade pip
    else
      echo "Error: Activate script not found in '$venv_dir/bin/activate'" >&2
      return 1
    fi
  else
    echo "Virtual environment already activated ($VIRTUAL_ENV)."
  fi
} 