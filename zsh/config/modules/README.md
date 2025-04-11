# ZSH Modules System

This directory contains the modular components of the ZSH configuration system. The structure is designed for maintainability, clarity, and scalability.

## Directory Structure

```markdown
modules/
├── functions/  - User-defined shell functions
│   ├── 00-core.zsh      - Core utility functions needed by others
│   ├── 10-navigation.zsh - Directory/file navigation functions
│   ├── 20-git.zsh       - Git-related functions
│   ├── 30-process.zsh   - Process management functions
│   ├── 40-python.zsh    - Python environment management
│   ├── 50-webserver.zsh - Web server functions
│   └── 60-system.zsh    - System maintenance functions
│
└── local/      - Local overrides (optional, user-specific)
    ├── README.md         - Documentation for local configurations
    └── example.zsh.template - Template for local configurations
```

## Numbering Convention

Files are named with a numeric prefix (`XX-name.zsh`) to define their loading order:

- **00-09**: Setup and initialization
- **10-69**: Core functionality, grouped by domain
- **70-89**: Reserved for future extensions
- **90-99**: Finalization and cleanup

This convention ensures that modules are loaded in the correct order regardless of their alphabetical order, making dependencies easier to manage.

## Module Loading Order

Modules are loaded in a special order to ensure dependencies are satisfied:

1. **Setup files first**: Files named `00-*.zsh` are loaded first in each directory
2. **Regular modules**: All other modules are loaded in numeric order
3. **Cleanup files last**: Files named `99-*.zsh` are loaded last in each directory

This allows for initialization code to run before module loading, and cleanup code to run after.

## Adding New Modules

To add a new module:

1. Determine its functionality and appropriate location in the functions directory
2. Choose an appropriate prefix number based on its dependencies
3. Create a new `XX-name.zsh` file in the appropriate directory

For example:

- To add a new networking utility: `35-network.zsh` in the functions directory
- To add Docker related functions: `25-docker.zsh` in the functions directory

The module will be automatically loaded in the right order - no need to modify any loader files!

## Local Overrides

If you need user-specific configurations that shouldn't be committed to the repository:

1. Create a `.zsh` file in the `local/` directory
2. These will be loaded last and can override any previously loaded settings

See [local/README.md](local/README.md) for more details on local configurations.

## Debugging

To enable debug output during module loading:

1. Edit `zsh/config/modules.zsh`
2. Uncomment the line: `# _MODULES_DEBUG=1`

This will show which modules are being loaded, making it easier to troubleshoot issues.
