import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:draw_graph/draw_graph.dart';
import 'package:draw_graph/models/feature.dart';

void main() {
  runApp(FlutterApp());
}

// Map for storing each device's detection order
Map<DeviceIdentifier, List<int>> order = new Map<DeviceIdentifier, List<int>>();

// Map for storing each device's signal strength
Map<DeviceIdentifier, List<int>> rssi = new Map<DeviceIdentifier, List<int>>();

// Two point pairs for distance estimation
int xMin, yMin, xMax, yMax;

// Slope and y-intercept for distance estimation
double m, b;

class FlutterApp extends StatelessWidget {
  // This widget is the root of your application.
  final String appTitle = 'BLE Measurement Tool for Flutter';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // Define app theme
        primarySwatch: Colors.blue,
      ),
      home: HomeRoute(title: appTitle),
    );
  }
}

class HomeRoute extends StatefulWidget {
  // Flutter defines app pages as 'routes'; this is the default route
  HomeRoute({Key key, this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  // Store devices discovered in the current cycle
  List<ScanResult> results = [];

  @override
  HomeRouteState createState() => HomeRouteState();
}

class HomeRouteState extends State<HomeRoute> {

  // Strings
  final String scanText = 'Measuring Detection Order & Signal Strength:';
  final String scanHintText = '# Scans';
  final String scanButtonText = 'Start Scanning ...';
  final String calibrateText = 'Calibrating Device & Distance Estimating:';
  final String scanCurrentText = 'Scans Completed:';

  // Controllers to allow input field values to be accessed
  final TextEditingController scanController = new TextEditingController();
  final TextEditingController xMinController = new TextEditingController();
  final TextEditingController xMaxController = new TextEditingController();
  final TextEditingController yMinController = new TextEditingController();
  final TextEditingController yMaxController = new TextEditingController();

  // Number of current scan, and the total amount of scans
  int scanCurrent = 0;
  int scanTotal = 0;

  void addResult(final ScanResult result) {
    // Add newly discovered device to list
    if(!widget.results.contains(result)) {
      setState(() {
        // Refresh user interface to display the added device
        widget.results.add(result);
      });
    }
  }

  void onScanPressed() async {
    // Button to commence scans is pressed
    try {
      // Get number of total scans to be executed
      scanTotal = int.parse(scanController.text);
      // Break out of recursion if all scans have been completed
      if(scanCurrent == scanTotal) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResultRoute()),
        );
      }
      else if(scanTotal > 0) {
        // Reset list after every cycle; add devices from anew
        widget.results = [];
        widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
          for (ScanResult result in results) {
            addResult(result);
          }
        });
        // Conduct a scan for five seconds; do this asynchronously
        return await widget.flutterBlue.startScan(timeout: Duration(seconds: 5)
        ).then((value) =>
          setState(() {
            // Refresh user interface to display incremented scan counter
            scanCurrent += 1;
          }),
        ).then((value) => {
          for(ScanResult result in widget.results) {
            // If device has not been detected before, create a new entry
            if(!order.containsKey(result.device.id)) {
              order[result.device.id] = [widget.results.indexOf(result)],
            }
            else {
              // Otherwise add new value to its existing list
              order[result.device.id].add(widget.results.indexOf(result)),
            },
            // If device has not been detected before, create a new entry
            if(!rssi.containsKey(result.device.id)) {
              rssi[result.device.id] = [result.rssi],
            }
            else {
              // Otherwise add new value to its existing list
              rssi[result.device.id].add(result.rssi),
            },
          },
        }).then((value) => widget.flutterBlue.stopScan()
        // Repeat this recursively until all scans are completed
        ).then((value) => onScanPressed()
        );
      }
    } on IOException {
      // Value entered is not a number.
      print('Error: NaN');
    }
  }

  void onCalibratePressed() {
    // Button to calibrate using two point pairs is pressed
    try {
      // Fetch entered data from text input fields
      xMin = int.parse(xMinController.text);
      xMax = int.parse(xMaxController.text);
      yMin = int.parse(yMinController.text);
      yMax = int.parse(yMaxController.text);

      // Calculate slope and y-intercept using these two coordinates
      m = (yMax - yMin) / (xMax - xMin);
      b = ((xMax * yMin) - (xMin * yMax)) / (xMax - xMin);

      // Debug
      print('xMin = $xMin');
      print('xMax = $xMax');
      print('yMin = $yMin');
      print('yMax = $yMax');
      print('y = $m * x + $b');

    } on IOException {
      // Value entered is not a number.
      print('Error: NaN');
    }
  }

  Expanded buildScanWidget() {
    List<Container> containers = [];
    // Give each device an own entry in the list
    for(ScanResult result in widget.results) {
      containers.add(
        Container(
          height: 75,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Text(
                      // Order of detection
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
                          // If device has no name configured, display 'unknown'
                          result.device.name.isEmpty ? 'unknown' : result.device.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // Display device identifier
                        Text('ID: ${result.device.id}'),
                        // Display Bluetooth device type
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
                          // Signal strength (icon); change colour depending on value
                          color: result.rssi <= -100 ? Colors.red :
                          result.rssi <= -50 ? Colors.yellow : Colors.green,
                          size: 30,
                        ),
                        Text(
                          'RSSI: ${result.rssi}',
                          // Signal strength (text); change colour depending on value
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
      // Put all list entries into a single list view
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
    // setState() causes this method to be invoked

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  // Text displayed for the scan feature
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(scanText),
                  ),
                ),
                Expanded(
                  // Text input field for the scan feature
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
                  // Button for the scan feature
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
                  // Text displayed for the calibration feature
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(calibrateText),
                  ),
                ),
                Expanded(
                  // Text input field (x-coordinate 1) for the calibration feature
                  flex: 2,
                  child: TextField(
                    controller: xMinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'xMin',
                    ),
                  ),
                ),
                Expanded(
                  // Text input field (x-coordinate 2) for the calibration feature
                  flex: 2,
                  child: TextField(
                    controller: xMaxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'xMax',
                    ),
                  ),
                ),
                Expanded(
                  // Text input field (y-coordinate 1) for the calibration feature
                  flex: 2,
                  child: TextField(
                    controller: yMinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'yMin',
                    ),
                  ),
                ),
                Expanded(
                  // Text input field (y-coordinate 2) for the calibration feature
                  flex: 2,
                  child: TextField(
                    controller: yMaxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'yMax',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    // Button for the scan feature
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: onCalibratePressed,
                      child: Center(
                        child: Icon(Icons.save),
                      ),
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
                  child: Text(
                    scanCurrentText,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  // Display number of current scan
                  '$scanCurrent',
                  style: Theme.of(context).textTheme.headline4,
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('/'),
                ),
                Text(
                  // Display number of total scans
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
            // Add the list view that contains all device entries
            buildScanWidget(),
          ],
        ),
      ),
    );
  }
}

