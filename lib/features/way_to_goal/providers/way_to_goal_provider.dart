import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/calculation_result.dart';

part 'way_to_goal_provider.g.dart';

@riverpod
Future<CalculationResult> calculationResult(CalculationResultRef ref) async {
  // Try to get existing result first
  try {
    final resp = await apiDio.get('/api/calculation/result');
    debugPrint('[way_to_goal] /api/calculation/result → ${resp.statusCode} ${resp.data}');
    if (resp.data != null) {
      return CalculationResult.fromJson(resp.data as Map<String, dynamic>);
    }
  } on DioException catch (e) {
    debugPrint('[way_to_goal] /api/calculation/result error: ${e.response?.statusCode} ${e.response?.data}');
    if (e.response?.statusCode != 404) rethrow;
  }

  // Fallback: load profile and calculate
  final profileResp = await apiDio.get('/api/profile');
  final profile = profileResp.data as Map<String, dynamic>;
  debugPrint('[way_to_goal] /api/profile → $profile');

  if (profile['age'] == null || profile['weight'] == null ||
      profile['height'] == null || profile['training_days'] == null) {
    debugPrint('[way_to_goal] Profile incomplete — cannot calculate');
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

  return CalculationResult.fromJson(calcResp.data as Map<String, dynamic>);
}
