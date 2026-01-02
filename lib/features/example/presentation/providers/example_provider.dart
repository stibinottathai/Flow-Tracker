import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:p_tracker/core/di/injection.dart';
import 'package:p_tracker/features/example/domain/usecases/get_examples.dart';
import 'package:p_tracker/features/example/presentation/providers/example_state.dart';

/// Example provider
final exampleNotifierProvider = NotifierProvider<ExampleNotifier, ExampleState>(
  ExampleNotifier.new,
);

/// Example notifier using Riverpod
class ExampleNotifier extends Notifier<ExampleState> {
  late final GetExamples _getExamples;

  @override
  ExampleState build() {
    _getExamples = getIt<GetExamples>();
    return const ExampleInitial();
  }

  /// Load examples
  Future<void> loadExamples() async {
    state = const ExampleLoading();

    final result = await _getExamples();

    result.fold(
      (failure) => state = ExampleError(failure.toString()),
      (examples) => state = ExampleLoaded(examples),
    );
  }

  /// Refresh examples
  Future<void> refreshExamples() async {
    await loadExamples();
  }
}
