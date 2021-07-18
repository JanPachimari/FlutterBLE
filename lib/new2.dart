import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  // Executable entrypoint.
  runApp(FlutterApp());
}

// Global variables.
// Maps the unique device IDs to their signal strength, discovered within all cycles.
var allRssiMap = new Map<DeviceIdentifier, String>();

class FlutterApp extends StatelessWidget {
  // Root of the application.
  final String appTitle = 'BLE Measurement Tool for Flutter';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Theme of the application, here: Material Design.
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeRoute(title: appTitle),
    );
  }
}

class HomeRoute extends StatefulWidget {
  // Hold the app title provided by the parent, here: The app widget.
  final String title;
  HomeRoute({Key key, this.title}) : super(key: key);

  @override
  _HomeRouteState createState() => _HomeRouteState();

  // Obtain an instance of FlutterBlue.
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  // List that will contain all discovered Bluetooth devices.
  List<BluetoothDevice> devices = [];
  // Maps the unique device IDs to their signal strength, discovered within the current cycle.
  var currentRssiMap = new Map<DeviceIdentifier, int>();
}

class ChannelRoute extends StatelessWidget {
  // Route for opening an L2CAP channel.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Open L2CAP Channel ...'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Go back!'),
          onPressed: () {
            // Navigate back to first route when tapped.
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class ResultRoute extends StatelessWidget {
  // Route for displaying the BLE scanning results.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BLE Scanning Results'),
        actions: <Widget>[
          PopupMenuButton<String>(
            // Display option for copying the results to the clipboard as a string.
            onSelected: onPopupMenuClick,
            itemBuilder: (BuildContext context) {
              return {'Copy to Clipboard'}.map((String option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Text(
          // Display the collected results from all scan cycles.
          getAllRssiMap(),
          textAlign: TextAlign.center,
          maxLines: null,
          style: const TextStyle(
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      // todo graphs here!
    );
  }

  void onPopupMenuClick(String value) {
    switch (value) {
      case 'Copy to clipboard':
        // Copy results to the device's clipboard for use elsewhere.
        Clipboard.setData(ClipboardData(text: getAllRssiMap()));
        return;
      default:
        return;
    }
  }

  String getAllRssiMap(){
    String info = '';
    List<String> rssiList = [];
    List<String> uniqueRssiList = [];
    allRssiMap.forEach((k, v) => {
      rssiList = v.split(' '),
      for (String value in rssiList) {
        if (!uniqueRssiList.contains(value)) {
          uniqueRssiList.add(value),
        }
      },
      info += '\n $k \n\n ',
      for (String value in uniqueRssiList) {
        info += ' $value '
      },
      info += '\n\n --- \n',
      rssiList = [],
      uniqueRssiList = [],
    });
    return info;
  }
}

class _HomeRouteState extends State<HomeRoute> {

  TextEditingController scanController = new TextEditingController();
  Timer timer;
  int scansSoFar = -1;

  void addDevice(final ScanResult result) {
    if (!widget.devices.contains(result.device)) {
      setState(() {
        widget.devices.add(result.device);
        widget.currentRssiMap[result.device.id] = result.rssi;
      });
    }
    if (allRssiMap.containsKey(result.device.id))
      allRssiMap[result.device.id] += ' (${getOrder(result.device).toString()})' + result.rssi.toString();
    else
      allRssiMap[result.device.id] = ' (${getOrder(result.device).toString()})' + result.rssi.toString();
  }

  void scanForDevices() {
    int amountScans = int.parse(scanController.text);
    if (!amountScans.isNaN && amountScans >= 1) {
      timer = Timer.periodic(Duration(seconds: 4), (Timer t) => doSingleScan());
    }
  }

  void doSingleScan() {
    widget.devices = [];
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results)
        addDevice(result);
    });
    widget.flutterBlue.startScan(timeout: Duration(seconds: 3));
    scansSoFar += 1;
    if (int.parse(scanController.text) == scansSoFar && scansSoFar >= 1) {
      timer.cancel();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResultRoute()),
      );
      scansSoFar = -1;
    }
  }

  int getOrder(BluetoothDevice device) {
    int index = widget.devices.indexOf(device);
    return index + 1;
  }

  @override
  void initState() {
    super.initState();
  }

  ListView _buildListView() {
    List<Container> containers = [];
    for (BluetoothDevice device in widget.devices) {
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
                      "No. " + getOrder(device).toString(),
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
                      "RSSI: " + widget.currentRssiMap[device.id].toString(),
                      style: widget.currentRssiMap[device.id] <= -100 ?
                      TextStyle(color: Colors.red) :
                      widget.currentRssiMap[device.id] <= -50 ?
                      TextStyle(color: Colors.orange) :
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
          controller: scanController,
          keyboardType: TextInputType.number,
        ),
        TextButton(
          onPressed: () {
            scanForDevices();
          },
          child: const Text('Start BLE Scanning'),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChannelRoute()),
            );
          },
          child: const Text('Open L2CAP Channel'),
        ),
        const Divider(
          height: 5,
          thickness: 1,
          indent: 0,
          endIndent: 0,
        ),
        SizedBox(height: 15),
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