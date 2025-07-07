# Bluetooth Module Persistence Implementation

## What was changed:

1. **Moved BluetoothStore to AppModule**
   - Moved the BluetoothStore binding from BluetoothModule to AppModule
   - This makes the BluetoothStore a global singleton accessible throughout the app
   - The store will persist even after navigating away from the Bluetooth page

2. **Modified BluetoothModule**
   - Removed BluetoothStore binding since it's now registered in the AppModule
   - BluetoothModule now only handles the routes for the Bluetooth page

3. **Modified BluetoothPage**
   - Updated initialization code to check if the store is already initialized
   - Prevents duplicate initialization when returning to the Bluetooth page

## Technical explanation:

The key issue was that in the original implementation, the BluetoothStore was scoped to the BluetoothModule. When the user navigated away from the Bluetooth page, the BluetoothStore was disposed, terminating all Bluetooth connections and services.

By moving the BluetoothStore binding to the AppModule, we've made it a global singleton that persists throughout the application's lifecycle. Now when you navigate away from the Bluetooth page and return to it, the same BluetoothStore instance is used, preserving all connections and state.

The BluetoothPage now checks if the store is already initialized before initializing it again, ensuring that the Bluetooth functionality continues seamlessly.

## Testing:

To test this implementation:
1. Launch the application
2. Navigate to the Bluetooth page
3. Connect to a device or start scanning
4. Navigate back to the Home page
5. Return to the Bluetooth page

You should observe that the Bluetooth functionality and any established connections are maintained across navigation.
