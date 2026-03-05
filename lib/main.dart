import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tickx/home.dart';
import 'package:window_manager/window_manager.dart';
import 'styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      title: 'TickX Reparaciones',
      center: true,
      skipTaskbar: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setFullScreen(true);
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TickX Reparaciones',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const Home(),
    );
  }
}
