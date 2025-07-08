import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../stores/real_bluetooth_store.dart';
import '../components/bluetooth_header.dart';
import '../components/real_bluetooth_status_card.dart';
import '../components/devices_tab.dart';
import '../components/messaging_tab.dart';
import '../components/messages_tab.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage>
    with TickerProviderStateMixin {
  late final BluetoothStore _bluetoothStore;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _bluetoothStore = Modular.get<BluetoothStore>();
    _bluetoothStore.addListener(_onBluetoothStateChanged);
    _tabController = TabController(length: 3, vsync: this);

    // Check if store needs initialization (it should already be initialized by the app)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_bluetoothStore.isInitialized) {
        _bluetoothStore.initialize();
      }
    });
  }

  @override
  void dispose() {
    _bluetoothStore.removeListener(_onBluetoothStateChanged);
    _tabController.dispose();
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
        bottom: _bluetoothStore.isBluetoothEnabled
            ? TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                indicatorColor: colorScheme.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.devices), text: 'Devices'),
                  Tab(icon: Icon(Icons.send), text: 'Send'),
                  Tab(icon: Icon(Icons.message), text: 'Messages'),
                ],
              )
            : null,
      ),
      body: _bluetoothStore.isBluetoothEnabled
          ? Column(
              children: [
                // Status Card
                Container(
                  margin: const EdgeInsets.all(16),
                  child: RealBluetoothStatusCard(
                    store: _bluetoothStore,
                    onToggleBluetooth: _bluetoothStore.toggleBluetooth,
                    onTogglePeripheral: _togglePeripheralMode,
                  ),
                ),
                // Error handling banner
                if (_bluetoothStore.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.red.shade50,
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
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      DevicesTab(bluetoothStore: _bluetoothStore),
                      MessagingTab(bluetoothStore: _bluetoothStore),
                      MessagesTab(bluetoothStore: _bluetoothStore),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BluetoothHeader(),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: RealBluetoothStatusCard(
                      store: _bluetoothStore,
                      onToggleBluetooth: _bluetoothStore.toggleBluetooth,
                      onTogglePeripheral: _togglePeripheralMode,
                    ),
                  ),
                ],
              ),
            ),
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
      case 'connection_stats':
        _showConnectionStatsDialog();
        break;
    }
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
}
