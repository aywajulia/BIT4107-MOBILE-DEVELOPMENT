import 'package:flutter/material.dart'; // imports flutter widgets

void main() { // where code starts
  runApp( // asks flutter to run the app
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.yellowAccent, // app background color
        body: Center( // alignment
          child: Column( // stacks widgets vertically
            mainAxisSize: MainAxisSize.min, // takes minimum space
            children: [
              const Text( // app text
                'ROTTEN MANGO',
                style: TextStyle(fontSize: 40, color: Colors.indigo), // text format
              ),
              const SizedBox(height: 20), // adds space between text and button
              ElevatedButton( // button widget
                onPressed: () {
                  // action when button is pressed
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Play Episode 1'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}