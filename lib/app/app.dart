import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Main application widget that serves as the root of our widget tree
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Road Data Collector Coming Soon')),
      ),
    );
  }
}
