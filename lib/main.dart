// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/menu_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const double adHeight = 100.0; // ← 広告の高さ（index.html と合わせる）

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ジャグノート',
      theme: ThemeData(primarySwatch: Colors.green),

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

      // 📌 全画面に広告分（100px + safe-area）の余白を追加する
      builder: (context, child) {
        // iPhone のホームバー対策（安全領域）
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;

        return Padding(
          // 📌 全ての画面の下に「広告高さ＋iPhoneの下余白」を足す
          padding: EdgeInsets.only(bottom: adHeight + bottomInset),
          child: child ?? const SizedBox.shrink(),
        );
      },

      // ルートは MenuScreen のみ
      initialRoute: '/',
      routes: {
        '/': (_) => const MenuScreen(),
      },
    );
  }
}
