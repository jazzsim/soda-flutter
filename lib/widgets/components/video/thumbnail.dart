import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soda/controllers/provider.dart';
import 'package:soda/modals/page_content.dart';
import 'package:soda/services/preferences_service.dart';
import 'package:soda/widgets/components/video/main_video_player.dart';
import 'package:soda/widgets/components/video/video_player.m.dart';
import 'package:soda/widgets/extensions/padding.dart';

class VideoThumbnail extends StatelessWidget {
  final FileElement file;
  const VideoThumbnail(this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    String readableFile = Uri.decodeComponent(file.filename);
    bool loadVideoThumbnail = PreferencesService().getVideoThumbnail();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) {
            if (Platform.isAndroid || Platform.isIOS) {
              return MobilleVideoPlayer(file.filename);
            }
            return MainVideoPlayer(file.filename);
          }),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (loadVideoThumbnail)
                  Align(
                    alignment: Alignment.center,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final AsyncValue<String> vidThumbnailUrl = ref.watch(vidThumbnailProvider(file.filename));

                        return vidThumbnailUrl.when(
                          data: (value) {
                            if (value.isEmpty) {
                              return const Center(
                                child: Text(
                                  "Thumbnail service unavailable",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: Color(
                                      0xFF999999,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ExtendedImage.network(
                                value,
                                fit: BoxFit.cover,
                                cacheMaxAge: const Duration(days: 1),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(
                                    12.0,
                                  ),
                                ),
                              ),
                            );
                          },
                          loading: () => const Icon(
                            Icons.play_circle_fill,
                            color: Color.fromARGB(255, 160, 112, 184),
                            size: 100,
                          ),
                          error: (e, st) => const Text('Oops, something unexpected happened'),
                        );
                      },
                    ),
                  )
                else
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Color.fromARGB(255, 160, 112, 184),
                      size: 100,
                    ),
                  ),
                Container(
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.black,
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: [0, 0.4],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Text(
                    readableFile,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                        ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ).pa(15),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
