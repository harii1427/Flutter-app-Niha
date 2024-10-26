import 'package:flutter/material.dart';

class LivingRoomPage extends StatelessWidget {
  final String collectionName;

  const LivingRoomPage({Key? key, required this.collectionName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Living room Appliances'),
      ),
      body: Center(
        child: Text('Appliances for $collectionName in Living room'),
      ),
    );
  }
}
