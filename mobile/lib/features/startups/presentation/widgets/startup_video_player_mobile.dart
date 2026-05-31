// Autor: Gabriel Martins de Almeida
// RA: 25006162

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';

Widget buildStartupVideoPlayer(
  String assetPath,
  BorderRadius borderRadius, {
  required bool controls,
  required bool preview,
  required bool autoplay,
  required String objectFit,
}) {
  return _MobileVideoPlayer(
    assetPath: assetPath,
    borderRadius: borderRadius,
    controls: controls,
    preview: preview,
    autoplay: autoplay,
    objectFit: objectFit,
  );
}

class _MobileVideoPlayer extends StatefulWidget {
  final String assetPath;
  final BorderRadius borderRadius;
  final bool controls;
  final bool preview;
  final bool autoplay;
  final String objectFit;

  const _MobileVideoPlayer({
    required this.assetPath,
    required this.borderRadius,
    required this.controls,
    required this.preview,
    required this.autoplay,
    required this.objectFit,
  });

  @override
  State<_MobileVideoPlayer> createState() => _MobileVideoPlayerState();
}

class _MobileVideoPlayerState extends State<_MobileVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        if (widget.autoplay) {
          _controller
            ..setLooping(true)
            ..play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  BoxFit get _boxFit =>
      widget.objectFit == 'cover' ? BoxFit.cover : BoxFit.contain;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: ColoredBox(
        color: const Color(0xFFF7F8FB),
        child: _initialized ? _buildPlayer() : _buildLoading(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildPlayer() {
    final videoWidget = FittedBox(
      fit: _boxFit,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );

    if (!widget.controls || widget.preview || widget.autoplay) {
      return videoWidget;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          videoWidget,
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller,
            builder: (_, value, _) {
              if (value.isPlaying) return const SizedBox.shrink();
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
