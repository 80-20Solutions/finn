import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/wizard_state_model.dart';

/// Local data source for caching wizard draft state using Hive.
/// Feature: 001-group-budget-wizard, Task: T014
abstract class WizardLocalDataSource {
  /// Get cached wizard draft if available and not expired.
  ///
  /// Returns null if no draft exists or cache is expired (>24 hours).
  Future<WizardStateModel?> getDraft(String groupId);

  /// Cache wizard draft locally.
  ///
  /// Saves wizard state to Hive with current timestamp.
  /// Cache expires after 24 hours (see research.md Decision 1).
  Future<void> cacheDraft(WizardStateModel draft);

  /// Clear cached wizard draft.
  ///
  /// Removes draft and timestamp from Hive storage.
  Future<void> clearCache(String groupId);
}

/// Implementation of [WizardLocalDataSource] using Hive.
class WizardLocalDataSourceImpl implements WizardLocalDataSource {
  WizardLocalDataSourceImpl({
    required Box<String> cacheBox,
  }) : _cacheBox = cacheBox;

  final Box<String> _cacheBox;

  static const _cacheExpiryHours = 24; // Cache expires after 24 hours

  String _getCacheKey(String groupId) => 'wizard_draft_$groupId';

  String _getTimestampKey(String cacheKey) => '${cacheKey}_timestamp';

  @override
  Future<WizardStateModel?> getDraft(String groupId) async {
    try {
      final cacheKey = _getCacheKey(groupId);
      final timestampKey = _getTimestampKey(cacheKey);

      final cachedData = _cacheBox.get(cacheKey);
      final cachedTimestamp = _cacheBox.get(timestampKey);

      if (cachedData == null || cachedTimestamp == null) {
        return null;
      }

      // Check if cache has expired
      final timestamp = DateTime.parse(cachedTimestamp);
      final now = DateTime.now();
      if (now.difference(timestamp).inHours >= _cacheExpiryHours) {
        // Cache expired, remove it
        await _cacheBox.delete(cacheKey);
        await _cacheBox.delete(timestampKey);
        return null;
      }

      final json = jsonDecode(cachedData) as Map<String, dynamic>;
      return WizardStateModel.fromJson(json);
    } catch (e) {
      // If there's any error reading cache, return null
      return null;
    }
  }

  @override
  Future<void> cacheDraft(WizardStateModel draft) async {
    try {
      final cacheKey = _getCacheKey(draft.groupId);
      final timestampKey = _getTimestampKey(cacheKey);

      final json = draft.toJson();
      await _cacheBox.put(cacheKey, jsonEncode(json));
      await _cacheBox.put(timestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Silently fail on cache errors
    }
  }

  @override
  Future<void> clearCache(String groupId) async {
    try {
      final cacheKey = _getCacheKey(groupId);
      final timestampKey = _getTimestampKey(cacheKey);

      await _cacheBox.delete(cacheKey);
      await _cacheBox.delete(timestampKey);
    } catch (e) {
      // Silently fail on cache errors
    }
  }
}
