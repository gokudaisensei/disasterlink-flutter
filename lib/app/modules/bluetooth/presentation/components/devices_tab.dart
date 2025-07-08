import 'package:flutter/material.dart';
import '../stores/real_bluetooth_store.dart';
import 'real_device_list_section.dart';
import 'real_connection_stats.dart';
import '../../domain/constants/ble_constants.dart';

class DevicesTab extends StatelessWidget {
  final BluetoothStore bluetoothStore;

  const DevicesTab({super.key, required this.bluetoothStore});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Statistics
          RealConnectionStats(store: bluetoothStore),
          const SizedBox(height: 24),

          // Connected Devices (Central)
          RealDeviceListSection(
            title: 'Connected Devices (Central)',
            devices: bluetoothStore.connectedDevices,
            emptyMessage: 'No devices connected as central',
            emptyIcon: Icons.bluetooth_disabled,
            onDeviceAction: (device) =>
                bluetoothStore.disconnectFromDevice(device),
            actionLabel: 'Disconnect',
            actionIcon: Icons.link_off,
            actionColor: Colors.red,
            isLoading:
                bluetoothStore.centralConnectionState ==
                BleConnectionState.disconnecting,
          ),
          const SizedBox(height: 24),

          // Available Devices
          RealDeviceListSection(
            title: 'Available Devices',
            devices: bluetoothStore.discoveredDevices,
            emptyMessage: bluetoothStore.isScanning
                ? 'Scanning for emergency devices...'
                : 'No devices found. Pull to refresh or tap scan.',
            emptyIcon: bluetoothStore.isScanning
                ? Icons.bluetooth_searching
                : Icons.bluetooth,
            onDeviceAction: (device) => bluetoothStore.connectToDevice(device),
            actionLabel: 'Connect',
            actionIcon: Icons.link,
            isLoading:
                bluetoothStore.centralConnectionState ==
                BleConnectionState.connecting,
          ),
          const SizedBox(height: 24),

          // Peripheral Connections
          PeripheralDeviceListSection(
            devices: bluetoothStore.peripheralConnectedDevices,
          ),
        ],
      ),
    );
  }
}
