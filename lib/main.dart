// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/menu_screen.dart'; // MenuScreen だけ残す

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'こえん式ジャグラー収支表 Web版',
      theme: ThemeData(primarySwatch: Colors.green),

      // 最初に表示する画面
      initialRoute: '/',

      // ルートは MenuScreen のみ
      routes: {
        '/': (_) => const MenuScreen(),
      },

      // 日本語対応
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'),
        Locale('en'),
      ],
      locale: const Locale('ja'),
    );
  }
}
