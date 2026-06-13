// lib/core/widgets/in_app_video_player.dart
//
// One reusable player that plays a video INSIDE the app:
//   • YouTube links            → youtube_player_flutter (embedded, never leaves app)
//   • Direct files (.mp4/.mov…) → video_player (admin local uploads)
//
// Run `flutter pub get` after pulling — adds video_player + youtube_player_flutter.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../theme/app_colors.dart';

class InAppVideoPlayer extends StatefulWidget {
  final String url;
  final bool autoPlay;
  final BorderRadius? borderRadius;

  const InAppVideoPlayer({
    super.key,
    required this.url,
    this.autoPlay = false,
    this.borderRadius,
  });

  /// YouTube video id (or null if not a YouTube URL).
  static String? youtubeId(String url) => YoutubePlayer.convertUrlToId(url);

  static bool isYoutube(String url) => youtubeId(url) != null;

  /// A direct, in-app-playable video file (admin upload / mp4 link).
  static bool isDirectVideo(String url) {
    final u = url.toLowerCase().split('?').first;
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.m4v') ||
        u.endsWith('.webm') ||
        u.endsWith('.m3u8');
  }

  /// Whether this URL can be played inline (vs. needing an external/in-app browser).
  static bool canPlayInline(String url) =>
      url.isNotEmpty && (isYoutube(url) || isDirectVideo(url));

  @override
  State<InAppVideoPlayer> createState() => _InAppVideoPlayerState();
}

class _InAppVideoPlayerState extends State<InAppVideoPlayer> {
  YoutubePlayerController? _yt;
  VideoPlayerController? _vp;
  bool _vpReady = false;
  bool _showControls = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final id = YoutubePlayer.convertUrlToId(widget.url);
    if (id != null) {
      _yt = YoutubePlayerController(
        initialVideoId: id,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
          mute: false,
          enableCaption: false,
        ),
      );
    } else if (widget.url.isNotEmpty) {
      _vp = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _vp!.initialize().then((_) {
        if (!mounted) return;
        setState(() => _vpReady = true);
        if (widget.autoPlay) _vp!.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _error = 'Could not load this video.');
      });
    }
  }

  @override
  void dispose() {
    _yt?.dispose();
    _vp?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    Widget child;
    if (_yt != null) {
      child = YoutubePlayer(
        controller: _yt!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.neonCyan,
        progressColors: const ProgressBarColors(
          playedColor: AppColors.neonCyan,
          handleColor: AppColors.neonCyan,
        ),
      );
    } else if (_error != null) {
      child = _box(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.orange, size: 36),
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
    } else if (_vp != null && _vpReady) {
      final ar = _vp!.value.aspectRatio == 0 ? 16 / 9 : _vp!.value.aspectRatio;
      child = AspectRatio(
        aspectRatio: ar,
        child: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_vp!),
              if (_showControls)
                Container(color: Colors.black26),
              if (_showControls)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _vp!.value.isPlaying ? _vp!.pause() : _vp!.play();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _vp!.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.darkBg,
                      size: 34,
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  _vp!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.neonCyan,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      child = _box(
        child: const CircularProgressIndicator(color: AppColors.neonCyan),
      );
    }

    return ClipRRect(borderRadius: radius, child: child);
  }

  Widget _box({required Widget child}) => AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppColors.darkCard,
          alignment: Alignment.center,
          child: child,
        ),
      );
}
