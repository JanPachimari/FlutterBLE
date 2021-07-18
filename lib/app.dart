import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  final String appTitle = 'BLE Measurement Tool for Flutter';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: appTitle),
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
  List<ScanResult> results = [];

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String scanText = 'Measuring Signal Strength:', scanHintText = '# Scans', scanButtonText = 'Start Scanning ...';
  final String channelText = 'Measuring Data Throughput:', channelHintText = 'PSM Value', channelButtonText = 'Open Channel ...';
  final TextEditingController scanController = new TextEditingController(), channelController = new TextEditingController();
  int scanCurrent = 0, scanTotal = 0;

  void addResult(final ScanResult result) {
    if (!widget.results.contains(result)) {
      setState(() {
        widget.results.add(result);
      });
    }
  }

  void onScanPressed() async {
    try {
      scanTotal = int.parse(scanController.text);
      if(scanCurrent == scanTotal) {
        return;
      }
      else if(scanTotal > 0) {
        widget.results = [];
        widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
          for (ScanResult result in results) {
            addResult(result);
          }
        });
        await widget.flutterBlue.startScan(timeout: Duration(seconds: 5)).then((value) =>
          setState(() {
            scanCurrent += 1;
          }),
        ).then((value) => widget.flutterBlue.stopScan()
        ).then((value) => onScanPressed());
      }
    } on IOException {
      // Value entered is not a number.
    }
  }

  void onChannelPressed() {
    try {
      int psmValue = int.parse(channelController.text);
      // todo open new screen
    } on IOException {
      // Value entered is not a number.
    }
  }

  Expanded buildScanWidget() {
    List<Container> containers = [];
    for (ScanResult result in widget.results) {
      containers.add(
        Container(
          height: 75,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Text(
                      'No. ${widget.results.indexOf(result)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: <Widget>[
                        Text(
                          result.device.name.isEmpty ? 'unknown' : result.device.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('ID: ${result.device.id}'),
                        Text('${result.device.type}'),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.signal_cellular_4_bar,
                          color: result.rssi <= -100 ? Colors.red :
                          result.rssi <= -50 ? Colors.yellow : Colors.green,
                          size: 30,
                        ),
                        Text(
                          'RSSI: ${result.rssi}',
                          style: result.rssi <= -100 ? TextStyle(color: Colors.red) :
                          result.rssi <= -50 ? TextStyle(color: Colors.yellow) :
                          TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                thickness: 3,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      );
    }
    ListView listView = new ListView(
      children: <Widget>[
        ...containers,
      ],
    );
    return new Expanded(
      child: listView,
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(scanText),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: scanController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: scanHintText,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: onScanPressed,
                      child: Text(scanButtonText),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(channelText),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: channelController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: channelHintText,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: onChannelPressed,
                      child: Text(channelButtonText),
                    ),
                  ),
                ),
              ],
            ),
            Divider(
              thickness: 10,
              color: Colors.blue,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('Scan'),
                ),
                Text(
                  '$scanCurrent',
                  style: Theme.of(context).textTheme.headline4,
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('/'),
                ),
                Text(
                  '$scanTotal',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ],
            ),
            Divider(
              thickness: 10,
              height: 20,
              color: Colors.blue,
            ),
            buildScanWidget(),
          ],
        ),
      ),
    );
  }
}
