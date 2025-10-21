# ===============================
# ASDF - Universal Version Manager
# ===============================

_init_asdf() {
  local asdf_script
  for asdf_script in \
    "/opt/homebrew/opt/asdf/libexec/asdf.sh" \
    "/usr/local/opt/asdf/libexec/asdf.sh" \
    "$HOME/.asdf/asdf.sh"
  do
    [[ -f $asdf_script ]] || continue
    export ASDF_DIR=${asdf_script%/asdf.sh}
    source "$asdf_script"
    return 0
  done
}

# Create wrappers for asdf + commonly managed tools
# NOTE: node/npm/npx/yarn managed by NVM, not ASDF
zdotfiles_lazy_load _init_asdf \
  asdf \
  python python3 pip pip3 \
  ruby gem bundle \
  java javac mvn gradle
