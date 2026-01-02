import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:p_tracker/features/example/data/models/example_model.dart';

/// Example local data source
abstract class ExampleLocalDataSource {
  Future<List<ExampleModel>> getCachedExamples();
  Future<void> cacheExamples(List<ExampleModel> examples);
  Future<void> clearCache();
}

/// Implementation of Example local data source
class ExampleLocalDataSourceImpl implements ExampleLocalDataSource {
  final SharedPreferences _prefs;
  static const String _cacheKey = 'cached_examples';

  ExampleLocalDataSourceImpl(this._prefs);

  @override
  Future<List<ExampleModel>> getCachedExamples() async {
    try {
      final jsonString = _prefs.getString(_cacheKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((json) => ExampleModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get cached examples: $e');
    }
  }

  @override
  Future<void> cacheExamples(List<ExampleModel> examples) async {
    try {
      final jsonList = examples.map((e) => e.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _prefs.setString(_cacheKey, jsonString);
    } catch (e) {
      throw Exception('Failed to cache examples: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _prefs.remove(_cacheKey);
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }
}
