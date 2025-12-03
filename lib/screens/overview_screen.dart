import 'package:flutter/material.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('収支概要')),
      body: const Center(child: Text('ここにグラフなどを表示予定')),
    );
  }
}
