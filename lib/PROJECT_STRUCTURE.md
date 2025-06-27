# DisasterLink - Flutter Project Structure

This project follows a modular architecture using Flutter Modular for better code organization, scalability, and maintainability.

## 📁 Folder Structure

```
lib/
├── app/
│   ├── app_module.dart          # Main application module
│   ├── app_widget.dart          # Root application widget
│   ├── app_exports.dart         # Centralized exports
│   ├── modules/                 # Feature modules
│   │   └── home/
│   │       ├── home_module.dart
│   │       └── presentation/
│   │           ├── pages/
│   │           │   └── home_page.dart
│   │           └── stores/
│   │               └── home_store.dart
│   └── shared/                  # Shared resources
│       ├── constants/
│       │   └── app_constants.dart
│       ├── themes/
│       │   └── app_theme.dart
│       ├── widgets/
│       │   └── common_widgets.dart
│       └── utils/
│           └── app_utils.dart
└── main.dart                    # Application entry point
```

## 🏗️ Architecture

### **Modular Architecture**
- Each feature is organized as a separate module
- Modules are self-contained with their own routes and dependencies
- Promotes separation of concerns and code reusability

### **Module Structure**
Each module follows this structure:
- `module.dart` - Module configuration (routes and dependencies)
- `presentation/` - UI layer (pages, widgets, stores)
- `domain/` - Business logic layer (entities, repositories, use cases)
- `data/` - Data layer (data sources, models, implementations)

## 🎨 Design System

### **Colors**
- Primary: Red (#D32F2F) - Emergency/Alert theme
- Secondary: Blue (#1976D2) - Information theme
- Success: Green (#388E3C)
- Warning: Orange (#F57C00)
- Error: Red (#D32F2F)

### **Components**
- `CustomButton` - Reusable button component
- `CustomCard` - Consistent card styling
- `EmptyState` - Empty state placeholder
- `LoadingWidget` - Loading indicator

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK (latest stable version)
- Dart SDK
- VS Code or Android Studio

### **Installation**
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

### **Adding New Modules**

1. Create a new folder under `lib/app/modules/`
2. Create the module structure:
   ```
   new_module/
   ├── new_module_module.dart
   ├── presentation/
   │   ├── pages/
   │   ├── stores/
   │   └── widgets/
   ├── domain/
   │   ├── entities/
   │   ├── repositories/
   │   └── use_cases/
   └── data/
       ├── data_sources/
       ├── models/
       └── repositories/
   ```
3. Register the module in `app_module.dart`
4. Add exports to `app_exports.dart`

## 🧩 Key Features

### **Current Features**
- ✅ Home page with emergency status
- ✅ Quick action buttons
- ✅ Recent alerts display
- ✅ Modern UI with disaster response theme
- ✅ Modular architecture setup
- ✅ Shared components and utilities

### **Planned Features**
- 🔄 Emergency reporting system
- 🔄 Interactive map with disaster zones
- 🔄 Real-time alerts and notifications
- 🔄 Emergency contact management
- 🔄 Community chat and updates
- 🔄 Offline support
- 🔄 Multi-language support

## 📱 Screens

### **Home Page**
- Emergency status indicator
- Quick action buttons (Report Emergency, Find Shelter, etc.)
- Recent alerts list
- Bottom navigation

## 🛠️ Development Guidelines

### **State Management**
- Using ChangeNotifier for simple state management
- Store classes for business logic
- Flutter Modular for dependency injection

### **Code Style**
- Follow Dart conventions
- Use meaningful variable and function names
- Comment complex logic
- Keep functions small and focused

### **File Naming**
- Use snake_case for file names
- Use descriptive names
- Group related files in folders

## 🤝 Contributing

1. Create a feature branch
2. Follow the existing code structure
3. Add tests for new features
4. Update documentation
5. Create a pull request

## 📄 License

This project is licensed under the MIT License.
