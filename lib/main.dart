import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:developer' as dev;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter BLE'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> deviceList = [];
  final rssiMap = new Map<DeviceIdentifier, int>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  _addDevice(final ScanResult result) {
    if (!widget.deviceList.contains(result.device)) {
      setState(() {
        widget.deviceList.add(result.device);
        widget.rssiMap[result.device.id] = result.rssi;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results)
        _addDevice(result);
    });
    widget.flutterBlue.startScan();
  }

  ListView _buildListView() {
    List<Container> containers = [];
    for (BluetoothDevice device in widget.deviceList) {
      containers.add(
        Container(
          height: 75,
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Column(
                  children: <Widget>[
                    Text(
                      "No. " + widget.deviceList.indexOf(device).toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  children: <Widget>[
                    Text(
                      device.name == '' ? 'UNKNOWN' : device.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("ID: " + device.id.toString()),
                    Text("Type: " + device.type.toString().substring(20).toUpperCase()),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  children: <Widget>[
                    Text(
                      "RSSI: " + widget.rssiMap[device.id].toString(),
                      style: widget.rssiMap[device.id] <= -100 ?
                          TextStyle(color: Colors.red) :
                        widget.rssiMap[device.id] <= -50 ?
                          TextStyle(color: Colors.yellow) :
                          TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.only(top: 0.0),
      children: <Widget>[
        TextField(
          decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter # Scans'
          ),
        ),
        TextButton(
          onPressed: () {
            print('button 1 test');
          },
          child: const Text('Start BLE Scanning'),
        ),
        TextButton(
          onPressed: () {
            print('button 2 test');
          },
          child: const Text('Open L2CAP Channel'),
        ),
        ...containers,
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
    ),
    body: _buildListView(),
  );
}