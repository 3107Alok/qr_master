
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

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'type': type.index,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      type: HistoryType.values[json['type']],
    );
  }
}
