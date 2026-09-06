class NotificationModel {
  final String id;
  final String homeId;
  final String type; // LOW_STOCK, OUT_OF_STOCK, EXPIRING_SOON, EXPIRED, SHOPPING_LIST_UPDATE, FAMILY_ACTIVITY
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.homeId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      homeId: json['homeId'] ?? '',
      type: json['type'] ?? 'LOW_STOCK',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
