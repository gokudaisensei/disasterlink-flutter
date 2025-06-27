import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';

class CommunityStore extends ChangeNotifier {
  List<UserProfile> _nearbyUsers = [];
  List<UserProfile> _connectedUsers = [];
  UserProfile? _currentUser;
  bool _isScanning = false;
  bool _isDiscovering = false;
  String? _errorMessage;

  // Getters
  List<UserProfile> get nearbyUsers => _nearbyUsers;
  List<UserProfile> get connectedUsers => _connectedUsers;
  List<UserProfile> get connectedPeers => _connectedUsers; // Alias for consistency
  UserProfile? get currentUser => _currentUser;
  bool get isScanning => _isScanning;
  bool get isDiscovering => _isDiscovering;
  String? get errorMessage => _errorMessage;

  // Mock current user
  UserProfile get defaultCurrentUser => UserProfile(
    id: 'current_user',
    name: 'Emergency Coordinator',
    role: UserRole.firstResponder,
    status: UserStatus.canHelp,
    trustScore: 4.8,
    lastSeen: DateTime.now(),
    location: 'Emergency Command Center',
    skills: const ['First Aid', 'Communication', 'Coordination'],
    resources: const ['Radio Equipment', 'Medical Supplies'],
    isOnline: true,
    signalStrength: 100,
  );

  // Mock nearby users data
  final List<UserProfile> _mockNearbyUsers = [
    UserProfile(
      id: 'user_1',
      name: 'Dr. Sarah Chen',
      role: UserRole.medicalPersonnel,
      status: UserStatus.canHelp,
      trustScore: 4.9,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
      location: 'Medical Station Alpha',
      skills: ['Emergency Medicine', 'Surgery', 'Triage'],
      resources: ['Medical Kit', 'Defibrillator'],
      isOnline: true,
      signalStrength: 92,
    ),
    UserProfile(
      id: 'user_2',
      name: 'Mike Rodriguez',
      role: UserRole.volunteer,
      status: UserStatus.canHelp,
      trustScore: 4.5,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      location: 'Shelter Zone B',
      skills: ['Search & Rescue', 'Heavy Lifting'],
      resources: ['Tools', 'Vehicle Access'],
      isOnline: true,
      signalStrength: 78,
    ),
    UserProfile(
      id: 'user_3',
      name: 'Emma Thompson',
      role: UserRole.civilian,
      status: UserStatus.needHelp,
      trustScore: 4.2,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 1)),
      location: 'Residential Area C',
      skills: ['Local Knowledge'],
      resources: [],
      isOnline: true,
      signalStrength: 65,
    ),
    UserProfile(
      id: 'user_4',
      name: 'Captain James Wilson',
      role: UserRole.firstResponder,
      status: UserStatus.canHelp,
      trustScore: 4.8,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 3)),
      location: 'Fire Station 12',
      skills: ['Fire Fighting', 'Rescue Operations', 'Leadership'],
      resources: ['Fire Truck', 'Rescue Equipment'],
      isOnline: true,
      signalStrength: 88,
    ),
    UserProfile(
      id: 'user_5',
      name: 'Lisa Park',
      role: UserRole.volunteer,
      status: UserStatus.safe,
      trustScore: 4.3,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 8)),
      location: 'Supply Distribution Point',
      skills: ['Logistics', 'Communication'],
      resources: ['Supplies', 'Transportation'],
      isOnline: true,
      signalStrength: 71,
    ),
    UserProfile(
      id: 'user_6',
      name: 'David Kim',
      role: UserRole.civilian,
      status: UserStatus.emergency,
      trustScore: 4.0,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 1)),
      location: 'Apartment Complex D',
      skills: ['Technical Skills'],
      resources: [],
      isOnline: true,
      signalStrength: 45,
    ),
  ];

  void initializeCurrentUser() {
    _currentUser = defaultCurrentUser;
    notifyListeners();
  }

  Future<void> scanForNearbyUsers() async {
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    // Simulate scanning delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate discovering users gradually
    _nearbyUsers.clear();
    for (int i = 0; i < _mockNearbyUsers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      _nearbyUsers.add(_mockNearbyUsers[i]);
      notifyListeners();
    }

    _isScanning = false;
    notifyListeners();
  }

  Future<void> connectToUser(UserProfile user) async {
    if (_connectedUsers.any((u) => u.id == user.id)) return;

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 1));

    _connectedUsers.add(user.copyWith(isOnline: true));
    _nearbyUsers.removeWhere((u) => u.id == user.id);
    notifyListeners();
  }

  void disconnectFromUser(UserProfile user) {
    _connectedUsers.removeWhere((u) => u.id == user.id);
    _nearbyUsers.add(user.copyWith(isOnline: false));
    notifyListeners();
  }

  void updateUserStatus(UserStatus newStatus) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(status: newStatus);
      notifyListeners();
    }
  }

  List<UserProfile> getUsersByRole(UserRole role) {
    return [..._nearbyUsers, ..._connectedUsers]
        .where((user) => user.role == role)
        .toList();
  }

  List<UserProfile> getUsersByStatus(UserStatus status) {
    return [..._nearbyUsers, ..._connectedUsers]
        .where((user) => user.status == status)
        .toList();
  }

  int get networkSize => _connectedUsers.length;
  
  double get averageTrustScore {
    if (_connectedUsers.isEmpty) return 0.0;
    return _connectedUsers
        .map((user) => user.trustScore)
        .reduce((a, b) => a + b) / _connectedUsers.length;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // New methods for user discovery
  Future<void> startUserDiscovery() async {
    _isDiscovering = true;
    notifyListeners();
    
    // Start continuous discovery
    await scanForNearbyUsers();
  }

  void stopUserDiscovery() {
    _isDiscovering = false;
    notifyListeners();
  }

  Future<void> refreshNearbyUsers() async {
    await scanForNearbyUsers();
  }

  bool isUserConnected(String userId) {
    return _connectedUsers.any((user) => user.id == userId);
  }

  UserProfile? getUserById(String userId) {
    return [..._nearbyUsers, ..._connectedUsers]
        .where((user) => user.id == userId)
        .firstOrNull;
  }
}
