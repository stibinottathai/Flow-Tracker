# Project Architecture Documentation

This project follows **Clean Architecture** principles with **Riverpod** for state management.

## 🏗️ Architecture Overview

The project is organized into three main layers:

### 1. **Presentation Layer** (`presentation/`)
- **Pages**: UI screens
- **Providers**: Riverpod providers and notifiers
- **Widgets**: Reusable UI components
- **State**: State classes (using Freezed)

### 2. **Domain Layer** (`domain/`)
- **Entities**: Business objects
- **Repositories**: Abstract repository interfaces
- **Usecases**: Business logic implementations

### 3. **Data Layer** (`data/`)
- **Models**: Data transfer objects
- **Repositories**: Repository implementations
- **Data Sources**: 
  - Remote (API calls)
  - Local (Cache/Database)

## 📁 Folder Structure

```
lib/
├── core/
│   ├── constants/          # App-wide constants
│   ├── di/                 # Dependency injection setup
│   ├── error/              # Error handling (failures & exceptions)
│   ├── extensions/         # Extension methods
│   ├── network/            # Network utilities
│   ├── theme/              # App theming
│   ├── usecase/            # Base usecase classes
│   └── utils/              # Utilities and typedefs
│
├── features/
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/    # Remote & local data sources
│       │   ├── models/         # Data models
│       │   └── repositories/   # Repository implementations
│       ├── domain/
│       │   ├── entities/       # Business entities
│       │   ├── repositories/   # Repository contracts
│       │   └── usecases/       # Business logic
│       └── presentation/
│           ├── pages/          # UI pages
│           ├── providers/      # Riverpod providers
│           └── widgets/        # Feature-specific widgets
│
└── main.dart
```

## 🔧 Key Technologies

- **State Management**: Riverpod + Riverpod Generator
- **Code Generation**: 
  - `freezed` (immutable classes)
  - `json_serializable` (JSON serialization)
  - `riverpod_generator` (provider generation)
  - `injectable` (dependency injection)
- **Networking**: Dio
- **Local Storage**: SharedPreferences
- **Functional Programming**: Dartz (Either type)

## 🚀 Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Generate Code
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run the App
```bash
flutter run
```

## 📝 Code Generation Commands

### Generate code once
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Watch for changes (auto-generate)
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Clean generated files
```bash
flutter pub run build_runner clean
```

## 🎯 Creating a New Feature

Follow these steps to create a new feature:

### 1. Create Feature Structure
```
lib/features/[feature_name]/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── pages/
    ├── providers/
    └── widgets/
```

### 2. Domain Layer (Business Logic)
```dart
// 1. Create Entity
@freezed
class MyEntity with _$MyEntity {
  const factory MyEntity({
    required String id,
    required String name,
  }) = _MyEntity;
}

// 2. Create Repository Interface
abstract class MyRepository {
  ResultFuture<List<MyEntity>> getItems();
}

// 3. Create Usecase
@lazySingleton
class GetItems extends UseCaseNoParams<List<MyEntity>> {
  final MyRepository _repository;
  GetItems(this._repository);
  
  @override
  ResultFuture<List<MyEntity>> call() => _repository.getItems();
}
```

### 3. Data Layer (Data Management)
```dart
// 1. Create Model
@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
  }) = _MyModel;
  
  factory MyModel.fromJson(Map<String, dynamic> json) => 
      _$MyModelFromJson(json);
}

// 2. Create Data Sources
@LazySingleton(as: MyRemoteDataSource)
class MyRemoteDataSourceImpl implements MyRemoteDataSource {
  final Dio _dio;
  MyRemoteDataSourceImpl(this._dio);
  
  @override
  Future<List<MyModel>> getItems() async {
    final response = await _dio.get('/items');
    return (response.data as List)
        .map((json) => MyModel.fromJson(json))
        .toList();
  }
}

// 3. Implement Repository
@LazySingleton(as: MyRepository)
class MyRepositoryImpl implements MyRepository {
  final MyRemoteDataSource _remoteDataSource;
  final MyLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  
  MyRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );
  
  @override
  ResultFuture<List<MyEntity>> getItems() async {
    try {
      if (await _networkInfo.isConnected) {
        final items = await _remoteDataSource.getItems();
        await _localDataSource.cacheItems(items);
        return Right(items.map(_mapToEntity).toList());
      } else {
        final cached = await _localDataSource.getCachedItems();
        return Right(cached.map(_mapToEntity).toList());
      }
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
```

### 4. Presentation Layer (UI)
```dart
// 1. Create State
@freezed
class MyState with _$MyState {
  const factory MyState.initial() = _Initial;
  const factory MyState.loading() = _Loading;
  const factory MyState.loaded(List<MyEntity> items) = _Loaded;
  const factory MyState.error(String message) = _Error;
}

// 2. Create Provider
@riverpod
class MyNotifier extends _$MyNotifier {
  late final GetItems _getItems;
  
  @override
  MyState build() {
    _getItems = getIt<GetItems>();
    return const MyState.initial();
  }
  
  Future<void> loadItems() async {
    state = const MyState.loading();
    final result = await _getItems();
    result.fold(
      (failure) => state = MyState.error(failure.toString()),
      (items) => state = MyState.loaded(items),
    );
  }
}

// 3. Create Page
class MyPage extends ConsumerWidget {
  const MyPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Page')),
      body: state.when(
        initial: () => const Center(child: Text('Press to load')),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ListTile(title: Text(items[index].name));
          },
        ),
        error: (message) => Center(child: Text('Error: $message')),
      ),
    );
  }
}
```

### 5. Don't Forget!
- Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
- Add `@injectable` or `@lazySingleton` annotations to classes that need DI
- Use `getIt<YourClass>()` to retrieve dependencies

## 🧪 Testing

Structure your tests to mirror the main code structure:
```
test/
├── features/
│   └── [feature_name]/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── core/
```

## 📦 Dependencies

Key dependencies used in this project:

- `flutter_riverpod: ^2.6.1` - State management
- `riverpod_annotation: ^2.6.1` - Riverpod annotations
- `dartz: ^0.10.1` - Functional programming (Either, Option)
- `dio: ^5.7.0` - HTTP client
- `freezed: ^2.5.7` - Code generation for immutable classes
- `injectable: ^2.5.0` - Dependency injection
- `get_it: ^8.0.3` - Service locator

## 🎨 Code Style

- Use `freezed` for immutable data classes
- Use `Either` from dartz for error handling
- Keep business logic in usecases
- Repository interfaces in domain, implementations in data
- Use Riverpod providers for state management
- Follow the dependency rule: outer layers depend on inner layers

## 📚 Additional Resources

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Riverpod Documentation](https://riverpod.dev/)
- [Freezed Documentation](https://pub.dev/packages/freezed)
- [Injectable Documentation](https://pub.dev/packages/injectable)
