# ONIS Viewer API - Modular Architecture

## Overview

The ONIS Viewer API has been refactored into a modular architecture to improve maintainability, scalability, and separation of concerns. The API is now organized into specialized modules, each handling a specific domain of functionality.

## Architecture

```
OVApi (Core Singleton)
├── PageManager (Page Management)
└── PluginManager (Plugin System)
```

### 1. OVApi (Core Coordinator)

**Location**: `lib/api/core/ov_api_core.dart`

The central coordinator that manages all API modules and provides a unified interface.

**Key Features**:

- Singleton pattern for global access
- Module lifecycle management
- Cross-module coordination

**Usage**:

```dart
final api = OVApi();
await api.initialize();

// Access modules
api.pages.switchToPage(pageType);
api.plugins.loadPlugin(pluginPath);
```

**Architecture**:
OVApi is now a pure coordinator with minimal cross-module coordination:

- **PageManager**: Handles all page-related functionality and observers
- **PluginManager**: Handles all plugin-related functionality and observers
- **Direct Sync**: PageManager syncs with `PageType.registeredTypes` after plugin initialization
- **No Cross-Module Observers**: Clean separation of concerns

**Global Page Creation**:
The PageFactory provides a centralized page creation system that uses page creators embedded in PageType definitions:

```dart
// Create a page widget for any registered page type
final pageWidget = PageFactory().createPage(pageType);

// The PageFactory automatically uses the pageCreator from the PageType
// or falls back to built-in page creation
```

### 2. PageManager

**Location**: `lib/api/core/page_manager.dart`

Manages page switching, page lifecycle, and page type registration.

**Key Features**:

- Page switching with history
- Page type management (synced with plugin registrations)
- Recent pages tracking
- Observer pattern for page changes
- Dynamic page type registration from plugins
- Page creation and validation during addition
- Reactive streams for page events

**Usage**:

```dart
// Switch to a page
await api.pages.switchToPage(pageType);

// Add new page type (creates and validates the page)
api.pages.addPageType(customPageType);

// Get current page
final currentPage = api.pages.currentPage;

// Sync with registered page types
api.pages.syncWithRegisteredTypes();

// Create a page widget using PageFactory
final pageWidget = PageFactory().createPage(pageType);

// Listen to page events directly from PageManager
api.pages.onPageChanged.listen((pageType) {
  // Handle page change
});
api.pages.onPageAdded.listen((pageType) {
  // Handle new page
});

// Listen to plugin events directly from PluginManager
api.plugins.onPluginLoaded.listen((plugin) {
  // Handle plugin loaded
});
```

**Page Addition Process**:
When `addPageType()` is called:

1. **Page Creation**: Uses PageFactory to create the page widget
2. **Validation**: Ensures the page can be created successfully
3. **Registration**: Adds the page type to available pages
4. **Auto-Selection**: Sets as current page if no current page exists
5. **Notification**: Notifies observers of the new page
6. **Error Handling**: Reports errors if page creation fails

**Reactive Streams**:
PageManager provides reactive streams for real-time updates:

- `onPageChanged`: Fired when user switches pages
- `onPageAdded`: Fired when a new page is added
- `onPageRemoved`: Fired when a page is removed
- `onError`: Fired when page-related errors occur

**Stream Architecture**:
Streams are located in their respective modules and accessed directly:

- **PageManager**: Handles all page-related streams
  - `api.pages.onPageChanged`
  - `api.pages.onPageAdded`
  - `api.pages.onPageRemoved`
  - `api.pages.onError`
- **PluginManager**: Handles all plugin-related streams
  - `api.plugins.onPluginLoaded`
  - `api.plugins.onPluginUnloaded`
  - `api.plugins.onError`
- **Direct Access**: No need to go through OVApi for streams

**Observer Pattern**:
UI components now observe modules directly instead of going through OVApi:

````dart
// Direct observation of PageManager
class MyWidget extends StatefulWidget implements PageManagerObserver {
  @override
  void initState() {
    super.initState();
    OVApi().pages.addObserver(this);
  }

  @override
  void onPageChanged(PageType? oldPage, PageType newPage) {
    setState(() {
      // Handle page change
    });
  }
}

**Page Type Registration**:
Page types are now registered by plugins rather than being hardcoded:

