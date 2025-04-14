# Hotkeys Module

A modular Hammerspoon hotkeys system with a clean, modern architecture for better maintainability, extensibility, and performance.

## Module Structure

The hotkeys module uses a well-organized, modular structure:

```markdown
hammerspoon/modules/hotkeys/
├── config/                # Configuration-related files
│   ├── config.lua         # Central configuration for hotkeys and modals
│   └── init.lua           # Re-exports config for backward compatibility
├── core/                  # Core functionality 
│   ├── actions.lua        # Action handlers for hotkeys and modals
│   ├── logging.lua        # Logging functionality
│   ├── modals.lua         # Modal management functionality
│   └── validation.lua     # Parameter validation functions
├── modals/                # Modal implementations
│   └── system.lua         # System actions like shutdown, restart, etc.
├── ui/                    # User interface components
│   └── ui.lua             # UI-related helper functions
├── utils/                 # Utility functions
│   └── config_utils.lua   # Configuration loading utilities
├── local/                 # Local customizations (user-specific)
│   ├── apps_mappings.lua  # Custom application mappings
│   ├── finder_mappings.lua# Custom Finder mappings
│   └── websites_mappings.lua # Custom website mappings
└── init.lua               # Main entry point that initializes the module
```

## Architecture Overview

The hotkeys module is built using modern software design principles:

### 1. Separation of Concerns

Each component has a single, well-defined responsibility:

- **Configuration**: Manages settings and mappings
- **Core Components**: Handle specific functional areas
- **Modals**: Implement modal interaction patterns
- **UI**: Manages user interface elements

### 2. Dependency Management

Components have explicit dependencies for better maintainability:

- Each module imports only what it needs
- Dependencies are clearly stated at the top of each file
- Circular dependencies are avoided

### 3. Extensibility

The system is designed to be extended without modifying existing code:

- Add new modals by updating configuration
- Implement custom behavior through specialized modules
- Override default settings through local configurations

## Component Interactions

### Init Module Flow

1. Loads configuration
2. Sets up logging
3. Creates modal interfaces from configuration
4. Binds global hotkeys
5. Exports public API

### Modal Activation Flow

1. User presses hotkey combination
2. Modal interface is displayed with available options
3. User selects an option
4. Action is executed based on the selection
5. Modal is dismissed

### Action Execution Flow

1. Action handler is determined from configuration
2. Parameters are validated
3. Action is executed with appropriate parameters
4. Result is logged
5. UI is updated if necessary

## Usage in Your Configuration

To use the hotkeys module in your Hammerspoon configuration:

```lua
-- Load the hotkeys module
local hotkeys = require("modules.hotkeys")

-- Access specialized modules directly
local ui = require("modules.hotkeys.ui.ui")
local logging = require("modules.hotkeys.core.logging")
local actions = require("modules.hotkeys.core.actions")
local configUtils = require("modules.hotkeys.utils.config_utils")

-- Use functionality from the specialized modules
ui.showFormattedAlert("Hammerspoon Config Loaded")
logging.info("Initialization complete")
configUtils.loadMappings(defaultMappings, localPath, "customModal")
```

## Extending the System

### Adding a New Modal

To add a new modal, add an entry to `config/config.lua`:

```lua
config.modals.newmodal = {
    title = "My New Modal:",  -- Title to display in the modal
    handler = {
        field = "myfield",    -- Field name required in mappings
        action = "myHandler"  -- Function to handle the action
    },
    mappings = {              -- Key mappings for this modal
        a = { myfield = "value1", desc = "Description 1" },
        b = { myfield = "value2", desc = "Description 2" }
    }
}
```

### Creating a Custom Modal Implementation

For more complex modals, create a custom implementation:

1. Add the `customModule` field to your modal configuration:

    ```lua
    config.modals.custom = {
        title = "Custom Modal:",
        handler = {
            field = "action",
            action = "functionCall"
        },
        customModule = "modules.hotkeys.modals.custom"
    }
    ```

2. Create a file at `modals/custom.lua`:

    ```lua
    -- Custom modal implementation
    local config = require("modules.hotkeys.config")
    local logging = require("modules.hotkeys.core.logging")
    local actions = require("modules.hotkeys.core.actions")
    local modals = require("modules.hotkeys.core.modals")

    -- Get the modal definition
    local customModal = config.modals.custom

    -- Define your custom functionality
    local function customAction()
        logging.info("Executing custom action")
        -- Your custom code here
        return true
    end

    -- Define mappings
    local customMappings = {
        c = { action = customAction, desc = "Custom Action" },
        -- Add more mappings as needed
    }

    -- Store the mappings in the modal definition
    customModal.mappings = customMappings

    -- Create the modal module
    local modal = modals.createModalModule(
        customMappings,
        customModal.title,
        customModal,
        "custom"
    )

    return modal
    ```

### Adding New Action Handlers

To add new action types, extend the `actions.lua` module:

1. Add your handler function:

    ```lua
    function M.myCustomHandler(data)
        if not validation.validate(data, {name = "custom data"}) then return false end
        
        -- Your custom implementation
        logging.info("Handling custom action with data: " .. tostring(data))
        
        -- Return success/failure
        return true
    end
    ```

2. Register the handler in the handlers table:

    ```lua
    local ACTION_HANDLERS = {
        -- Existing handlers
        launchOrFocus = M.launchOrFocus,
        openURL = M.openURL,
        -- Your new handler
        customHandler = M.myCustomHandler
    }
    ```

## Local Customization

You can customize the default mappings by creating files in the `local/` directory:

- `local/apps_mappings.lua` - Custom application mappings
- `local/finder_mappings.lua` - Custom Finder mappings
- `local/websites_mappings.lua` - Custom website mappings
- `local/global_shortcuts.lua` - Custom global shortcuts

See the README in the `local` directory for detailed customization instructions.

## Performance Considerations

The module is designed with performance in mind:

1. **Lazy Loading**: Components are only loaded when needed
2. **Efficient Data Structures**: Optimized for fast lookups
3. **Caching**: Frequently accessed data is cached
4. **Minimized UI Updates**: UI is only updated when necessary
5. **Batched Operations**: Operations are batched where possible

## API Reference

The module provides the following API through the `init.lua` file:

- `exitAllModals()` - Exit all active modal interfaces
- `setLogLevel(level)` - Set the logging level
- `setLoggingEnabled(enabled)` - Enable or disable logging
- `createModal(modalName)` - Create a modal interface from configuration
- `executeAction(handler, mapping)` - Execute an action with a handler and mapping
- `reloadConfig()` - Reload configuration and reinitialize the module
