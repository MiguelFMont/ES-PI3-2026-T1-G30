// Autor: Gabriel Martins de Almeida
// RA: 25006162

import 'package:flutter/material.dart';

import 'startup_video_player_mobile.dart'
    if (dart.library.html) 'startup_video_player_web.dart' as impl;

class StartupVideoPlayer extends StatelessWidget {
  final String assetPath;
  final BorderRadius borderRadius;
  final bool controls;
  final bool preview;
  final bool autoplay;
  final String objectFit;

  const StartupVideoPlayer({
    super.key,
    required this.assetPath,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.controls = true,
    this.preview = false,
    this.autoplay = false,
    this.objectFit = 'contain',
  });

  @override
  Widget build(BuildContext context) {
    return impl.buildStartupVideoPlayer(
      assetPath,
      borderRadius,
      controls: controls,
      preview: preview,
      autoplay: autoplay,
      objectFit: objectFit,
    );
  }
}
