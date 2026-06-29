# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-06-30 - Enterprise Edition

### 🎉 Major Release

This is a major release that transforms Arabic HTTP Studio from a basic HTTP client into a professional-grade platform suitable for enterprise use.

### Added

#### 🤖 Artificial Intelligence (AI)
- **AI Provider System**: Pluggable architecture supporting any OpenAI-compatible API (OpenAI, Azure, Ollama, vLLM, local models)
- **AI Features**:
  - Explain HTTP errors automatically
  - Suggest fixes for failed requests
  - Optimize request headers
  - Suggest authentication configuration
  - Explain status codes
  - Summarize long responses
  - Generate requests from natural language descriptions
  - Generate code in 12 languages from requests
  - Search history using natural language
- **AI Configuration Dialog**: Enable/disable, configure API keys, test connections
- **AI Chat Widget**: Interactive chat interface with quick actions
- **Secure Storage**: API keys stored in flutter_secure_storage

#### 🔌 Plugin System
- **Plugin Contracts**: `AppPlugin` interface for third-party extensions
- **Plugin Registry**: Dynamic plugin registration and lifecycle management
- **Plugin Context**: Register custom tools, AI providers, export/import formats, screens, and settings sections
- **Extensible Architecture**: Add functionality without modifying core code

#### 📋 Session Management
- **Session Model**: Save complete testing workflows with requests and responses
- **Session Repository**: CRUD operations with Hive storage
- **Session Comparison**: Compare two sessions with detailed difference reporting
- **Session Entry**: Track individual request/response pairs with notes

#### 🔄 Comparison Tools
- **Request Comparison**: Compare two HTTP requests side-by-side
- **Response Comparison**: Compare two HTTP responses
- **JSON Comparison**: Deep comparison with path tracking
- **Text Diff**: Line-by-line text comparison
- **Header Comparison**: Compare headers between requests

#### 🔧 JSON Tools
- **Formatter**: Beautify JSON with configurable indentation
- **Validator**: Validate JSON with detailed error messages
- **Compare**: Deep comparison with difference tracking (added, removed, changed, type mismatch)
- **Tree Viewer**: Interactive collapsible tree with color-coded value types
- **Search**: Search keys and values in JSON (case-insensitive)
- **Statistics**: Key count, value types, max depth, size analysis

#### 🔧 XML Tools
- **Formatter**: Beautify XML with proper indentation
- **Validator**: Validate XML structure
- **Tree Viewer**: Hierarchical tree view
- **Compare**: Compare XML documents with detailed differences

#### 🔐 Encoding & Crypto Tools
- **Base64**: Encode/decode text and files
- **URL Encoding**: Encode/decode URL components
- **Unicode**: Encode/decode Unicode escape sequences
- **Hex**: Encode/decode hexadecimal
- **Hashing**: MD5, SHA-1, SHA-256, SHA-512
- **HMAC**: HMAC-SHA256, HMAC-SHA512, HMAC-MD5, HMAC-SHA1
- **UUID Generation**: Generate unique identifiers

#### 📁 File Explorer
- **File Listing**: Browse directories
- **File Operations**: Create, delete, rename, duplicate
- **Recent Files**: Track recently accessed files
- **Pinned Files**: Quick access to important files
- **File Preview**: View file contents
- **Import/Export**: Move files in and out

#### 📊 Reports
- **Comprehensive Reports**: Request summary, response summary, performance metrics, timing, sizes, errors, user notes
- **Batch Reports**: Generate reports for multiple requests
- **Export Formats**: Markdown and HTML
- **Statistics**: Success/failure counts, average response time, total data size

#### 🛠️ Developer Tools
- **Performance Monitor**: Real-time FPS, memory usage, CPU usage, widget count, isolate count
- **Network Inspector**: Inspect all network requests
- **Crash Logs**: View and track application crashes
- **Storage Viewer**: Browse Hive database boxes
- **Memory Viewer**: Detailed memory usage breakdown
- **Shared Preferences Viewer**: View secure storage info

#### ⚡ Performance Optimizations
- **Debouncer & Throttler**: Control event frequency
- **LRU Cache**: Least Recently Used caching
- **Timed Cache**: Time-based cache expiration
- **Isolate Service**: Background processing for heavy operations
- **Pagination**: Efficient data loading with infinite scroll
- **Smart Caching**: HTTP response caching, computed value caching, long-term caching

