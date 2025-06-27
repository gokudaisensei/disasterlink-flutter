enum UserRole {
  civilian,
  volunteer,
  firstResponder,
  medicalPersonnel,
  admin,
}

enum UserStatus {
  safe,
  needHelp,
  canHelp,
  offline,
  emergency,
}

class UserProfile {
  final String id;
  final String name;
  final String? avatar;
  final UserRole role;
  final UserStatus status;
  final double trustScore;
  final DateTime lastSeen;
  final String? location;
  final List<String> skills;
  final List<String> resources;
  final bool isOnline;
  final int signalStrength;

  const UserProfile({
    required this.id,
    required this.name,
    this.avatar,
    required this.role,
    required this.status,
    required this.trustScore,
    required this.lastSeen,
    this.location,
    this.skills = const [],
    this.resources = const [],
    this.isOnline = false,
    this.signalStrength = 0,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? avatar,
    UserRole? role,
    UserStatus? status,
    double? trustScore,
    DateTime? lastSeen,
    String? location,
    List<String>? skills,
    List<String>? resources,
    bool? isOnline,
    int? signalStrength,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      status: status ?? this.status,
      trustScore: trustScore ?? this.trustScore,
      lastSeen: lastSeen ?? this.lastSeen,
      location: location ?? this.location,
      skills: skills ?? this.skills,
      resources: resources ?? this.resources,
      isOnline: isOnline ?? this.isOnline,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.civilian:
        return 'Civilian';
      case UserRole.volunteer:
        return 'Volunteer';
      case UserRole.firstResponder:
        return 'First Responder';
      case UserRole.medicalPersonnel:
        return 'Medical Personnel';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case UserStatus.safe:
        return 'Safe';
      case UserStatus.needHelp:
        return 'Need Help';
      case UserStatus.canHelp:
        return 'Can Help';
      case UserStatus.offline:
        return 'Offline';
      case UserStatus.emergency:
        return 'Emergency';
    }
  }
}

class PeerConnection {
  final String userId;
  final String connectionId;
  final DateTime connectedAt;
  final int signalStrength;
  final bool isDirectConnection;
  final List<String> hops;

  const PeerConnection({
    required this.userId,
    required this.connectionId,
    required this.connectedAt,
    required this.signalStrength,
    this.isDirectConnection = true,
    this.hops = const [],
  });

  Duration get connectionDuration => DateTime.now().difference(connectedAt);
}
