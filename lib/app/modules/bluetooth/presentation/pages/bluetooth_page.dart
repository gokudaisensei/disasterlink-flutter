import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../stores/real_bluetooth_store.dart';
import '../components/bluetooth_header.dart';
import '../components/real_bluetooth_status_card.dart';
import '../components/real_device_list_section.dart';
import '../components/real_connection_stats.dart';
import '../components/message_history_section.dart';
import '../components/send_message_dialog.dart';
import '../../domain/constants/ble_constants.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  late final BluetoothStore _bluetoothStore;

  @override
  void initState() {
    super.initState();
    _bluetoothStore = Modular.get<BluetoothStore>();
    _bluetoothStore.addListener(_onBluetoothStateChanged);

    // Initialize the store
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bluetoothStore.initialize();
    });
  }

  @override
  void dispose() {
    _bluetoothStore.removeListener(_onBluetoothStateChanged);
    super.dispose();
  }

  void _onBluetoothStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Emergency Mesh Network',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed:
                _bluetoothStore.isBluetoothEnabled &&
                    !_bluetoothStore.isScanning
                ? () => _bluetoothStore.startScanning()
                : null,
            icon: _bluetoothStore.isScanning
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Scan for devices',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'emergency_sos',
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Send Emergency SOS'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_location',
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Share Location'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'connection_stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.green),
                    SizedBox(width: 8),
                    Text('View Statistics'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_bluetoothStore.isBluetoothEnabled) {
            await _bluetoothStore.startScanning();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const BluetoothHeader(),
              const SizedBox(height: 20),

              // Status Card
              RealBluetoothStatusCard(
                store: _bluetoothStore,
                onToggleBluetooth: _bluetoothStore.toggleBluetooth,
                onTogglePeripheral: _togglePeripheralMode,
              ),
              const SizedBox(height: 20),

              if (_bluetoothStore.isBluetoothEnabled) ...[
                // Connection Statistics
                RealConnectionStats(store: _bluetoothStore),
                const SizedBox(height: 24),

                // Connected Devices (Central)
                RealDeviceListSection(
                  title: 'Connected Devices (Central)',
                  devices: _bluetoothStore.connectedDevices,
                  emptyMessage: 'No devices connected as central',
                  emptyIcon: Icons.bluetooth_disabled,
                  onDeviceAction: (device) =>
                      _bluetoothStore.disconnectFromDevice(device),
                  actionLabel: 'Disconnect',
                  actionIcon: Icons.link_off,
                  actionColor: Colors.red,
                  isLoading:
                      _bluetoothStore.centralConnectionState ==
                      BleConnectionState.disconnecting,
                ),
                const SizedBox(height: 24),

                // Available Devices
                RealDeviceListSection(
                  title: 'Available Devices',
                  devices: _bluetoothStore.discoveredDevices,
                  emptyMessage: _bluetoothStore.isScanning
                      ? 'Scanning for emergency devices...'
                      : 'No devices found. Pull to refresh or tap scan.',
                  emptyIcon: _bluetoothStore.isScanning
                      ? Icons.bluetooth_searching
                      : Icons.bluetooth,
                  onDeviceAction: (device) =>
                      _bluetoothStore.connectToDevice(device),
                  actionLabel: 'Connect',
                  actionIcon: Icons.link,
                  isLoading:
                      _bluetoothStore.centralConnectionState ==
                      BleConnectionState.connecting,
                ),
                const SizedBox(height: 24),

                // Peripheral Connections
                PeripheralDeviceListSection(
                  devices: _bluetoothStore.peripheralConnectedDevices,
                ),
                const SizedBox(height: 24),

                // Message History
                MessageHistorySection(
                  messages: [
                    ..._bluetoothStore.receivedMessages,
                    ..._bluetoothStore.sentMessages,
                  ],
                ),
              ],

              // Error handling
              if (_bluetoothStore.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _bluetoothStore.errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _bluetoothStore.clearError,
                        icon: Icon(Icons.close, color: Colors.red.shade700),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 100), // Extra space at bottom
            ],
          ),
        ),
      ),
      floatingActionButton: _bluetoothStore.isBluetoothEnabled
          ? FloatingActionButton.extended(
              onPressed: _showSendMessageDialog,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: const Icon(Icons.message),
              label: const Text('Send Message'),
            )
          : null,
    );
  }

  void _togglePeripheralMode() {
    if (_bluetoothStore.isPeripheralActive) {
      _bluetoothStore.stopPeripheralMode();
    } else {
      _bluetoothStore.startPeripheralMode();
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'emergency_sos':
        await _bluetoothStore.sendEmergencySOS(
          additionalInfo: 'Emergency SOS sent from DisasterLink app',
        );
        _showSnackBar(
          'Emergency SOS sent to all connected devices',
          Colors.red,
        );
        break;
      case 'share_location':
        await _bluetoothStore.sendLocationShare(
          locationName: 'Current Location',
        );
        _showSnackBar('Location shared with network', Colors.blue);
        break;
      case 'connection_stats':
        _showConnectionStatsDialog();
        break;
    }
  }

  void _showSendMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => SendMessageDialog(
        onSendMessage: (text, priority, targetDevice) async {
          await _bluetoothStore.sendTextMessage(
            text: text,
            targetDevice: targetDevice,
            priority: priority,
          );
          _showSnackBar('Message sent successfully', Colors.green);
        },
        availableDevices: _bluetoothStore.connectedDevices,
      ),
    );
  }

  void _showConnectionStatsDialog() {
    final stats = _bluetoothStore.getConnectionStats();
    final messageStats = _bluetoothStore.getMessageStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connection Statistics:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...stats.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(entry.key), Text(entry.value.toString())],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Message Statistics:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...messageStats.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(entry.key), Text(entry.value.toString())],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
