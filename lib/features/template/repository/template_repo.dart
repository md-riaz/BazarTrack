import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../model/template_item.dart';

class TemplateRepo {
  final SharedPreferences sharedPreferences;
  static const String _key = 'template_items';

  TemplateRepo({required this.sharedPreferences});

  List<TemplateItem> getItems() {
    final jsonString = sharedPreferences.getString(_key);
    if (jsonString == null) return [];
    final List decoded = jsonDecode(jsonString);
    return decoded.map((e) => TemplateItem.fromJson(e)).toList();
  }

  Future<void> saveItems(List<TemplateItem> items) async {
    final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
    await sharedPreferences.setString(_key, jsonString);
  }
}
