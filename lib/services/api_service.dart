/// FraudX Analyst - API Service
/// ===============================
/// Handles all HTTP communication with the FastAPI backend

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';

class ApiService {
    // ── Delete History Item ──────────────────────────────────────────────────
    static Future<void> deleteHistoryItem(String simulationId) async {
      try {
        final response = await http.delete(
          Uri.parse('${ApiConfig.history}/$simulationId'),
        ).timeout(ApiConfig.timeout);
        if (response.statusCode != 200) {
          throw ApiException(
            'Failed to delete history item: ${response.statusCode}',
            response.body,
          );
        }
      } catch (e) {
        throw ApiException('Network error', e.toString());
      }
    }
  // ── Predict ────────────────────────────────────────────────────────────────
  static Future<PredictResponse> predict(PredictRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.predict),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return PredictResponse.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(
          'Prediction failed: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw ApiException('Network error', e.toString());
    }
  }

  // ── Get Models ─────────────────────────────────────────────────────────────
  static Future<List<ModelMetrics>> getModels() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.models),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['models'] as List)
            .map((m) => ModelMetrics.fromJson(m))
            .toList();
      } else {
        throw ApiException(
          'Failed to load models: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw ApiException('Network error', e.toString());
    }
  }

  // ── Get Models Comparison ──────────────────────────────────────────────────
  static Future<ModelsComparisonData> getModelsComparison() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.modelsCompare),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return ModelsComparisonData.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(
          'Failed to load comparison: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw ApiException('Network error', e.toString());
    }
  }

  // ── Get History ────────────────────────────────────────────────────────────
  static Future<List<HistoryItem>> getHistory({
    required String deviceId,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.history}?device_id=$deviceId&limit=$limit'),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['history'] as List)
            .map((h) => HistoryItem.fromJson(h))
            .toList();
      } else {
        throw ApiException(
          'Failed to load history: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw ApiException('Network error', e.toString());
    }
  }

  // ── Clear History ──────────────────────────────────────────────────────────
  static Future<void> clearHistory(String deviceId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.history}?device_id=$deviceId'),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to clear history: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw ApiException('Network error', e.toString());
    }
  }

  // ── Chat ───────────────────────────────────────────────────────────────────
  static Future<ChatResponse> chat(ChatRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.chat),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return ChatResponse.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(
          'Chat failed: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw ApiException('Network error', e.toString());
    }
  }

  // ── Get Chat Suggestions ───────────────────────────────────────────────────
  static Future<List<String>> getChatSuggestions() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.chatSuggestions),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['suggestions']);
      } else {
        // Return fallback suggestions if endpoint fails
        return [
          'What is credit card fraud?',
          'How does XGBoost detect fraud?',
          'What does SHAP mean?',
          'Explain my last prediction',
        ];
      }
    } catch (e) {
      return [
        'What is credit card fraud?',
        'How does XGBoost detect fraud?',
        'What does SHAP mean?',
        'Explain my last prediction',
      ];
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  API Exception
// ══════════════════════════════════════════════════════════════════════════════

class ApiException implements Exception {
  final String message;
  final String? details;

  ApiException(this.message, [this.details]);

  @override
  String toString() => details != null ? '$message: $details' : message;
}
