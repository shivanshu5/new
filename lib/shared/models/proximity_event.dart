class ProximityEvent {
  final String id;
  final String discovererId;
  final String discoveredUserId;
  final double distance; 
  final DateTime detectedAt;

  ProximityEvent({
    required this.id,
    required this.discovererId,
    required this.discoveredUserId,
    required this.distance,
    required this.detectedAt,
  });

  factory ProximityEvent.fromJson(Map<String, dynamic> json) {
    return ProximityEvent(
      id: json['id'] as String,
      discovererId: json['discovererId'] as String,
      discoveredUserId: json['discoveredUserId'] as String,
      distance: (json['distance'] as num).toDouble(),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'discovererId': discovererId,
    'discoveredUserId': discoveredUserId,
    'distance': distance,
    'detectedAt': detectedAt.toIso8601String(),
  };
}
