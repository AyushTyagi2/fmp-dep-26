import 'package:dio/dio.dart';
import 'package:fmp_app/app_session.dart';

class ApiClient {
  late final Dio dio;
  static const String _defaultBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5153',); 


  ApiClient() {
    
    dio = Dio(
      BaseOptions(
        baseUrl: "http://localhost:5153",
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          "Content-Type": "application/json",
        },
      ),
    );


    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler){
          final token = AppSession.token;
          if(token != null){
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if(e.response?.statusCode == 401){
            AppSession.clear();
          }
          return handler.next(e);
        },
      ),
    );
  }
}
