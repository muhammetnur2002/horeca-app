import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

bool localPathExists(String path) =>
    path.startsWith('blob:') || path.startsWith('data:') || path.startsWith('http');

Widget localImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  Widget? missing,
}) {
  if (!localPathExists(path)) return missing ?? const SizedBox.shrink();
  return Image.network(
    path,
    fit: fit,
    errorBuilder: (_, __, ___) => missing ?? const SizedBox.shrink(),
  );
}

VideoPlayerController openLocalVideo(String path) =>
    VideoPlayerController.networkUrl(Uri.parse(path));
