// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

int _viewCounter = 0;

Widget buildStartupVideoPlayer(
  String assetPath,
  BorderRadius borderRadius, {
  required bool controls,
  required bool preview,
  required bool autoplay,
  required String objectFit,
}) {
  return _StartupVideoHtmlPlayer(
    assetPath: assetPath,
    borderRadius: borderRadius,
    controls: controls,
    preview: preview,
    autoplay: autoplay,
    objectFit: objectFit,
  );
}

class _StartupVideoHtmlPlayer extends StatefulWidget {
  final String assetPath;
  final BorderRadius borderRadius;
  final bool controls;
  final bool preview;
  final bool autoplay;
  final String objectFit;

  const _StartupVideoHtmlPlayer({
    required this.assetPath,
    required this.borderRadius,
    required this.controls,
    required this.preview,
    required this.autoplay,
    required this.objectFit,
  });

  @override
  State<_StartupVideoHtmlPlayer> createState() =>
      _StartupVideoHtmlPlayerState();
}

class _StartupVideoHtmlPlayerState extends State<_StartupVideoHtmlPlayer> {
  late final String _viewType;
  late final html.VideoElement _video;
  String? _objectUrl;

  @override
  void initState() {
    super.initState();
    _viewType = 'startup-video-${_viewCounter++}';

    _video = html.VideoElement()
      ..controls = widget.controls
      ..muted = widget.preview || widget.autoplay
      ..autoplay = widget.autoplay
      ..preload = 'auto'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#F7F8FB'
      ..style.border = '0'
      ..style.display = 'block';

    _video
      ..setAttribute('playsinline', 'true')
      ..setAttribute('controlsList', 'nodownload');
    _video.style
      ..setProperty('object-fit', widget.objectFit)
      ..setProperty('border-radius', '12px');

    if (widget.preview) {
      _video.style.setProperty('pointer-events', 'none');
    }

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (_) => _video,
    );

    _loadVideo();
  }

  @override
  void dispose() {
    final url = _objectUrl;
    if (url != null) {
      html.Url.revokeObjectUrl(url);
    }
    super.dispose();
  }

  Future<void> _loadVideo() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final blob = html.Blob([bytes], 'video/mp4');
      final url = html.Url.createObjectUrlFromBlob(blob);

      if (!mounted) {
        html.Url.revokeObjectUrl(url);
        return;
      }

      _objectUrl = url;
      if (widget.preview) {
        _showPreviewFrame();
      } else if (widget.autoplay) {
        _playWhenReady();
      }

      _video
        ..src = url
        ..load();
    } catch (_) {
      _video.style.backgroundColor = '#ECEFF1';
    }
  }

  void _showPreviewFrame() {
    _video.onLoadedMetadata.first.then((_) {
      final duration = _video.duration.isFinite ? _video.duration : 1.0;
      _video.currentTime = duration <= 1 ? duration / 2 : 1;
      _video.pause();
    });
  }

  void _playWhenReady() {
    _video.onCanPlay.first.then((_) {
      _video.play().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
