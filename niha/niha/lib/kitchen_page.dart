import 'package:flutter/material.dart';

class KitchenPage extends StatelessWidget {
  final String collectionName;

  const KitchenPage({Key? key, required this.collectionName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kitchen Appliances'),
      ),
      body: Center(
        child: Text('Appliances for $collectionName in Kitchen'),
      ),
    );
  }
}
