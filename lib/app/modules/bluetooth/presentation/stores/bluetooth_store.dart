import 'package:flutter/material.dart';

enum BluetoothConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class BluetoothDevice {
  final String id;
  final String name;
  final int signalStrength;
  final bool isConnected;
  final BluetoothDeviceType type;

  const BluetoothDevice({
    required this.id,
    required this.name,
    required this.signalStrength,
    this.isConnected = false,
    this.type = BluetoothDeviceType.unknown,
  });

  BluetoothDevice copyWith({
    String? id,
    String? name,
    int? signalStrength,
    bool? isConnected,
    BluetoothDeviceType? type,
  }) {
    return BluetoothDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      signalStrength: signalStrength ?? this.signalStrength,
      isConnected: isConnected ?? this.isConnected,
      type: type ?? this.type,
    );
  }
}

enum BluetoothDeviceType {
  phone,
  tablet,
  laptop,
  speaker,
  headphones,
  watch,
  unknown,
}

class BluetoothStore extends ChangeNotifier {
  BluetoothConnectionStatus _status = BluetoothConnectionStatus.disconnected;
  bool _isBluetoothEnabled = true;
  bool _isScanning = false;
  List<BluetoothDevice> _availableDevices = [];
  List<BluetoothDevice> _connectedDevices = [];
  String? _errorMessage;

  // Getters
  BluetoothConnectionStatus get status => _status;
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get isScanning => _isScanning;
  List<BluetoothDevice> get availableDevices => _availableDevices;
  List<BluetoothDevice> get connectedDevices => _connectedDevices;
  String? get errorMessage => _errorMessage;

  // Mock data for demonstration
  final List<BluetoothDevice> _mockDevices = [
    const BluetoothDevice(
      id: '1',
      name: 'Emergency Response Unit',
      signalStrength: 85,
      type: BluetoothDeviceType.laptop,
    ),
    const BluetoothDevice(
      id: '2',
      name: 'Rescue Team Alpha',
      signalStrength: 72,
      type: BluetoothDeviceType.phone,
    ),
    const BluetoothDevice(
      id: '3',
      name: 'Medical Unit-01',
      signalStrength: 68,
      type: BluetoothDeviceType.tablet,
    ),
    const BluetoothDevice(
      id: '4',
      name: 'Base Station',
      signalStrength: 95,
      type: BluetoothDeviceType.laptop,
    ),
    const BluetoothDevice(
      id: '5',
      name: 'Field Commander',
      signalStrength: 60,
      type: BluetoothDeviceType.phone,
    ),
  ];

  void toggleBluetooth() {
    _isBluetoothEnabled = !_isBluetoothEnabled;
    if (!_isBluetoothEnabled) {
      _status = BluetoothConnectionStatus.disconnected;
      _connectedDevices.clear();
      _availableDevices.clear();
      _isScanning = false;
    }
    notifyListeners();
  }

  Future<void> startScanning() async {
    if (!_isBluetoothEnabled) return;

    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    // Simulate scanning delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate discovering devices gradually
    _availableDevices.clear();
    for (int i = 0; i < _mockDevices.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      _availableDevices.add(_mockDevices[i]);
      notifyListeners();
    }

    _isScanning = false;
    notifyListeners();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (!_isBluetoothEnabled) return;

    _status = BluetoothConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate connection success/failure
    if (device.signalStrength > 50) {
      _status = BluetoothConnectionStatus.connected;
      final connectedDevice = device.copyWith(isConnected: true);
      _connectedDevices.add(connectedDevice);
      
      // Remove from available devices
      _availableDevices.removeWhere((d) => d.id == device.id);
    } else {
      _status = BluetoothConnectionStatus.error;
      _errorMessage = 'Connection failed: Signal too weak';
    }

    notifyListeners();
  }

  void disconnectDevice(BluetoothDevice device) {
    _connectedDevices.removeWhere((d) => d.id == device.id);
    
    // Add back to available devices
    final disconnectedDevice = device.copyWith(isConnected: false);
    _availableDevices.add(disconnectedDevice);
    
    if (_connectedDevices.isEmpty) {
      _status = BluetoothConnectionStatus.disconnected;
    }
    
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == BluetoothConnectionStatus.error) {
      _status = _connectedDevices.isNotEmpty
          ? BluetoothConnectionStatus.connected
          : BluetoothConnectionStatus.disconnected;
    }
    notifyListeners();
  }
}
