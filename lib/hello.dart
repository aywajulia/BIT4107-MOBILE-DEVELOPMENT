import 'package:flutter/material.dart'; // imports flutter widgets

void main() { // where code starts
  runApp( // asks flutter to run app
    MaterialApp(
      home: Material(
        color: Colors.green, // background color
        child: Center(
          child: Column( // stacks widgets vertically
            mainAxisSize: MainAxisSize.min, // takes minimum space
            children: [
              Text(
                'HELLO WORLD',
                style: TextStyle(fontSize: 40, color: Colors.white), // text format
              ),
              SizedBox(height: 20), // adds space between text and button
              ElevatedButton(
                onPressed: () {
                  // prints when clicked
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // button background color
                  foregroundColor: Colors.green, // button text color
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('I\'m Julia'), // note the escaped apostrophe
              ),
            ],
          ),
        ),
      ),
    ),
  );
}