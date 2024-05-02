import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:soda/controllers/content_controller.dart';
import 'package:window_size/window_size.dart';

class MainVideoPlayer extends ConsumerStatefulWidget {
  final String url;
  const MainVideoPlayer(this.url, {super.key});

  @override
  ConsumerState<MainVideoPlayer> createState() => _MainVideoPlayerState();
}

class _MainVideoPlayerState extends ConsumerState<MainVideoPlayer> {
  bool showVideoControl = false, isFullScreen = false;
  Timer? _timer;
  final Duration _duration = const Duration(milliseconds: 550); // Set the duration for pointer stop
  late final videoPlayerHeight = (MediaQuery.of(context).size.height) / 2, videoPlayerWidth = (MediaQuery.of(context).size.width) / 2;
  late final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    setWindowTitle(Uri.decodeComponent(widget.url));
    String basicAuth = 'Basic ${base64.encode(utf8.encode('${ref.read(httpServerStateProvider).username}:${ref.read(httpServerStateProvider).password}'))}';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (player.platform is NativePlayer) {
        await (player.platform as dynamic).setProperty(
          'force-seekable',
          'yes',
        );
      }
    });

    player.open(
      Media(
        ref.read(httpServerStateProvider).url + ref.read(pathStateProvider) + widget.url,
        httpHeaders: {
          "authorization": basicAuth,
        },
      ),
    );
    _timer = Timer.periodic(_duration, (Timer timer) {});
  }

  @override
  void dispose() {
    setWindowTitle("Soda");
    player.pause();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Listener(
                      onPointerHover: (event) {
                        showVideoControl = true;
                        setState(() {});
                        _timer?.cancel();
                        _timer = Timer(_duration, () {
                          showVideoControl = false;
                          setState(() {});
                        });
                      },
                      // loading view
                      child: Stack(
                        children: [
                          Video(
                            controller: controller,
                            controls: (state) {
                              return GestureDetector(
                                onDoubleTap: () {
                                  state.toggleFullscreen();
                                },
                                onSecondaryTapDown: (event) => player.state.playing ? player.pause() : player.play(),
                              );
                            },
                          ),
                          StreamBuilder(
                            stream: player.stream.buffering,
                            builder: (context, snapshot) {
                              if (snapshot.data == true) {
                                return GestureDetector(
                                  onSecondaryTapDown: (event) => player.state.playing ? player.pause() : player.play(),
                                  child: Stack(
                                    children: [
                                      Container(
                                        color: Colors.black26,
                                      ),
                                      Positioned(
                                        top: videoPlayerHeight - 50,
                                        left: videoPlayerWidth - 50,
                                        child: const SizedBox(
                                          height: 80,
                                          width: 80,
                                          child: CircularProgressIndicator(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return Container();
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: AnimatedOpacity(
                        opacity: showVideoControl ? 1 : 0,
                        curve: Curves.decelerate,
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        child: MouseRegion(
                          onEnter: (event) => setState(
                            () {
                              _timer?.cancel();
                              showVideoControl = true;
                            },
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 38,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      child: AnimatedOpacity(
                        opacity: showVideoControl ? 1 : 0,
                        curve: Curves.decelerate,
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        child: MouseRegion(
                          onEnter: (event) => setState(
                            () {
                              _timer?.cancel();
                              showVideoControl = true;
                            },
                          ),
                          child: _ControlsOverlay(
                            videoPlayerSize: player.state.width?.toDouble() ?? 0,
                            player: player,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final Player player;
  final double videoPlayerSize;

  const _ControlsOverlay({required this.player, required this.videoPlayerSize});

  @override
  Widget build(BuildContext context) {
    const double controlsOverlaySize = 400;

    return StreamBuilder<Duration>(
        stream: player.stream.position,
        builder: (context, snapshot) {
          return Container(
            width: controlsOverlaySize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color.fromARGB(235, 216, 215, 215),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 3, 10, 11),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: controlsOverlaySize,
                    height: 40,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: IconButton(
                              onPressed: () => player.state.playing ? player.pause() : player.play(),
                              alignment: Alignment.center,
                              iconSize: 42,
                              padding: EdgeInsets.zero,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              icon: Icon(
                                player.state.playing ? Icons.pause : Icons.play_arrow,
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          top: 13,
                          left: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(
                                  Icons.volume_up,
                                  size: 20,
                                ),
                              ),
                              SizedBox(
                                width: 55,
                                child: VolumeSlider(),
                              )
                            ],
                          ),
                        ),
                        const Positioned(
                          top: 13,
                          right: 0,
                          child: Icon(
                            Icons.playlist_play_rounded,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      children: [
                        Text(
                          durationToStringWithoutMilliseconds(player.state.position),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 0),
                            child: ProgressBar(player: player),
                          ),
                        ),
                        Text(
                          durationToStringWithoutMilliseconds(player.state.duration),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 2,
        activeTrackColor: Colors.black38,
        inactiveTrackColor: Colors.grey[300],
        thumbShape: const EmptySliderThumb(),
        overlayColor: Colors.transparent,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
      ),
      child: Slider(
        min: 0.0,
        max: player.state.duration.inSeconds.toDouble(),
        value: player.state.position.inSeconds.toDouble(),
        onChangeEnd: (seekTo) async {
          await player.seek(
            Duration(
              seconds: seekTo.toInt(),
            ),
          );
        },
        onChanged: (_) {},
      ),
    );
  }
}

String durationToStringWithoutMilliseconds(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');

  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));

  return '$hours:$minutes:$seconds';
}

class VolumeSlider extends StatefulWidget {
  const VolumeSlider({super.key});

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  double _volume = 1.0;
  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: SliderComponentShape.noThumb,
      ),
      child: Slider(
        value: _volume,
        onChanged: (value) => setState(() {
          _volume = value;
        }),
        activeColor: Colors.blueAccent,
        inactiveColor: const Color.fromARGB(229, 199, 198, 198),
      ),
    );
  }
}

class EmptySliderThumb extends SliderComponentShape {
  const EmptySliderThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    double thumbRadius = 0;
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}
