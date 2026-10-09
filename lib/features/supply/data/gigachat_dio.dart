import 'package:dio/dio.dart';
import 'package:horeca_app/features/supply/data/gigachat_dio_io.dart'
    if (dart.library.html) 'package:horeca_app/features/supply/data/gigachat_dio_web.dart'
    as platform;

Dio buildGigaChatDio() => platform.buildGigaChatDio();
