// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; // Web専用
import 'dart:ui' as ui; // Web専用

// 既存画面
import 'screens/menu_screen.dart';

void main() {
  if (kIsWeb) {
    // Flutter Web のみ広告タグ登録
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'adstir-banner',
      (int viewId) {
        final container = html.DivElement();
        container.style.width = '100%';
        container.style.height = '100%';
        container.innerHtml = '''
<script type="text/javascript">
var adstir_vars = {
  ver: "4.0",
  app_id: "MEDIA-d51fb80d",
  ad_spot: 1,
  center: false
};
</script>
<script type="text/javascript" src="https://js.ad-stir.com/js/adstir.js"></script>
''';
        return container;
      },
    );
  }

  runApp(const MyAppWithBanner());
}

// MyApp
class MyAppWithBanner extends StatelessWidget {
  const MyAppWithBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ジャグノート',
      theme: ThemeData(primarySwatch: Colors.green),

      // 最初の画面だけ設定
      home: const AppWithBanner(child: MenuScreen()),

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

// 広告付きラッパー（全画面共通）
class AppWithBanner extends StatelessWidget {
  final Widget child;
  const AppWithBanner({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 上部バナー広告
          SizedBox(
            height: 100, // SP 320x100 広告用
            child: kIsWeb
                ? HtmlElementView(viewType: 'adstir-banner')
                : Container(
                    color: Colors.grey.shade300, // Android/iOS向け仮広告スペース
                    child: const Center(child: Text('広告スペース')),
                  ),
          ),
          // 下の画面は常に全画面表示
          Expanded(child: child),
        ],
      ),
    );
  }
}
