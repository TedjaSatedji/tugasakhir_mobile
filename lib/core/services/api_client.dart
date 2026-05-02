import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService().getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Handle global 401 unauthorized
            // We can emit an event or call a callback to force logout
            // For now we'll just delete the token so the next check fails
            await StorageService().deleteToken();
            
            // If we have an onAuthFailed callback, call it
            if (onAuthFailed != null) {
              onAuthFailed!();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  late final Dio _dio;
  Dio get dio => _dio;
  
  // Callback to handle 401s globally
  static void Function()? onAuthFailed;
}
