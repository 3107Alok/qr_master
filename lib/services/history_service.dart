
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum HistoryType { scan, generate }

class HistoryItem {
  final String data;
  final DateTime timestamp;
  final HistoryType type;

  HistoryItem({
    required this.data,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index, // Store as index for simplicity or name
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      type: HistoryType.values[json['type']], // Retrieve by index
    );
  }
}

class HistoryService {
  static const String _keyHistory = 'qr_history';

  static Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_keyHistory);
    if (historyJson == null) return [];
    
    final List<dynamic> historyList = jsonDecode(historyJson);
    final List<HistoryItem> items = historyList.map((e) => HistoryItem.fromJson(e)).toList();
    // Return newest first (assuming stored chronological)
    return items.reversed.toList();
  }

  static Future<void> addHistoryItem(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    // Get existing raw list (chronological)
    final String? historyJson = prefs.getString(_keyHistory);
    List<HistoryItem> list = [];
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      list = historyList.map((e) => HistoryItem.fromJson(e)).toList();
    }
    
    list.add(item);
    
    final String json = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_keyHistory, json);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }
}
