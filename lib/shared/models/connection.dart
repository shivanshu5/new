class Connection {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime connectedAt;

  Connection({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.connectedAt,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] as String,
      user1Id: json['user1Id'] as String,
      user2Id: json['user2Id'] as String,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user1Id': user1Id,
    'user2Id': user2Id,
    'connectedAt': connectedAt.toIso8601String(),
  };
}
