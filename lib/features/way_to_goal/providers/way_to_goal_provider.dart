import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/calculation_result.dart';

part 'way_to_goal_provider.g.dart';

const _cacheKey = 'calculation_result_cache';

Future<void> _saveCache(CalculationResult result) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(result.toJson()));
  } catch (e) {
    debugPrint('[way_to_goal] cache save failed: $e');
  }
}

Future<CalculationResult?> _loadCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    return CalculationResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (e) {
    debugPrint('[way_to_goal] cache load failed: $e');
    return null;
  }
}

@riverpod
Future<CalculationResult> calculationResult(CalculationResultRef ref) async {
  // Try API first
  try {
    final resp = await apiDio.get('/api/calculation/result');
    debugPrint('[way_to_goal] /api/calculation/result → ${resp.statusCode}');
    if (resp.data != null) {
      final result = CalculationResult.fromJson(resp.data as Map<String, dynamic>);
      await _saveCache(result);
      return result;
    }
  } on DioException catch (e) {
    debugPrint('[way_to_goal] /api/calculation/result error: ${e.response?.statusCode}');
    if (e.response?.statusCode != 404) {
      // Network error — try cache
      final cached = await _loadCache();
      if (cached != null) {
        debugPrint('[way_to_goal] returning cached result');
        return cached;
      }
      rethrow;
    }
  }

  // Fallback: load profile and calculate
  try {
    final profileResp = await apiDio.get('/api/profile');
    final profile = profileResp.data as Map<String, dynamic>;
    debugPrint('[way_to_goal] /api/profile → $profile');

    if (profile['age'] == null || profile['weight'] == null ||
        profile['height'] == null || profile['training_days'] == null) {
      // Try cache before throwing
      final cached = await _loadCache();
      if (cached != null) return cached;
      throw Exception('Профиль не заполнен. Пройдите онбординг повторно.');
    }

    final calcResp = await apiDio.post('/api/calculate', data: {
      'age': profile['age'],
      'weight': profile['weight'],
      'height': profile['height'],
      'training_days': profile['training_days'],
      if (profile['deficit_mode'] != null) 'deficit_mode': profile['deficit_mode'],
    });
    debugPrint('[way_to_goal] /api/calculate → ${calcResp.data}');

    final result = CalculationResult.fromJson(calcResp.data as Map<String, dynamic>);
    await _saveCache(result);
    return result;
  } catch (e) {
    // Last resort: cache
    final cached = await _loadCache();
    if (cached != null) return cached;
    rethrow;
  }
}
