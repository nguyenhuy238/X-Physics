import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api_client.dart';

class AdminProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _loading = false;
  String? _error;
  List<dynamic> _lastUsers = const <dynamic>[];
  List<dynamic> _lastChapters = const <dynamic>[];
  List<dynamic> _lastLessons = const <dynamic>[];
  List<dynamic> _lastQuestions = const <dynamic>[];
  Map<String, dynamic>? _lastStatistics;

  int _usersPage = 1;
  int _usersLimit = 20;
  int? _usersTotal;

  bool get loading => _loading;
  String? get error => _error;
  List<dynamic> get lastUsers => _lastUsers;
  List<dynamic> get lastChapters => _lastChapters;
  List<dynamic> get lastLessons => _lastLessons;
  List<dynamic> get lastQuestions => _lastQuestions;
  Map<String, dynamic>? get lastStatistics => _lastStatistics;

  int get usersPage => _usersPage;
  int get usersLimit => _usersLimit;
  int? get usersTotal => _usersTotal;
  int get usersTotalPages => _usersTotal == null ? 1 : (_usersTotal! / _usersLimit).ceil();

  Future<void> setUsersPage(int page) async {
    _usersPage = page;
    await fetchUsers(page: page);
  }

  Future<void> setUsersLimit(int limit) async {
    _usersLimit = limit;
    _usersPage = 1;
    await fetchUsers(limit: limit);
  }

  Future<void> clearError() async {
    _error = null;
    notifyListeners();
  }

  Future<T> _withLoading<T>(Future<T> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      return await action();
    } on Exception catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> fetchUsers({
    String? search,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) {
    return _withLoading(() async {
      final data = await _api.get('admin/users', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
        'page': page,
        'limit': limit,
      });
      _lastUsers = data['items'] as List<dynamic>;
      return _lastUsers;
    });
  }

  Future<Map<String, dynamic>> fetchStatistics() {
    return _withLoading(() async {
      final data = await _api.get('admin/statistics');
      _lastStatistics = data;
      return _lastStatistics!;
    });
  }

  Future<List<dynamic>> fetchChapters() {
    return _withLoading(() async {
      final data = await _api.get('admin/chapters');
      _lastChapters = data as List<dynamic>;
      return _lastChapters;
    });
  }

  Future<List<dynamic>> fetchLessons() {
    return _withLoading(() async {
      final data = await _api.get('admin/lessons');
      _lastLessons = data as List<dynamic>;
      return _lastLessons;
    });
  }

  Future<List<dynamic>> fetchQuestions() {
    return _withLoading(() async {
      final data = await _api.get('admin/questions');
      _lastQuestions = data as List<dynamic>;
      return _lastQuestions;
    });
  }
}
