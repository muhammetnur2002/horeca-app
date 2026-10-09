import 'package:dio/dio.dart';

Dio buildGigaChatDio() {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 90),
    sendTimeout: const Duration(seconds: 60),
  ));
}
