import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../stores/bluetooth_store.dart';
import '../components/bluetooth_header.dart';
import '../components/bluetooth_status_card.dart';
import '../components/device_list_section.dart';
import '../components/connection_stats.dart';

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
          'Bluetooth Mesh',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _bluetoothStore.isBluetoothEnabled
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
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _bluetoothStore.startScanning,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BluetoothHeader(),
              const SizedBox(height: 20),
              
              BluetoothStatusCard(
                store: _bluetoothStore,
                onToggleBluetooth: _bluetoothStore.toggleBluetooth,
              ),
              const SizedBox(height: 20),
              
              if (_bluetoothStore.isBluetoothEnabled) ...[
                ConnectionStats(store: _bluetoothStore),
                const SizedBox(height: 24),
                
                DeviceListSection(
                  title: 'Connected Devices',
                  devices: _bluetoothStore.connectedDevices,
                  emptyMessage: 'No devices connected',
                  emptyIcon: Icons.bluetooth_disabled,
                  onDeviceAction: (device) => _bluetoothStore.disconnectDevice(device),
                  actionLabel: 'Disconnect',
                  actionIcon: Icons.link_off,
                  actionColor: Colors.red,
                ),
                const SizedBox(height: 24),
                
                DeviceListSection(
                  title: 'Available Devices',
                  devices: _bluetoothStore.availableDevices,
                  emptyMessage: _bluetoothStore.isScanning 
                      ? 'Scanning for devices...' 
                      : 'No devices found. Pull to refresh or tap scan.',
                  emptyIcon: _bluetoothStore.isScanning 
                      ? Icons.bluetooth_searching 
                      : Icons.bluetooth,
                  onDeviceAction: (device) => _bluetoothStore.connectToDevice(device),
                  actionLabel: 'Connect',
                  actionIcon: Icons.link,
                  isLoading: _bluetoothStore.status == BluetoothConnectionStatus.connecting,
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
              onPressed: _bluetoothStore.isScanning
                  ? null
                  : () => _bluetoothStore.startScanning(),
              backgroundColor: _bluetoothStore.isScanning
                  ? colorScheme.surfaceVariant
                  : colorScheme.primary,
              foregroundColor: _bluetoothStore.isScanning
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onPrimary,
              icon: _bluetoothStore.isScanning
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_bluetoothStore.isScanning ? 'Scanning...' : 'Scan Devices'),
            )
          : null,
    );
  }
}
