import 'package:flutter/material.dart';

class BathroomPage extends StatelessWidget {
  final String collectionName;

  const BathroomPage({Key? key, required this.collectionName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bathroom Appliances'),
      ),
      body: Center(
        child: Text('Appliances for $collectionName in Bathroom'),
      ),
    );
  }
}
