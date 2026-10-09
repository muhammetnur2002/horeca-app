import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

Dio buildGigaChatDio() {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 90),
    sendTimeout: const Duration(seconds: 60),
  ));
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        return host == 'ngw.devices.sberbank.ru' || host == 'api.giga.chat';
      };
      return client;
    },
  );
  return dio;
}
