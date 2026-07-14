import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../shared/models/x_models.dart';

enum OfflineLessonFreshness { same, serverNewer, localNewer, unknown }

class OfflineLessonModel {
  const OfflineLessonModel({
    required this.lessonId,
    required this.title,
    required this.downloadedAt,
  });

  final String lessonId;
  final String title;
  final DateTime downloadedAt;
}

class OfflineLessonMetadata {
  const OfflineLessonMetadata({
    required this.userId,
    required this.lessonId,
    required this.contentFingerprint,
    required this.downloadedAt,
    this.serverVersion,
    this.serverUpdatedAt,
    this.lastCheckedAt,
    this.updateAvailable = false,
  });

  final String userId;
  final String lessonId;
  final int? serverVersion;
  final String? serverUpdatedAt;
  final String contentFingerprint;
  final DateTime downloadedAt;
  final DateTime? lastCheckedAt;
  final bool updateAvailable;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'lessonId': lessonId,
    'serverVersion': serverVersion,
    'serverUpdatedAt': serverUpdatedAt,
    'contentFingerprint': contentFingerprint,
    'downloadedAt': downloadedAt.toUtc().toIso8601String(),
    'lastCheckedAt': lastCheckedAt?.toUtc().toIso8601String(),
    'updateAvailable': updateAvailable,
  };

  factory OfflineLessonMetadata.fromJson(
    Map<dynamic, dynamic> json, {
    required String fallbackUserId,
    required String fallbackLessonId,
    required Lesson lesson,
  }) {
    final normalized = normalizeJsonMap(json);
    return OfflineLessonMetadata(
      userId: _readString(normalized['userId']) ?? fallbackUserId,
      lessonId: _readString(normalized['lessonId']) ?? fallbackLessonId,
      serverVersion: _readInt(normalized['serverVersion']),
      serverUpdatedAt: _readString(normalized['serverUpdatedAt']),
      contentFingerprint:
          _readString(normalized['contentFingerprint']) ??
          OfflineLessonVersioning.fingerprintForLesson(lesson),
      downloadedAt:
          _readDate(normalized['downloadedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastCheckedAt: _readDate(normalized['lastCheckedAt']),
      updateAvailable: normalized['updateAvailable'] == true,
    );
  }

  factory OfflineLessonMetadata.fromLesson({
    required String userId,
    required Lesson lesson,
    DateTime? downloadedAt,
    DateTime? lastCheckedAt,
    bool updateAvailable = false,
  }) => OfflineLessonMetadata(
    userId: userId.trim(),
    lessonId: lesson.id.trim(),
    serverUpdatedAt: lesson.updatedAt,
    contentFingerprint: OfflineLessonVersioning.fingerprintForLesson(lesson),
    downloadedAt: (downloadedAt ?? DateTime.now()).toUtc(),
    lastCheckedAt: lastCheckedAt?.toUtc(),
    updateAvailable: updateAvailable,
  );

  OfflineLessonMetadata copyWith({
    int? serverVersion,
    String? serverUpdatedAt,
    String? contentFingerprint,
    DateTime? downloadedAt,
    DateTime? lastCheckedAt,
    bool? updateAvailable,
  }) => OfflineLessonMetadata(
    userId: userId,
    lessonId: lessonId,
    serverVersion: serverVersion ?? this.serverVersion,
    serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    contentFingerprint: contentFingerprint ?? this.contentFingerprint,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    updateAvailable: updateAvailable ?? this.updateAvailable,
  );
}

class OfflineLessonSnapshot {
  const OfflineLessonSnapshot({required this.lesson, required this.metadata});

  final Lesson lesson;
  final OfflineLessonMetadata metadata;

  bool get updateAvailable => metadata.updateAvailable;

  Map<String, dynamic> toCacheMap() => {
    'userId': metadata.userId,
    'lessonId': metadata.lessonId,
    'lesson': lesson.toJson(),
    'metadata': metadata.toJson(),
  };

  factory OfflineLessonSnapshot.fromCacheMap(Map<dynamic, dynamic> source) {
    final normalized = normalizeJsonMap(source);
    final lessonJson = normalized['lesson'];
    if (lessonJson is! Map) {
      throw const FormatException('Offline lesson payload is missing lesson');
    }
    final lesson = Lesson.fromJson(normalizeJsonMap(lessonJson));
    final userId = _readString(normalized['userId']) ?? '';
    final lessonId = _readString(normalized['lessonId']) ?? lesson.id;
    final metadataJson = normalized['metadata'];
    final metadata = metadataJson is Map
        ? OfflineLessonMetadata.fromJson(
            metadataJson,
            fallbackUserId: userId,
            fallbackLessonId: lessonId,
            lesson: lesson,
          )
        : OfflineLessonMetadata.fromLesson(
            userId: userId,
            lesson: lesson,
            downloadedAt: _readDate(normalized['downloadedAt']),
          );
    return OfflineLessonSnapshot(lesson: lesson, metadata: metadata);
  }
}

class OfflineLessonVersioning {
  const OfflineLessonVersioning._();

  static String fingerprintForLesson(Lesson lesson) {
    final content = <String, dynamic>{
      'title': lesson.title,
      'content': lesson.content,
      'formulaLatex': lesson.formulaLatex,
      'simulation': lesson.simulation.toJson(),
      'questions': lesson.questions
          .map((question) => question.toJson())
          .toList(),
    };
    final canonicalJson = jsonEncode(_canonicalize(content));
    return sha256.convert(utf8.encode(canonicalJson)).toString();
  }

  static OfflineLessonFreshness compare({
    int? localVersion,
    int? serverVersion,
    String? localUpdatedAt,
    String? serverUpdatedAt,
    String? localFingerprint,
    String? serverFingerprint,
  }) {
    if (localVersion != null && serverVersion != null) {
      if (serverVersion > localVersion) {
        return OfflineLessonFreshness.serverNewer;
      }
      if (serverVersion < localVersion) {
        return OfflineLessonFreshness.localNewer;
      }
      return OfflineLessonFreshness.same;
    }

    if (_hasText(localUpdatedAt) && _hasText(serverUpdatedAt)) {
      final localDate = DateTime.tryParse(localUpdatedAt!)?.toUtc();
      final serverDate = DateTime.tryParse(serverUpdatedAt!)?.toUtc();
      if (localDate == null || serverDate == null) {
        return OfflineLessonFreshness.unknown;
      }
      if (serverDate.isAfter(localDate)) {
        return OfflineLessonFreshness.serverNewer;
      }
      if (serverDate.isBefore(localDate)) {
        return OfflineLessonFreshness.localNewer;
      }
      return OfflineLessonFreshness.same;
    }

    if (_hasText(localFingerprint) && _hasText(serverFingerprint)) {
      return localFingerprint == serverFingerprint
          ? OfflineLessonFreshness.same
          : OfflineLessonFreshness.serverNewer;
    }

    return OfflineLessonFreshness.unknown;
  }

  static OfflineLessonMetadata metadataForDownloadedLesson({
    required String userId,
    required Lesson lesson,
    DateTime? downloadedAt,
    DateTime? lastCheckedAt,
    bool updateAvailable = false,
  }) => OfflineLessonMetadata.fromLesson(
    userId: userId,
    lesson: lesson,
    downloadedAt: downloadedAt,
    lastCheckedAt: lastCheckedAt,
    updateAvailable: updateAvailable,
  );

  static dynamic _canonicalize(dynamic value) {
    if (value is Map) {
      final normalized = normalizeJsonMap(value);
      final sorted = <String, dynamic>{};
      final keys = normalized.keys.toList()..sort();
      for (final key in keys) {
        sorted[key] = _canonicalize(normalized[key]);
      }
      return sorted;
    }
    if (value is Iterable) {
      return value.map(_canonicalize).toList(growable: false);
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    return value;
  }

  static bool _hasText(String? value) => value != null && value.isNotEmpty;
}

Map<String, dynamic> normalizeJsonMap(Map<dynamic, dynamic> source) {
  final normalized = <String, dynamic>{};
  source.forEach((key, value) {
    normalized[key.toString()] = _normalizeJsonValue(value);
  });
  return normalized;
}

dynamic _normalizeJsonValue(dynamic value) {
  if (value is Map) {
    return normalizeJsonMap(value);
  }
  if (value is Iterable) {
    return value.map(_normalizeJsonValue).toList(growable: false);
  }
  return value;
}

String? _readString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _readDate(Object? value) {
  if (value is DateTime) return value.toUtc();
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}
