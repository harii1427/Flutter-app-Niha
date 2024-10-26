import 'package:flutter/material.dart';

class HallPage extends StatelessWidget {
  final String collectionName;

  const HallPage({Key? key, required this.collectionName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hall Appliances'),
      ),
      body: Center(
        child: Text('Appliances for $collectionName in Hall'),
      ),
    );
  }
}
