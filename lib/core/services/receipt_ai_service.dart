import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';

class ReceiptAiResult {
  final double? amount;
  final String? description;
  final String? date;
  final String? category;
  final String? type;

  const ReceiptAiResult({
    this.amount,
    this.description,
    this.date,
    this.category,
    this.type,
  });

  factory ReceiptAiResult.fromJson(Map<String, dynamic> json) {
    return ReceiptAiResult(
      amount: (json['amount'] as num?)?.toDouble(),
      description: json['description'] as String?,
      date: json['date'] as String?,
      category: json['category'] as String?,
      type: json['type'] as String?,
    );
  }
}

class ReceiptAiService {
  final Dio _dio = ApiClient().dio;

  Future<ReceiptAiResult> extractFromImage(String imagePath) async {
    final file = File(imagePath);
    final fileName = file.path.split('/').last;
    
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    try {
      final response = await _dio.post(
        ApiConstants.receiptExtractPath,
        data: formData,
      );

      final data = response.data;

      // If Dio already parsed it as a Map, use it directly
      if (data is Map) {
        return ReceiptAiResult.fromJson(Map<String, dynamic>.from(data));
      }

      // Otherwise try to extract JSON from the raw string
      final raw = data.toString().trim();
      final jsonStr = _extractJson(raw);
      if (jsonStr != null) {
        final parsed = jsonDecode(jsonStr);
        if (parsed is Map) {
          return ReceiptAiResult.fromJson(Map<String, dynamic>.from(parsed));
        }
      }

      throw Exception('AI response was not JSON: ${raw.length > 200 ? raw.substring(0, 200) : raw}');
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? 'AI scan failed')
          : 'AI scan failed';
      throw Exception(message);
    }
  }

  /// Tries to extract a JSON object from a string that may be wrapped
  /// in markdown code fences or contain surrounding text.
  String? _extractJson(String raw) {
    // Strip markdown code fences: ```json ... ``` or ``` ... ```
    final fencePattern = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final fenceMatch = fencePattern.firstMatch(raw);
    if (fenceMatch != null) {
      return fenceMatch.group(1)?.trim();
    }

    // Try to find a JSON object directly: first { to last }
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end > start) {
      return raw.substring(start, end + 1);
    }

    return null;
  }

  String _guessMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
