import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

bool localPathExists(String path) {
  try {
    return File(path).existsSync();
  } catch (_) {
    return false;
  }
}

Widget localImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  Widget? missing,
}) {
  final file = File(path);
  if (!file.existsSync()) return missing ?? const SizedBox.shrink();
  return Image.file(
    file,
    fit: fit,
    errorBuilder: (_, __, ___) => missing ?? const SizedBox.shrink(),
  );
}

VideoPlayerController openLocalVideo(String path) =>
    VideoPlayerController.file(File(path));
