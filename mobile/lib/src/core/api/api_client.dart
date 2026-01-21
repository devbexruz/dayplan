import 'dart:io';
import 'package:dio/dio.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    String baseUrl = 'http://45.138.158.199:5050';
    try {
      if (Platform.isAndroid) {
        baseUrl = 'http://45.138.158.199:5050';
      }
    } catch (e) {
      // Platform check might fail on web, ignore
    }

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }
}