class ResultRoute extends StatelessWidget {
  // Route that displays collected results after all scans are completed

  // Strings
  final String title = 'BLE Scanning Results';
  final String orderRawText = 'Detection Order (Raw Data)';
  final String rssiRawText = 'Signal Strength (Raw Data)';
  final String clipboardText = 'Copy to Clipboard ...';

  Expanded buildResultWidget() {
    List<Container> containers = [];
    // For every discovered device, create an own list entry
    order.forEach((key, value) {
      containers.add(
        Container(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  // Display device identifier
                  '$key',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Display total amount of times a device was detected
                  Padding(
                    padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                    child: Text('Times Detected:'),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                    child: Text('${value.length}'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Display best detection order
                  Padding(
                    padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                    child: Text('Detection Order (best):'),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                    child: Text('${getMin(value)}'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Display worst detection order
                  Padding(
                    padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                    child: Text('Detection Order (worst):'),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                    child: Text('${getMax(value)}'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Display average detection order
                  Padding(
                    padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                    child: Text('Detection Order (average):'),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                    child: Text('${getAvg(value)}'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Display best signal strength
                  Padding(
                    padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                    child: Text('Signal Strength (best):'),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                    child: Text('${getMax(rssi[key])}'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Display worst signal strength
                  Padding(
                    padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                    child: Text('Signal Strength (worst):'),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                    child: Text('${getMin(rssi[key])}'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Display average signal strength
                  Padding(
                    padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                    child: Text('Signal Strength (average):'),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                    child: Text('${getAvg(rssi[key])}'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Display estimated distance calculated by the application
                  Padding(
                    padding: EdgeInsets.fromLTRB(30, 0, 0, 10),
                    child: Text('Estimated Distance (metres):'),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 30, 10),
                    child: Text(getDistance(getAvg(rssi[key]))),
                  ),
                ],
              ),
              // If a device was discovered more than once, add a graph (order detection)
              value.length > 1 ?
              LineGraph(
                features: [
                  Feature(
                    color: Colors.blue,
                    data: getData(value),
                  ),
                ],
                size: Size(400, 200),
                // Steps on x-axis
                labelX: getLabelX(value),
                // Steps on y-axis
                labelY: getLabelY(value),
                showDescription: false,
                graphColor: Colors.black,
                graphOpacity: 0.5,
              )
              : Container(),
              // If a device was discovered more than once, add a graph (signal strength)
              value.length > 1 ?
              LineGraph(
                features: [
                  Feature(
                    color: Colors.blue,
                    data: getData(rssi[key]),
                  ),
                ],
                size: Size(400, 200),
                // Steps on x-axis
                labelX: getLabelX(rssi[key]),
                // Steps on y-axis
                labelY: [
                  '${(getMax(rssi[key]) + getMin(rssi[key])) / 2}',
                  '${getMax(rssi[key])}'
                ],
                showDescription: false,
                graphColor: Colors.black,
                graphOpacity: 0.5,
              )
              : Container(),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
              ),
              Divider(
                thickness: 5,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      );
    });
    ListView listView = new ListView(
      children: <Widget>[
        // Add all list entries into a single list view
        ...containers,
      ],
    );
    return new Expanded(
      flex: 3,
      child: listView,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: ListView(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Text(
                      // Display collected raw data (order detection)
                      orderRawText,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      // Button to copy data to clipboard
                      onPressed: onClipboardPressed('order'),
                      child: Text(clipboardText),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('$order'),
                ),
                Divider(
                  thickness: 10,
                  height: 20,
                  color: Colors.blue,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Text(
                      // Display collected raw data (signal strength)
                      rssiRawText,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      // Button to copy data to clipboard
                      onPressed: onClipboardPressed('rssi'),
                      child: Text(clipboardText),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('$rssi'),
                ),
              ],
            ),
          ),
          Divider(
            thickness: 10,
            height: 20,
            color: Colors.blue,
          ),
          // Add list view containing all list entries
          buildResultWidget(),
        ],
      ),
    );
  }

  onClipboardPressed(String string) {
    // Copy raw data to clipboard

    switch(string) {
      case 'order':
        // Copy order detection raw data
        Clipboard.setData(ClipboardData(text: '$order'));
        return;
      case 'rssi':
        // Copy signal strength raw data
        Clipboard.setData(ClipboardData(text: '$rssi'));
        return;
    }
  }

  int getMin(List<int> ints) {
    // Return the minimal value of a list
    return ints.reduce(min);
  }

  int getMax(List<int> ints) {
    // Return the maximal value of a list
    return ints.reduce(max);
  }

  double getAvg(List<int> ints) {
    // Return the average value (mean) of a list
    return ints.reduce((a, b) => a + b) / ints.length;
  }

  List<double> getData(List<int> ints) {
    double min = getMin(ints).toDouble();
    double max = getMax(ints).toDouble();
    // Data to be displayed in the graph
    List<double> data = [];
    ints.forEach((element) {
      if(min == max) {
        // Special case, because max-min would result in division by zero
        data.add(1);
      }
      else {
        // Normalise data, so that the max value matches the top of the graph
        data.add((element.toDouble() - min) / (max - min));
      }
    });
    return data;
  }

  List<String> getLabelX(List<int> ints) {
    List<String> data = [];
    int counter = 0;
    ints.forEach((element) {
      // Add increments of one to the x-axis
      data.add('$counter');
      counter++;
    });
    return data;
  }

  List<String> getLabelY(List<int> ints) {
    List<String> data = [];
    if(getMax(ints) != getMin (ints)) {
      // Add four labels to the y-axis: 25%, 50%, 75% and 100% of max value
      data.add('${getMax(ints) / 4}');
      data.add('${getMax(ints) / 2}');
      data.add('${3 * getMax(ints) / 4}');
    }
    data.add('${getMax(ints)}');
    return data;
  }

  String getDistance(double avg) {
    // If no calibration was conducted, the distance estimation returns 'unknown'
    if (xMin == null || xMax == null || yMin == null || yMax == null) {
      return 'unknown';
    }
    else return '${m * avg + b}';
  }

}
