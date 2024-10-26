import 'package:flutter/material.dart';

class SurveillancePage extends StatelessWidget {
  const SurveillancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveillance'),
      ),
      body: const Center(
        child: Text('Surveillance Page'),
      ),
    );
  }
}
