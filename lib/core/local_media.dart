import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:horeca_app/core/local_media_io.dart'
    if (dart.library.html) 'package:horeca_app/core/local_media_web.dart' as media;

bool localPathExists(String path) => media.localPathExists(path);

Widget localImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  Widget? missing,
}) =>
    media.localImage(path, fit: fit, missing: missing);

VideoPlayerController openLocalVideo(String path) => media.openLocalVideo(path);
