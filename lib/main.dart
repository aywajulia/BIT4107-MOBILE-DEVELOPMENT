// This file initializes and starts the entire application
import 'package:flutter/material.dart';
import 'login.dart';  // Import the login screen

// Main function - this is where the app starts execution
void main() {
  runApp(const MyApp());  // runApp() displays the Flutter app on screen
}

// MyApp class - The root widget that contains the whole application
// StatelessWidget means this widget cannot change once built
class MyApp extends StatelessWidget {
  const MyApp({super.key});  // Constructor

  // build() method - This designs what the app looks like
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Management App',  // App title shown in task manager

      // ThemeData - Controls the visual styling of the entire app
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,  // Adapts to different screen sizes
        useMaterial3: true,  // Uses latest Material Design 3
      ),

      home: const LoginScreen(),  // First screen users see when app opens
      debugShowCheckedModeBanner: false,  // Hides the debug banner in top right corner
    );
  }
}