#### 🎨 UI/UX Improvements
- **Material You**: Dynamic color support (Android 12+)
- **Bottom Navigation**: Modern navigation bar with 5 tabs
- **Professional Animations**: Fade, slide, scale, staggered list animations
- **Shimmer Loading**: Skeleton loading states
- **Responsive Design**: Adapts to all screen sizes
- **Dynamic Color Service**: Wallpaper-based theming

#### 📁 Project Management
- **Workspace**: Top-level organizational unit
- **Project**: API-specific grouping with base URL
- **Tags**: Color-coded labels for organization
- **Notes**: Markdown notes attached to requests/collections

#### 💾 Backup & Restore
- **Local Backups**: Create backup snapshots
- **Restore**: Restore from any backup
- **Export/Import**: Share backup files
- **Automatic Backups**: Configurable periodic backups
- **Backup History**: Track all backups with timestamps

#### 🐙 GitHub & Documentation
- **CONTRIBUTING.md**: Comprehensive contribution guide
- **CODE_OF_CONDUCT.md**: Community standards
- **SECURITY.md**: Security policy and reporting
- **Issue Templates**: Bug report, feature request, question, help wanted
- **Pull Request Template**: Standardized PR template
- **Dependabot**: Automated dependency updates
- **Release Workflow**: Automated GitHub releases on tags
- **Developer Guide**: Detailed developer documentation
- **Roadmap**: Project roadmap with priorities

### Changed
- Updated version to 2.0.0
- Updated description to reflect AI capabilities
- Enhanced settings screen with new sections
- Improved router with all new routes
- Updated MainShell with Tools tab
- Enhanced HiveSetup with new boxes

### Fixed
- Fixed TODO: Add to favorites now properly adds/removes favorites
- Fixed missing imports in request_builder_screen.dart
- Fixed async handling in menu actions

### Security
- API keys stored in secure storage (Android Keystore / iOS Keychain)
- All sensitive data encrypted with AES-256
- No sensitive data logged

---

## [1.0.0] - 2024-01-01 - Initial Release

### Added

#### Core Features
- Complete HTTP client supporting GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
- WebSocket support with auto-reconnect, ping/pong, and message history
- Server-Sent Events (SSE) support
- HTTP/1.1, HTTP/2, HTTP/3 protocol support
- TLS with custom certificates and certificate pinning
- HTTP and SOCKS5 proxy support

#### Authentication
- Bearer Token, Basic Auth, Digest Auth, API Key, JWT, Custom Auth

#### Request Body Types
- JSON, XML, Form Data, Multipart, Binary upload, Raw text, HTML

#### Response Viewer
- Pretty JSON, XML, HTML, Markdown, Image, Raw, Hex, Base64

#### Code Generation (12 languages)
- cURL, Dart (Dio), JavaScript (Fetch), Python, Java, Kotlin, PHP, Node.js, Go, Rust, C#, JavaScript (Axios)

#### Organization
- Collections, folders, tags, favorites, pinned items, search, recent items

#### Variables and Environments
- Global variables, encrypted secrets, dynamic variables, multiple environments

#### History and Logs
- Complete request/response history, detailed timeline, comprehensive logging

#### Import/Export
- JSON, YAML, CSV, TXT, ZIP

#### UI/UX
- Full Arabic language support (RTL), English (LTR), Dark/Light mode, Material 3

#### Architecture
- Clean Architecture, Repository Pattern, Dependency Injection (Riverpod)

#### Testing
- Unit tests, Widget tests

#### CI/CD
- GitHub Actions, code analysis, automated testing, APK builds, App Bundle, iOS builds, automatic releases

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 2.0.0 | 2024-06-30 | Enterprise Edition - AI, Plugins, Advanced Tools |
| 1.0.0 | 2024-01-01 | Initial Release |

---

## Semantic Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Incompatible API changes
- **MINOR** (1.X.0): New features, backward compatible
- **PATCH** (1.0.X): Bug fixes, backward compatible

### Version Numbering

```
MAJOR.MINOR.PATCH+BUILD
```

- **MAJOR**: Breaking changes
- **MINOR**: New features
- **PATCH**: Bug fixes
- **BUILD**: Build number (incremented for each build)

### Upgrade Guide

#### From 1.0.0 to 2.0.0

1. Update `pubspec.yaml` dependencies
2. Run `flutter pub get`
3. The app will automatically migrate your data
4. New features (AI, Tools) are optional and can be enabled in settings

No data loss will occur during the upgrade.
