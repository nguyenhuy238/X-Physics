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

  int _usersPage = 1;
  int _usersLimit = 20;
  int? _usersTotal;

  bool get loading => _loading;
  String? get error => _error;
  List<dynamic> get lastUsers => _lastUsers;
  List<dynamic> get lastChapters => _lastChapters;
  List<dynamic> get lastLessons => _lastLessons;
  List<dynamic> get lastQuestions => _lastQuestions;

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

  Future<List<dynamic>> fetchChapters() {
    return _withLoading(() async {
      final data = await _api.getList('admin/chapters');
      _lastChapters = data;
      return _lastChapters;
    });
  }

  Future<List<dynamic>> fetchLessons({String? chapterId}) {
    return _withLoading(() async {
      final data = await _api.getList(
        'admin/lessons',
        queryParameters: chapterId != null ? {'chapterId': chapterId} : null,
      );
      _lastLessons = data;
      return _lastLessons;
    });
  }

  Future<List<dynamic>> fetchQuestions({String? lessonId}) {
    return _withLoading(() async {
      final data = await _api.getList(
        'admin/questions',
        queryParameters: lessonId != null ? {'lessonId': lessonId} : null,
      );
      _lastQuestions = data;
      return _lastQuestions;
    });
  }
}
