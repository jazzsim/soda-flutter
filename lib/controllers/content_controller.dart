import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soda/api/server_api.dart';
import 'package:soda/modals/http_server.dart';
import 'package:soda/pages/home_page.dart';
import 'package:soda/providers/preferences_service.dart';
import 'package:soda/widgets/components/video/main_video_player.dart';
import 'package:soda/widgets/components/video/video_control.dart';

import '../modals/page_content.dart';

final thumbnailFutureProvider = FutureProvider.family<Image?, String>((ref, url) async {
  return ref.read(contentControllerProvider).vidThumbnail(url);
});

final httpServerStateProvider = StateProvider<HttpServer>((ref) => HttpServer(url: '', username: '', password: ''));

final pathStateProvider = StateProvider<String>((ref) => '');

final contentControllerProvider = Provider((ref) => ContentController(ref));

final serverListStateProvider = StateProvider<List<String>>((ref) {
  final servers = PreferencesService().getServerList();

  var urls = <String>[];
  for (var s in servers) {
    final server = HttpServer.fromRawJson(s);
    urls.add(server.url);
  }

  return urls;
});

final pageContentStateProvider = StateProvider<PageContent>((ref) {
  return PageContent(folders: [], files: []);
});

final imagesContentStateProvider = StateProvider<List<FileElement>>((ref) => []);

final videosContentStateProvider = StateProvider<List<FileElement>>((ref) => []);

final documentsContentStateProvider = StateProvider<List<FileElement>>((ref) => []);

final othersContentStateProvider = StateProvider<List<FileElement>>((ref) => []);

class ContentController {
  final ProviderRef<Object?> ref;
  ContentController(this.ref);

  Future<void> getPageContent({bool browse = false}) async {
    final String path = browse ? ref.read(browsePathStateProvider) : ref.read(pathStateProvider);
    // append path to selected server
    HttpServer targetServer = ref.read(httpServerStateProvider).copyWith(url: ref.read(httpServerStateProvider).url + path);
    final res = await ServerApi().getContent(targetServer);

    ref.read(pageContentStateProvider.notifier).update((state) => state.copyWith(folders: res.folders, files: res.files));
    sortFiles();
  }

  void sortFiles() {
    List<String> mediaTypes = ['image', 'video', 'document', 'others'];

    for (var type in mediaTypes) {
      final contents = ref.read(pageContentStateProvider).files.where((file) => file.media.toLowerCase() == type).toList();
      switch (type) {
        case "image":
          ref.read(imagesContentStateProvider.notifier).update((state) => contents);
          break;
        case "video":
          ref.read(videosContentStateProvider.notifier).update((state) => contents);
          break;
        case "document":
          ref.read(documentsContentStateProvider.notifier).update((state) => contents);
          break;
        default:
          ref.read(othersContentStateProvider.notifier).update((state) => contents);
      }
    }
  }

  // will sort the saved server url into proper origin and path pair
  // e.g: If saved url was https://example.com/a1/films/,
  // will be separate as https://example.com and /a1/films/ and assign to respective StateProviders
  Uri selectServer(String url) {
    List<String> serverListString = PreferencesService().getServerList();

    for (var s in serverListString) {
      final server = HttpServer.fromRawJson(s);
      if (server.url == url) {
        ref.read(httpServerStateProvider.notifier).update(
              (state) => state.copyWith(
                url: url,
                username: server.username,
                password: server.password,
              ),
            );
        Uri serverUri = Uri.parse(server.url);

        return serverUri;
      }
    }
    return Uri.parse(ref.read(httpServerStateProvider).url);
  }

  Uri handleReverse({bool browse = false}) {
    String path = browse ? ref.read(browsePathStateProvider) : ref.read(pathStateProvider);
    Uri originalUri = Uri.parse(ref.watch(httpServerStateProvider).url + path);
    List<String> newPathSegments = List.from(originalUri.pathSegments);

    // remove empty path ("/")
    if (newPathSegments.last == '') {
      newPathSegments.removeLast();
    }

    // remove latest path
    newPathSegments.removeLast();

    Uri modifiedUri = originalUri.replace(pathSegments: newPathSegments);
    return modifiedUri;
  }

  Future<void> updateServerList() async {
    List<String> serverList = PreferencesService().getServerList();
    final newServer = ref.watch(httpServerStateProvider).toRawJson();

    if (!serverList.contains(newServer)) {
      serverList.add(newServer);
      ref.read(selectedIndexStateProvvider.notifier).update((state) => serverList.length - 1);
      await PreferencesService().setServerList(serverList);
    }
  }

  Future<void> deleteServer(int index) async {
    final selectedServer = ref.watch(serverListStateProvider)[index];
    List<String> serverList = PreferencesService().getServerList();
    List<String> newServerList = [];

    for (var server in serverList) {
      var serverJson = jsonDecode(server);
      if (serverJson["url"] != selectedServer) {
        newServerList.add(json.encode(serverJson));
      }
    }
    await PreferencesService().setServerList(newServerList);
    ref.invalidate(serverListStateProvider);

    // clear content if current active content is from deleted server
    if (ref.watch(selectedIndexStateProvvider) == index) {
      ref.invalidate(selectedIndexStateProvvider);
      ref.invalidate(pageContentStateProvider);
    }
  }

  // video
  Future<Image?> vidThumbnail(String url) async {
    url = getUrl(url);
    try {
      final res = await ServerApi().getThumbnail(url);
      final bytes = base64Decode(res.thumbnail);
      return Image.memory(
        bytes,
        scale: 0.2,
        fit: BoxFit.cover,
      );
    } catch (e) {
      log("error $e");
      return null;
    }
  }

  String getUrl(String url) {
    final username = ref.watch(httpServerStateProvider).username;
    final password = ref.watch(httpServerStateProvider).password;
    if (username != '' && password != '') {
      var uri = Uri.parse(url);
      url = uri.replace(userInfo: '$username:$password').toString();
    }

    return url;
  }

  void startCancelTimer() {
    const Duration volumeDuration = Duration(milliseconds: 1200);

    ref.read(videoTimerProvider)?.cancel();
    ref.read(videoTimerProvider.notifier).state = Timer(volumeDuration, () {
      ref.read(showVolumeProvider.notifier).update((state) => false);
    });
  }
}
