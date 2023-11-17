import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';

//for window pc based ui need to change here
/* void main() {
  if (Platform.isWindows) {
    // Run Windows-specific code
    runApp(WindowsApp());
  } else {
    // Run mobile-specific code
    runApp(MyApp());
  }
}*/
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothChatScreen(),
    );
  }
}

class BluetoothChatScreen extends StatefulWidget {
  @override
  _BluetoothChatScreenState createState() => _BluetoothChatScreenState();
}

class _BluetoothChatScreenState extends State<BluetoothChatScreen> {
  BluetoothDevice? _selectedDevice;
  BluetoothConnection? _connection;
  List<String> messages = [];
  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Bluetooth Chat ${_connection != null ? 'Connected' : 'Disconnected'}'),
      ),
      body: Center(
        child: _connection != null ? buildChatUI() : buildConnectionButton(),
      ),
    );
  }

  Widget buildConnectionButton() {
    return ElevatedButton(
      onPressed: () async {
        _selectedDevice = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DeviceListScreen()),
        );

        if (_selectedDevice != null) {
          await _connectToDevice(_selectedDevice!);
        }
      },
      child: Text('Connect to Bluetooth'),
    );
  }

  Widget buildChatUI() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(messages[index]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(hintText: 'Type your message'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  _sendMessage(messageController.text);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _connection = await BluetoothConnection.toAddress(device.address);
    _connection!.input.listen(
      (Uint8List data) {
        String message = utf8.decode(data);
        setState(() {
          messages.add(message);
        });
      },
      onDone: () {
        _disconnect();
      },
    );
  }

  void _sendMessage(String message) {
    if (_connection != null) {
      _connection!.output.add(Uint8List.fromList(utf8.encode(message)));
      _connection!.output.allSent.then((_) {
        setState(() {
          messages.add('You: $message');
        });
        messageController.clear();
      });
    }
  }

  void _disconnect() {
    if (_connection != null) {
      _connection!.finish();
      setState(() {
        _connection = null;
      });
    }
  }
}

class DeviceListScreen extends StatelessWidget {
  Future<List<BluetoothDevice>> _discoverDevices() async {
    List<BluetoothDevice> devices = [];

    try {
      devices = await QuickBlue.instance.getBondedDevices();
      if (devices.isEmpty) {
        devices = await QuickBlue.instance.startDiscovery();
      }
    } catch (e) {
      print("Error discovering devices: $e");
    }

    return devices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select a Bluetooth Device'),
      ),
      body: FutureBuilder<List<BluetoothDevice>>(
        future: _discoverDevices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No Bluetooth devices found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = snapshot.data![index];
                return ListTile(
                  title: Text(device.name ?? "Unknown Device"),
                  subtitle: Text(device.address),
                  onTap: () {
                    Navigator.pop(context, device);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

/*
class WindowsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Windows-specific configurations
      // ...
      home: WindowsBluetoothChatScreen(),
    );
  }
}

class WindowsBluetoothChatScreen extends StatefulWidget {
  @override
  _WindowsBluetoothChatScreenState createState() => _WindowsBluetoothChatScreenState();
}

class _WindowsBluetoothChatScreenState extends State<WindowsBluetoothChatScreen> {
  // Windows-specific state and UI implementation
  // ...
}
 */