```dart
// In a plugin
const PageType myPageType = PageType(
  id: 'my_page',
  name: 'My Page',
  description: 'My custom page',
  icon: Icons.star,
  color: Colors.blue,
);

// Register the page type
PageType.register(myPageType);

// Unregister when plugin is disposed
PageType.unregister(myPageType.id);
````

### 3. PageFactory (Page Creation)

**Location**: `lib/core/page_factory.dart`

A singleton factory that handles page widget creation from page types.

**Key Features**:

- Singleton pattern for global access
- Page creator embedded in PageType definitions
- Dynamic page creation from page types
- Built-in page creation fallback
- Error handling for page creation failures

**Usage**:

```dart
// Create a page widget
final pageWidget = PageFactory().createPage(pageType);

// Create a page widget by ID
final pageWidget = PageFactory().createPageById('database');

// Check if a creator exists
bool hasCreator = PageFactory().hasPageCreator(pageType);
```

**Page Creation Process**:

1. **PageType Definition**: PageType includes an optional pageCreator function
2. **Creator Execution**: PageFactory uses the pageCreator from PageType if available
3. **Built-in Fallback**: If no creator is provided, built-in page creation is attempted
4. **Error Handling**: Any creation errors are logged and null is returned

**Plugin Integration**:
Plugins define their page creators directly in the PageType:

```dart
// Define page type with creator
const PageType myPageType = PageType(
  id: 'my_page',
  name: 'My Page',
  description: 'My custom page',
  icon: Icons.star,
  color: Colors.blue,
  pageCreator: _createMyPage,
);

// Create function
Widget _createMyPage(PageType pageType) {
  return const MyPage();
}

// Register (includes page creator)
PageType.register(myPageType);

// Unregister (includes page creator)
PageType.unregister(myPageType.id);
```

**Built-in Plugin Loading**:
Built-in plugins (Database, Viewer) are automatically loaded during initialization:

- Plugins are created and registered
- Page types are registered with PageType.register()
- PageManager syncs with registered page types after plugin initialization
- Pages are created and validated during addition

**Simplified Plugin Interface**:
Plugins no longer need to provide a `pageTypes` list since page types are registered directly:

- Page types are self-contained with their creators
- No need to maintain separate page type lists
- Cleaner plugin interface

**Simplified Architecture**:
The cross-module coordination has been simplified:

- No more `_PluginManagerObserver` needed
- PageManager directly syncs with `PageType.registeredTypes`
- Cleaner separation of concerns
- More efficient initialization flow

### 4. PluginManager (Plugin Lifecycle)

**Location**: `lib/api/core/plugin_manager.dart`

Handles plugin discovery, loading, validation, and lifecycle management.

**Key Features**:

- Built-in plugin management
- Dynamic plugin loading
- Plugin validation and conflict resolution
- Plugin directory discovery

**Plugin Structure**:

```
lib/plugins/
├── database/
│   ├── database_plugin.dart
│   └── page/
│       ├── database_page.dart
│       └── database_controller.dart
├── viewer/
│   ├── viewer_plugin.dart
│   └── page/
│       ├── viewer_page.dart
│       └── viewer_controller.dart
├── base/
│   └── (base plugin classes)
└── external/
    └── (external plugins)
```

**Usage**:

```dart
// Load a plugin
await api.plugins.loadPlugin('/path/to/plugin');

// Get plugin information
final info = api.plugins.getPluginInfo('plugin_id');

// Unload a plugin
await api.plugins.unloadPlugin('plugin_id');
```

## Observer Pattern

All modules support the observer pattern for reactive updates. UI components now observe modules directly instead of going through OVApi:

```dart
// Direct observation of PageManager
class MyWidget extends StatefulWidget implements PageManagerObserver {
  @override
  void initState() {
    super.initState();
    OVApi().pages.addObserver(this);
  }

  @override
  void onPageChanged(PageType? oldPage, PageType newPage) {
    // Handle page changes
  }

  @override
  void onPageAdded(PageType pageType) {
    // Handle page added
  }

  @override
  void onPageRemoved(PageType pageType) {
    // Handle page removed
  }

  @override
  void onError(String message) {
    // Handle errors
  }
}

// Direct observation of PluginManager
class MyWidget extends StatefulWidget implements PluginManagerObserver {
  @override
  void initState() {
    super.initState();
    OVApi().plugins.addObserver(this);
  }

  @override
  void onPluginLoaded(OnisViewerPlugin plugin) {
    // Handle plugin loaded
  }

  @override
  void onPluginUnloaded(String pluginId) {
    // Handle plugin unloaded
  }

  @override
  void onError(String message) {
    // Handle errors
  }
}
```

## Stream-Based Events

The API provides streams for reactive programming. Streams are accessed directly from their respective modules:

```dart
// Listen to page changes directly from PageManager
api.pages.onPageChanged.listen((pageType) {
  print('Page changed to: ${pageType.name}');
});

