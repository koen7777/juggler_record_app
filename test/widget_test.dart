import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:juggler_record_app/main.dart';
import 'package:juggler_record_app/screens/menu_screen.dart';

void main() {
  testWidgets('MenuScreen displays correctly with top banner', (WidgetTester tester) async {
    // 全画面共通ラッパーで MenuScreen を表示
    await tester.pumpWidget(const AppWithBanner(child: MenuScreen()));

    // MenuScreen のタイトルや主要テキストがあるか確認
    expect(find.text('ジャグノート'), findsOneWidget); // MenuScreen 内タイトル例
    expect(find.byType(ElevatedButton), findsWidgets); // ボタンがあるか確認

    // 上部バナー（HtmlElementView）はテスト環境では無視されるため確認不可
    // 代わりに Column 内に 2 つの子（広告スペース + MenuScreen）があることを確認
    final columnFinder = find.byType(Column);
    expect(columnFinder, findsOneWidget);

    final column = tester.widget<Column>(columnFinder);
    expect(column.children.length, 2); // 上部広告 + MenuScreen
  });
}
