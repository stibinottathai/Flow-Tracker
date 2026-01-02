import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p_tracker/core/constants/app_constants.dart';
import 'package:p_tracker/core/network/network_info.dart';
import 'package:p_tracker/features/example/data/datasources/example_local_datasource.dart';
import 'package:p_tracker/features/example/data/datasources/example_remote_datasource.dart';
import 'package:p_tracker/features/example/data/repositories/example_repository_impl.dart';
import 'package:p_tracker/features/example/domain/repositories/example_repository.dart';
import 'package:p_tracker/features/example/domain/usecases/get_examples.dart';
import 'package:p_tracker/core/services/notification_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // External dependencies
  await _registerExternalDependencies();

  // Services
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());

  // Data sources
  _registerDataSources();

  // Repositories
  _registerRepositories();

  // Use cases
  _registerUseCases();
}

Future<void> _registerExternalDependencies() async {
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Dio
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  getIt.registerLazySingleton<Dio>(() => dio);

  // Connectivity
  final connectivity = Connectivity();
  getIt.registerLazySingleton<Connectivity>(() => connectivity);

  // NetworkInfo
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<Connectivity>()),
  );
}

void _registerDataSources() {
  // Example data sources
  getIt.registerLazySingleton<ExampleRemoteDataSource>(
    () => ExampleRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<ExampleLocalDataSource>(
    () => ExampleLocalDataSourceImpl(getIt<SharedPreferences>()),
  );
}

void _registerRepositories() {
  // Example repository
  getIt.registerLazySingleton<ExampleRepository>(
    () => ExampleRepositoryImpl(
      getIt<ExampleRemoteDataSource>(),
      getIt<ExampleLocalDataSource>(),
      getIt<NetworkInfo>(),
    ),
  );
}

void _registerUseCases() {
  // Example use cases
  getIt.registerLazySingleton(() => GetExamples(getIt<ExampleRepository>()));
}
