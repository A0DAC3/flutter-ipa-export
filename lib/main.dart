import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BLEController(),
    );
  }
}

class BLEController extends StatefulWidget {
  const BLEController({super.key});
  @override
  State<BLEController> createState() => _BLEControllerState();
}

class _BLEControllerState extends State<BLEController> {
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? targetCharacteristic;
  String status = "Idle";

  // These must match your ESP32 code exactly
  final String deviceName = "ESP32_LED_Control";
  final String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String charUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  void startScan() async {
    setState(() => status = "Scanning...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == deviceName) {
          FlutterBluePlus.stopScan();
          setState(() {
            targetDevice = r.device;
            status = "Found ESP32! Connecting...";
          });
          connectToDevice();
        }
      }
    });
  }

  void connectToDevice() async {
    if (targetDevice == null) return;
    await targetDevice!.connect();
    
    List<BluetoothService> services = await targetDevice!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == serviceUUID) {
        for (var char in service.characteristics) {
          if (char.uuid.toString() == charUUID) {
            setState(() {
              targetCharacteristic = char;
              status = "Connected & Ready";
            });
          }
        }
      }
    }
  }

  void sendCommand(String cmd) async {
    if (targetCharacteristic != null) {
      // We send the ASCII value of '1' or '0'
      await targetCharacteristic!.write(cmd.codeUnits);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ESP32 LED Controller")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Status: $status", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: startScan, 
              child: const Text("Search for ESP32")
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => sendCommand("1"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("ON", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => sendCommand("0"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("OFF", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
