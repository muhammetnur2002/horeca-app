enum HistoryType { request, inventory }
class HistoryEntry {
  final String id; final HistoryType type; final String title; final String text; final DateTime createdAt;
  HistoryEntry({required this.id, required this.type, required this.title, required this.text, required this.createdAt});
}
