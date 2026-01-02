import 'package:p_tracker/features/example/domain/entities/example_entity.dart';

/// Example state sealed class
sealed class ExampleState {
  const ExampleState();
}

class ExampleInitial extends ExampleState {
  const ExampleInitial();
}

class ExampleLoading extends ExampleState {
  const ExampleLoading();
}

class ExampleLoaded extends ExampleState {
  final List<ExampleEntity> examples;
  const ExampleLoaded(this.examples);
}

class ExampleError extends ExampleState {
  final String message;
  const ExampleError(this.message);
}

/// Extension for pattern matching on ExampleState
extension ExampleStateX on ExampleState {
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(List<ExampleEntity> examples) loaded,
    required T Function(String message) error,
  }) {
    return switch (this) {
      ExampleInitial() => initial(),
      ExampleLoading() => loading(),
      ExampleLoaded(examples: final examples) => loaded(examples),
      ExampleError(message: final message) => error(message),
    };
  }
}
