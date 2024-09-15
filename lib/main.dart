import 'package:fit_equipment/devices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMS TECHNOLOGY',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple[400],
          //background: Colors.deepPurple[400],
        ),
        useMaterial3: true,
      ),

      home: const DevicesListScreen(
        isBack: false,
      ),
      //home: const DeviceScreen(),
    );
  }
}