api.pages.onPageAdded.listen((pageType) {
  print('Page added: ${pageType.name}');
});

// Listen to plugin events directly from PluginManager
api.plugins.onPluginLoaded.listen((plugin) {
  print('Plugin loaded: ${plugin.name}');
});

api.plugins.onPluginUnloaded.listen((pluginId) {
  print('Plugin unloaded: $pluginId');
});

// Listen to errors from specific modules
api.pages.onError.listen((message) {
  print('Page error: $message');
});

api.plugins.onError.listen((message) {
  print('Plugin error: $message');
});
```

## Module Communication

Modules are designed to be independent with minimal cross-module dependencies:

```dart
// Plugin manager registers plugins
await api.plugins.registerPlugin(plugin);

// Page manager syncs with registered page types
api.pages.syncWithRegisteredTypes();

// Page manager notifies observers of page changes
await api.pages.switchToPage(pageType);
```

**Simplified Coordination**:

- **PluginManager**: Handles plugin lifecycle independently
- **PageManager**: Syncs with `PageType.registeredTypes` after plugin initialization
- **No Cross-Module Observers**: Direct sync instead of complex observer patterns
- **Clean Separation**: Each module has clear, focused responsibilities

## Benefits of Modular Architecture

1. **Separation of Concerns**: Each module handles a specific domain
2. **Maintainability**: Easier to maintain and debug individual modules
3. **Scalability**: Easy to add new modules without affecting existing ones
4. **Testability**: Each module can be tested independently
5. **Reusability**: Modules can be reused in different contexts
6. **Clear Dependencies**: Explicit dependencies between modules

## Adding New Modules

To add a new module (e.g., DatabaseApi, ImageApi):

1. Create the module in `lib/api/modules/`
2. Implement the module interface
3. Add it to the core OVApi
4. Update initialization and disposal
5. Add getter for easy access

Example:

```dart
// In ov_api_core.dart
late final NewModuleApi _newModuleApi;

// Initialize
_newModuleApi = NewModuleApi();
await _newModuleApi.initialize();

// Add getter
NewModuleApi get newModule => _newModuleApi;

// Dispose
await _newModuleApi.dispose();
```

## Future Module Extensions

The modular architecture is designed to easily accommodate future modules:

### Planned Modules:

- **DatabaseApi**: Database connections, queries, and schema management
- **ImageApi**: Image loading, processing, and metadata handling
- **DicomApi**: DICOM-specific operations and tag management
- **NetworkApi**: Network communication and API endpoints
- **StorageApi**: File system and storage management

### Module Structure:

```
OVApi (Core Singleton)
├── PageManager (Page Management)
├── PluginManager (Plugin System)
├── DatabaseApi (Database Operations) - Future
├── ImageApi (Image Processing) - Future
├── DicomApi (DICOM Operations) - Future
├── NetworkApi (Network Communication) - Future
└── StorageApi (Storage Management) - Future
```

## Migration from Old API

The old monolithic OVApi has been replaced with the modular structure. All existing functionality is preserved but now organized into logical modules:

- `OVApi.switchToPage()` → `OVApi.pages.switchToPage()`
- `OVApi.registerPlugin()` → `OVApi.plugins.registerPlugin()`

The old API file now re-exports the new modular API for backward compatibility.

## Choosing Between Observers and Streams

The PageManager provides two ways to react to page events: **Observer Pattern** and **Streams**. Both receive the same events, but they have different use cases and characteristics.

### Observer Pattern vs Streams

| Aspect                   | Observer Pattern            | Streams                             |
| ------------------------ | --------------------------- | ----------------------------------- |
| **Lifecycle Management** | Manual (add/remove)         | Automatic (subscription)            |
| **Memory Management**    | Manual cleanup required     | Automatic with proper subscription  |
| **Error Handling**       | Built-in error callbacks    | Separate error stream               |
| **Multiple Listeners**   | One observer per widget     | Multiple stream subscriptions       |
| **Widget Integration**   | Direct widget state updates | Reactive programming                |
| **Complexity**           | Simpler for simple cases    | More powerful for complex scenarios |

### When to Use Observer Pattern

**Best for:**

- Simple widget state updates
- Direct UI reactions
- When you need both old and new values
- When you want built-in error handling
- When you prefer explicit lifecycle management

**Example - Simple Widget:**

```dart
class SimplePageWidget extends StatefulWidget implements PageManagerObserver {
  @override
  void initState() {
    super.initState();
    OVApi().pages.addObserver(this);
  }

