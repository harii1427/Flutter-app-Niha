import 'package:flutter/material.dart';

class BedroomPage extends StatelessWidget {
  final String collectionName;

  const BedroomPage({Key? key, required this.collectionName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bedroom Appliances'),
      ),
      body: Center(
        child: Text('Appliances for $collectionName in Bedroom'),
      ),
    );
  }
}
