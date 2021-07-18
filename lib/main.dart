import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io' as io;

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

var allRssiMap = new Map<DeviceIdentifier, String>();

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
  List<BluetoothDevice> deviceList = [];
  var currentRssiMap = new Map<DeviceIdentifier, int>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class MySecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Open L2CAP Channel"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate back to first route when tapped.
            Navigator.pop(context);
          },
          child: Text('Go back!'),
        ),
      ),
    );
  }
}

class MyThirdPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BLE Scanning Results"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: onPopupMenuClick,
            itemBuilder: (BuildContext context) {
              return {'Copy to clipboard'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          SingleChildScrollView(
            child: Expanded(
              flex: 1,
              child: Text(
                getAllRssiMap(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: null,
              ),
            )
          ),
        ],
      ),
      // todo graphs here!
    );
  }

  void onPopupMenuClick(String value) {
    switch (value) {
      case 'Copy to clipboard':
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

class _MyHomePageState extends State<MyHomePage> {

  TextEditingController tec = new TextEditingController();
  Timer timer;
  int scansSoFar = -1;

  void addDevice(final ScanResult result) {
    if (!widget.deviceList.contains(result.device)) {
      setState(() {
        widget.deviceList.add(result.device);
        widget.currentRssiMap[result.device.id] = result.rssi;
      });
    }
    if (allRssiMap.containsKey(result.device.id))
      allRssiMap[result.device.id] += ' (${getIndexOfElement(result.device).toString()})' + result.rssi.toString();
    else
      allRssiMap[result.device.id] = ' (${getIndexOfElement(result.device).toString()})' + result.rssi.toString();
  }

  void scanForDevices() {
    int amountScans = int.parse(tec.text);
    if (!amountScans.isNaN && amountScans >= 1) {
      timer = Timer.periodic(Duration(seconds: 4), (Timer t) => doSingleScan());
    }
  }

  void doSingleScan() {
    widget.deviceList = [];
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results)
        addDevice(result);
    });
    widget.flutterBlue.startScan(timeout: Duration(seconds: 3));
    scansSoFar += 1;
    if (int.parse(tec.text) == scansSoFar && scansSoFar >= 1) {
      timer.cancel();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyThirdPage()),
      );
      scansSoFar = -1;
    }
  }

  int getIndexOfElement(BluetoothDevice device) {
    int index = widget.deviceList.indexOf(device);
    return index + 1;
  }

  @override
  void initState() {
    super.initState();
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
                      "No. " + getIndexOfElement(device).toString(),
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
          controller: tec,
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
              MaterialPageRoute(builder: (context) => MySecondPage()),
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

/*
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            */

/*

setState(() {

// This call to setState tells the Flutter framework that something has
// changed in this State, which causes it to rerun the build method below
// so that the display can reflect the updated values. If we changed
// _counter without calling setState(), then the build method would not be
// called again, and so nothing would appear to happen.
_counter++;
});

 */