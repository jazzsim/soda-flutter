import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../controllers/content_controller.dart';
import '../services/preferences_service.dart';
import '../widgets/components/dialogs/loading_dialog.dart';
import '../widgets/components/dialogs/toast_overlay.dart';
import 'desktop/home_page.d.dart';
import 'mobile/home_page.m.dart';
import 'responsive_layout.dart';
import 'tablet/home_page.t.dart';

final selectedIndexStateProvvider = StateProvider<int?>((ref) => null);

final volumeStateProvider = StateProvider<double>((ref) => 100);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // skip if not desktop

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        double height = (await windowManager.getTitleBarHeight()).toDouble();
        ref.read(titleBarHeight.notifier).update((state) => height);
        windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      } else {
        // get phone status bar height
        double height = MediaQuery.of(context).padding.top;
        ref.read(titleBarHeight.notifier).update((state) => height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileLayout: HomePageMobile(),
      tabletLayout: HomePageTablet(),
      dekstopLayout: HomePageDekstop(),
    );
  }
}

void selectServerFunc(WidgetRef ref, BuildContext context, int index) {
  ref.read(selectedIndexStateProvvider.notifier).update((state) => index);
  String url = ref.watch(serverListStateProvider)[index];

  if (ref.read(httpServerStateProvider).url + ref.read(pathStateProvider) != url) {
    LoadingScreen(context).show();
    Uri serverUri = ref.read(contentControllerProvider).selectServer(url);
    ref.invalidate(pageContentStateProvider);
    ref.read(httpServerStateProvider.notifier).update((state) => state.copyWith(url: serverUri.origin));
    ref.read(pathStateProvider.notifier).state = serverUri.path;

    ref.read(contentControllerProvider).getPageContent().then((_) {
      if (!context.mounted) return;
      LoadingScreen(context).hide();
    }).catchError((err, st) {
      if (!context.mounted) return;
      LoadingScreen(context).hide();
      showToast(context, ToastType.error, err.toString());
    });
  }
}

Future<void> updateFolderPref() async {
  bool gridFolderView = PreferencesService().getGridFolder();
  gridFolderView = !gridFolderView;
  await PreferencesService().setGridFolder(gridFolderView);
}

void selectFolderFunc(WidgetRef ref, BuildContext context, String folder) {
  LoadingScreen(context).show();
  if (folder == '../') {
    Uri uri = ref.read(contentControllerProvider).handleReverse();
    ref.read(httpServerStateProvider.notifier).update((state) => state.copyWith(url: uri.origin));
    ref.read(pathStateProvider.notifier).update((state) => "${uri.path}/");
  } else {
    ref.watch(pathStateProvider.notifier).update((state) => '$state$folder');
  }
  ref.read(contentControllerProvider).getPageContent().then((value) {
    if (!context.mounted) return;
    LoadingScreen(context).hide();
  }).catchError((err, st) {
    if (!context.mounted) return;
    showToast(context, ToastType.error, err);
  });
}
