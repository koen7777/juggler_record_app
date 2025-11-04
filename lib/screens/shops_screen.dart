import 'package:flutter/material.dart';
import '../database/db_helper_web.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  final DBHelperWeb _dbHelper = DBHelperWeb();
  final TextEditingController _shopController = TextEditingController();
  List<String> _shops = [];

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  void _loadShops() async {
    final shops = await _dbHelper.getShops();
    setState(() => _shops = shops);
  }

  void _addShop() async {
    final shop = _shopController.text.trim();
    if (shop.isEmpty) return;
    await _dbHelper.insertShop(shop);
    _shopController.clear();
    _loadShops();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('店舗を登録しました')));
  }

  void _deleteShop(String shop) async {
    await _dbHelper.deleteShop(shop);
    _loadShops();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('店舗を削除しました')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('店舗登録')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 入力フォーム + 登録ボタン
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _shopController,
                    decoration: const InputDecoration(
                      labelText: '店舗名',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addShop(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addShop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  child: const Text('登録', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 登録済み店舗リスト
            Expanded(
              child: _shops.isEmpty
                  ? const Center(child: Text('登録済み店舗はありません'))
                  : ListView.builder(
                      itemCount: _shops.length,
                      itemBuilder: (context, index) {
                        final shop = _shops[index];
                        final isEven = index % 2 == 0;
                        return Container(
                          color: isEven
                              ? Colors.grey.shade100
                              : Colors.white, // 奇数偶数で色を変える
                          child: ListTile(
                            title: Text(shop),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteShop(shop),
                                tooltip: '削除',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
