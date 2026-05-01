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
    final bytes = await file.readAsBytes();
    final mimeType = _guessMimeType(imagePath);

    try {
      final response = await _dio.post(
        ApiConstants.receiptExtractPath,
        data: {
          'image_base64': base64Encode(bytes),
          'mime_type': mimeType,
        },
      );
      return ReceiptAiResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? 'AI scan failed')
          : 'AI scan failed';
      throw Exception(message);
    }
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
