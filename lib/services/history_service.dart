
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';
import 'firestore_service.dart';

export '../models/history_item.dart'; // Re-export for compatibility if needed elsewhere

class HistoryService {
  static const String _keyHistory = 'qr_history';
  static final FirestoreService _firestoreService = FirestoreService();

  static Future<void> addHistoryItem(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Save Locally
    final String? historyJson = prefs.getString(_keyHistory);
    List<HistoryItem> list = [];
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      list = historyList.map((e) => HistoryItem.fromJson(e)).toList();
    }
    
    list.add(item);
    
    final String json = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_keyHistory, json);

    // 2. Sync to Cloud (Fire-and-forget)
    try {
      await _firestoreService.addHistoryItem(item);
    } catch (e) {
      // Ignore cloud errors for now, local is primary
      print("Cloud sync failed: $e");
    }
  }

  static Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_keyHistory);
    if (historyJson == null) return [];

    final List<dynamic> historyList = jsonDecode(historyJson);
    final List<HistoryItem> list = historyList
        .map((e) => HistoryItem.fromJson(e))
        .toList();
    
    // Return reversed list (newest first)
    return list.reversed.toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }
}
