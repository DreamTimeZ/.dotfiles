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
  if zdotfiles_has_command brew; then
    local brew_prefix
    brew_prefix="$(brew --prefix python 2>/dev/null)"
    if [[ -n "$brew_prefix" && -x "$brew_prefix/bin/python3" ]]; then
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
    if [[ -d "$venv_dir" ]]; then
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
    if [[ "$VIRTUAL_ENV" = "$abs_venv_dir" ]]; then
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
  if [[ ! -d "$venv_dir" ]]; then
    echo "Creating virtual environment '$venv_dir'..."
    if ! "$python_bin" -m venv "$venv_dir"; then
      echo "Error: Failed to create virtual environment '$venv_dir'" >&2
      return 1
    fi
  else
    echo "Virtual environment '$venv_dir' exists."
  fi

  # Activate the venv if not already active or if the active one is missing.
  if [[ -z "$VIRTUAL_ENV" || ! -d "$VIRTUAL_ENV" ]]; then
    if [[ -f "$venv_dir/bin/activate" ]]; then
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

pcheck() {
  local python_path=""
  local jupyter=false
  local fix=false
  local missing_tools=()
  local tools_common=(black isort mypy ruff bandit pytest)
  local tools_jupyter=(nbqa)
  local results=()

  # Parse arguments
  for arg in "$@"; do
    case $arg in
      --python=*)
        python_path="${arg#*=}"
        ;;
      --jupyter)
        jupyter=true
        ;;
      --fix)
        fix=true
        ;;
    esac
  done

  if [[ -n "$python_path" ]]; then
    echo "⚙️  Using Python: $python_path"
    poetry config virtualenvs.in-project true
    poetry env use "$python_path" || {
      echo "❌ Failed to use interpreter: $python_path"
      return 1
    }
  fi

  echo "📦 Installing project dependencies..."
  poetry install --no-root || {
    echo "❌ poetry install --no-root failed"
    return 1
  }

  echo "🔍 Checking for required tools..."
  for tool in "${tools_common[@]}"; do
    poetry show "$tool" &>/dev/null || missing_tools+=("$tool")
  done
  if $jupyter; then
    for tool in "${tools_jupyter[@]}"; do
      poetry show "$tool" &>/dev/null || missing_tools+=("$tool")
    done
  fi

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    echo "🚨 Missing tools: ${missing_tools[*]}"
    read "REPLY?Install them as dev dependencies? [y/N]: "
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
      poetry add --dev "${missing_tools[@]}" || {
        echo "❌ Failed to install missing tools"
        return 1
      }
    else
      echo "⚠️ Skipping install. Some checks may fail."
    fi
  fi

  # Determine scan path
  local scan_path="."
  [[ -d src ]] && scan_path="src"

  run_check() {
    local name="$1"
    local cmd="$2"
    echo "🔧 $name"
    if eval "$cmd"; then
      results+=("$name: ✅ Passed")
    else
      results+=("$name: ❌ Failed")
    fi
  }

  echo "🧪 Running code quality checks..."

  run_check "mypy" "poetry run mypy ."

  if $fix; then
    run_check "black (fix)" "poetry run black ."
    run_check "isort (fix)" "poetry run isort ."
    run_check "ruff (fix)" "poetry run ruff check --fix ."
  else
    run_check "black" "poetry run black --check ."
    run_check "isort" "poetry run isort --check ."
    run_check "ruff" "poetry run ruff check ."
  fi

  run_check "bandit" "poetry run bandit -r $scan_path"

  if [[ -d tests || -n $(find . -name 'test_*.py' -o -name '*_test.py' 2>/dev/null) ]]; then
    run_check "pytest" "poetry run pytest"
  else
    echo "⚠️ No test files found. Skipping pytest."
    results+=("pytest: ⚠️ Skipped (no tests)")
  fi

  if $jupyter; then
    echo "📓 Running notebook checks"
    if $fix; then
      run_check "nbqa black (fix)" "poetry run nbqa black . --nbqa-mutate"
      run_check "nbqa isort (fix)" "poetry run nbqa isort . --nbqa-mutate"
      run_check "nbqa ruff (fix)" "poetry run nbqa ruff . --nbqa-mutate --fix"
    else
      run_check "nbqa black" "poetry run nbqa black ."
      run_check "nbqa isort" "poetry run nbqa isort ."
      run_check "nbqa ruff" "poetry run nbqa ruff ."
    fi
    run_check "nbqa mypy" "poetry run nbqa mypy ."
  fi

  echo
  echo "📊 === SUMMARY ==="
  for result in "${results[@]}"; do
    if [[ $result == *"✅"* ]]; then
      echo -e "\033[1;32m$result\033[0m"
    elif [[ $result == *"⚠️"* ]]; then
      echo -e "\033[1;33m$result\033[0m"
    else
      echo -e "\033[1;31m$result\033[0m"
    fi
  done
  echo "🏁 All checks done."
}