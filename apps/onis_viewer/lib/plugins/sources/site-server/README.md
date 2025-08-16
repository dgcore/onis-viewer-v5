# Site Server Plugin - Hierarchical Source Structure

## Overview

The Site Server plugin implements a hierarchical source structure where authentication to a site source creates child sources representing different data containers and services.

## Architecture

### Source Hierarchy

```
SiteSource (Root)
├── SiteChildSource (Partition)
│   ├── SiteChildSource (Album)
│   └── SiteChildSource (Album)
├── SiteChildSource (Partition)
│   └── SiteChildSource (Album)
└── SiteChildSource (DICOM PACS)
    └── SiteChildSource (DICOM PACS)
```

### Source Types

#### 1. SiteSource (Root)

- **Purpose**: Main site server connection point
- **Authentication**: Required before child sources are available
- **Behavior**:
  - Shows login panel when not authenticated
  - Creates child sources after successful authentication
  - Removes child sources when disconnected

#### 2. SiteChildSource Types

##### Partition

- **Purpose**: Represents a data partition/volume
- **Icon**: Folder icon
- **Color**: Blue
- **Example**: "Clinical Data", "Research Data"

##### Album

- **Purpose**: Represents a collection of studies within a partition
- **Icon**: Photo library icon
- **Color**: Purple
- **Example**: "Cardiology Studies", "Neurology Studies"

##### DICOM PACS

- **Purpose**: Represents a DICOM PACS server connection
- **Icon**: Medical services icon
- **Color**: Orange
- **Example**: "Main PACS Server", "Backup PACS Server"

## Implementation Details

### Key Classes

#### SiteSource

- Extends `DatabaseSource`
- Manages authentication state
- Creates child sources after successful login
- Removes child sources on disconnect

#### SiteChildSource

- Extends `DatabaseSource`
- Represents child sources with specific types
- Contains type-specific metadata
- Provides type-specific icons and colors

#### SiteSourceManager

- Singleton manager for site source operations
- Handles child source creation and removal
- Integrates with `DatabaseSourceManager`

### Authentication Flow

1. **Initial State**: Site source shows login panel
2. **User Authentication**: User enters credentials
3. **Server Response**: Simulated 1-second delay
4. **Child Source Creation**: `SiteSourceManager` creates child sources
5. **UI Update**: Login panel disappears, child sources appear

### Disconnection Flow

1. **User Disconnect**: User clicks disconnect button
2. **Server Disconnect**: Simulated 10-second delay
3. **Child Source Removal**: `SiteSourceManager` removes all child sources
4. **UI Update**: Child sources disappear, login panel reappears

## Usage

### Creating a Site Source

```dart
final siteSource = SiteSource(
  uid: 'site_server_1',
  name: 'Site Server 1',
  metadata: {
    'type': 'site_server',
    'url': 'http://localhost:8080'
  },
);

// Register with DatabaseSourceManager
api.sources.registerSource(siteSource);
```

### Accessing Child Sources

```dart
// Get all partitions
final partitions = siteSource.partitions;

// Get all albums
final albums = siteSource.albums;

// Get all DICOM PACS sources
final pacsSources = siteSource.dicomPacsSources;

// Get child sources by type
final partitions = siteSource.getChildSourcesByType(SiteChildSourceType.partition);
```

### UI Components

#### SiteSourceTreeView

- Displays hierarchical source structure
- Shows source icons, names, and status
- Handles source selection
- Provides disconnect functionality

#### SiteSourceInfoCard

- Displays detailed source information
- Shows metadata and status
- Type-specific information display

## Configuration

### Child Source Creation

Child sources are created in `SiteSourceManager.createChildSourcesForSite()`:

- **Partitions**: Clinical Data, Research Data
- **Albums**: Cardiology Studies, Neurology Studies
- **DICOM PACS**: Main PACS Server, Backup PACS Server

### Metadata Structure

Each child source contains relevant metadata:

```dart
// Partition metadata
{
  'description': 'Main clinical data partition',
  'size': '2.5 TB',
  'created': DateTime.now().subtract(Duration(days: 30)),
}

// Album metadata
{
  'description': 'Cardiology imaging studies',
  'partition': 'Clinical Data',
  'studyCount': 1250,
  'created': DateTime.now().subtract(Duration(days: 20)),
}

// DICOM PACS metadata
{
  'description': 'Primary DICOM PACS server',
  'aeTitle': 'MAIN_PACS',
  'host': '192.168.1.100',
  'port': 104,
  'status': 'Online',
}
```

## Future Enhancements

1. **Dynamic Child Source Creation**: Fetch real child sources from server
2. **Nested Hierarchies**: Support for deeper nesting (e.g., albums within albums)
3. **Source Filtering**: Filter child sources by type or metadata
4. **Bulk Operations**: Select and operate on multiple child sources
5. **Source Templates**: Predefined child source configurations
6. **Real-time Updates**: Live updates when child sources change on server