  @override
  void dispose() {
    OVApi().pages.removeObserver(this);
    super.dispose();
  }

  @override
  void onPageChanged(PageType? oldPage, PageType newPage) {
    setState(() {
      // Simple state update
      currentPage = newPage;
    });
  }

  @override
  void onPageAdded(PageType pageType) {
    setState(() {
      // Update available pages list
    });
  }

  @override
  void onPageRemoved(PageType pageType) {
    setState(() {
      // Remove from available pages list
    });
  }

  @override
  void onError(String message) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
```

### When to Use Streams

**Best for:**

- Complex reactive programming
- Multiple transformations
- When you need to combine with other streams
- When you want automatic memory management
- When you prefer functional programming style

**Example - Complex Reactive Widget:**

```dart
class ReactivePageWidget extends StatefulWidget {
  @override
  State<ReactivePageWidget> createState() => _ReactivePageWidgetState();
}

class _ReactivePageWidgetState extends State<ReactivePageWidget> {
  StreamSubscription<PageType>? _pageChangeSubscription;
  StreamSubscription<PageType>? _pageAddedSubscription;
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _setupStreams() {
    final api = OVApi();

    // Combine page changes with other logic
    _pageChangeSubscription = api.pages.onPageChanged
        .where((pageType) => pageType.id == 'database') // Filter
        .debounceTime(const Duration(milliseconds: 300)) // Debounce
        .listen((pageType) {
          setState(() {
            // Complex reactive logic
          });
        });

    // Handle page additions
    _pageAddedSubscription = api.pages.onPageAdded
        .listen((pageType) {
          setState(() {
            // Update UI
          });
        });

    // Handle errors
    _errorSubscription = api.pages.onError
        .listen((message) {
          // Show error
        });
  }

  @override
  void dispose() {
    _pageChangeSubscription?.cancel();
    _pageAddedSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }
}
```

### Advanced Stream Usage

**Combining Multiple Streams:**

```dart
class AdvancedPageWidget extends StatefulWidget {
  @override
  State<AdvancedPageWidget> createState() => _AdvancedPageWidgetState();
}

class _AdvancedPageWidgetState extends State<AdvancedPageWidget> {
  StreamSubscription? _combinedSubscription;

  @override
  void initState() {
    super.initState();
    _setupCombinedStreams();
  }

  void _setupCombinedStreams() {
    final api = OVApi();

    // Combine page changes with plugin events
    _combinedSubscription = Rx.combineLatest2(
      api.pages.onPageChanged,
      api.plugins.onPluginLoaded,
      (PageType page, OnisViewerPlugin plugin) => {
        'page': page,
        'plugin': plugin,
      },
    ).listen((data) {
      // Handle combined events
      setState(() {
        // Update UI based on both page and plugin state
      });
    });
  }

  @override
  void dispose() {
    _combinedSubscription?.cancel();
    super.dispose();
  }
}
```

### Guidelines for Choosing

**Use Observer Pattern when:**

- ✅ You need simple, direct widget updates
- ✅ You want built-in error handling
- ✅ You prefer explicit lifecycle management
- ✅ You need both old and new values in callbacks
- ✅ You're building simple UI components

**Use Streams when:**

- ✅ You need complex reactive programming
- ✅ You want to combine multiple event sources
- ✅ You need to filter, transform, or debounce events
- ✅ You prefer functional programming style
- ✅ You're building complex, reactive components
- ✅ You want automatic memory management

### Best Practices

**Observer Pattern:**

```dart
// Always implement all methods
class MyWidget extends StatefulWidget implements PageManagerObserver {
  @override
  void onPageChanged(PageType? oldPage, PageType newPage) {
    // Handle page change
  }

  @override
  void onPageAdded(PageType pageType) {
    // Handle page added
  }

  @override
  void onPageRemoved(PageType pageType) {
    // Handle page removed
  }

  @override
  void onError(String message) {
    // Handle error
  }
}
```

**Streams:**

```dart
// Always cancel subscriptions in dispose
@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}

// Use proper error handling
_stream.listen(
  (data) => handleData(data),
  onError: (error) => handleError(error),
);
```

### Performance Considerations

- **Observers**: Lightweight, direct method calls
- **Streams**: Slightly more overhead, but better for complex scenarios
- **Memory**: Both require proper cleanup to avoid memory leaks
- **Scalability**: Streams scale better for complex reactive scenarios
