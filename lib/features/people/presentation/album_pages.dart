import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:horeca_app/core/local_media.dart';
import 'package:horeca_app/features/people/presentation/people_style.dart';

class AlbumPhotoPage extends StatelessWidget {
  final String path;
  final VoidCallback onDelete;

  const AlbumPhotoPage({required this.path, required this.onDelete, super.key});

  @override
  Widget build(BuildContext context) {
    final exists = localPathExists(path);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Фото'),
        actions: [
          IconButton(
            tooltip: 'Убрать из альбома',
            onPressed: () async {
              final ok = await askPeopleConfirm(
                context,
                title: 'Убрать фото?',
                body: 'Снимок пропадёт из альбома на этом телефоне.',
                confirm: 'Убрать',
              );
              if (!ok || !context.mounted) return;
              onDelete();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Center(
        child: exists
            ? InteractiveViewer(
                child: localImage(
                  path,
                  fit: BoxFit.contain,
                  missing: const Text('Не удалось показать фото', style: TextStyle(color: Colors.white)),
                ),
              )
            : const Text('Файл не найден на телефоне', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class AlbumVideoPage extends StatefulWidget {
  final String path;
  final VoidCallback onDelete;

  const AlbumVideoPage({required this.path, required this.onDelete, super.key});

  @override
  State<AlbumVideoPage> createState() => _AlbumVideoPageState();
}

class _AlbumVideoPageState extends State<AlbumVideoPage> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!localPathExists(widget.path)) {
      _error = 'Файл не найден на телефоне';
      return;
    }
    final controller = openLocalVideo(widget.path);
    _controller = controller;
    _start(controller);
  }

  Future<void> _start(VideoPlayerController controller) async {
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
      await controller.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось открыть видео');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Видео'),
        actions: [
          IconButton(
            tooltip: 'Убрать из альбома',
            onPressed: () async {
              final ok = await askPeopleConfirm(
                context,
                title: 'Убрать видео?',
                body: 'Ролик пропадёт из альбома на этом телефоне.',
                confirm: 'Убрать',
              );
              if (!ok || !context.mounted) return;
              widget.onDelete();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Center(
        child: _error != null
            ? Text(_error!, style: const TextStyle(color: Colors.white))
            : !ready
                ? const CircularProgressIndicator(color: Colors.white)
                : GestureDetector(
                    onTap: () {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                      setState(() {});
                    },
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio == 0
                          ? 9 / 16
                          : controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  ),
      ),
    );
  }
}
