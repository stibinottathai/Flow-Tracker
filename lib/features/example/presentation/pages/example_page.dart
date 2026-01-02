import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:p_tracker/features/example/presentation/providers/example_provider.dart';
import 'package:p_tracker/features/example/presentation/providers/example_state.dart';

/// Example page demonstrating clean architecture with Riverpod
class ExamplePage extends ConsumerWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exampleNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Example Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(exampleNotifierProvider.notifier).refreshExamples();
            },
          ),
        ],
      ),
      body: state.when(
        initial: () =>
            const Center(child: Text('Press the button to load examples')),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (examples) => ListView.builder(
          itemCount: examples.length,
          itemBuilder: (context, index) {
            final example = examples[index];
            return ListTile(
              title: Text(example.title),
              subtitle: Text(example.description),
              trailing: Text(example.createdAt.toString().split(' ')[0]),
            );
          },
        ),
        error: (message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Error: $message', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(exampleNotifierProvider.notifier).loadExamples();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(exampleNotifierProvider.notifier).loadExamples();
        },
        child: const Icon(Icons.download),
      ),
    );
  }
}
