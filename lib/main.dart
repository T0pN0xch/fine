import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'features/shell/main_shell.dart';
import 'providers/providers.dart';

/// If a personal seed database is bundled under assets/data/personal_seed.sqlite
/// (a local-only, gitignored asset — never present in the public source tree),
/// copy it into place before the app's own database is first opened, so this
/// build launches directly into that data instead of the demo seed.
Future<void> _installPersonalSeedIfPresent() async {
  final docsDir = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(docsDir.path, 'budgetku.sqlite'));
  if (await dbFile.exists()) return;

  ByteData seedData;
  try {
    seedData = await rootBundle.load('assets/data/personal_seed.sqlite');
  } on FlutterError {
    return; // No personal seed bundled in this build — normal demo seed runs.
  }

  await dbFile.create(recursive: true);
  await dbFile.writeAsBytes(seedData.buffer.asUint8List(), flush: true);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _installPersonalSeedIfPresent();

  await NotificationService.instance.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: BudgetKuApp()));
}

class BudgetKuApp extends ConsumerWidget {
  const BudgetKuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const MainShell(),
    );
  }
}
