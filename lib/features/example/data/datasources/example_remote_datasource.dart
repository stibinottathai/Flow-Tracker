import 'package:dio/dio.dart';
import 'package:p_tracker/features/example/data/models/example_model.dart';

/// Example remote data source
abstract class ExampleRemoteDataSource {
  Future<List<ExampleModel>> getExamples();
  Future<ExampleModel> getExampleById(String id);
  Future<void> createExample(ExampleModel model);
  Future<void> updateExample(ExampleModel model);
  Future<void> deleteExample(String id);
}

/// Implementation of Example remote data source
class ExampleRemoteDataSourceImpl implements ExampleRemoteDataSource {
  final Dio _dio;

  ExampleRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ExampleModel>> getExamples() async {
    try {
      final response = await _dio.get('/examples');
      final List<dynamic> data = response.data;
      return data.map((json) => ExampleModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get examples: $e');
    }
  }

  @override
  Future<ExampleModel> getExampleById(String id) async {
    try {
      final response = await _dio.get('/examples/$id');
      return ExampleModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get example: $e');
    }
  }

  @override
  Future<void> createExample(ExampleModel model) async {
    try {
      await _dio.post('/examples', data: model.toJson());
    } catch (e) {
      throw Exception('Failed to create example: $e');
    }
  }

  @override
  Future<void> updateExample(ExampleModel model) async {
    try {
      await _dio.put('/examples/${model.id}', data: model.toJson());
    } catch (e) {
      throw Exception('Failed to update example: $e');
    }
  }

  @override
  Future<void> deleteExample(String id) async {
    try {
      await _dio.delete('/examples/$id');
    } catch (e) {
      throw Exception('Failed to delete example: $e');
    }
  }
}
