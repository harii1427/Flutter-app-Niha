import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollectionNamePage extends StatelessWidget {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionNamePage({super.key});

  void _saveCollectionName(BuildContext context) async {
    User? user = _auth.currentUser;

    if (user != null) {
      String userId = user.uid;
      String deviceName = _deviceNameController.text;
      String nickname = _nicknameController.text;

      // Check if the device name or nickname already exists under the user's collection
      var existingDevices = await _firestore
          .collection('users')
          .doc(userId)
          .collection('Devices')
          .where('name', isEqualTo: deviceName)
          .get();

      var existingNicknames = await _firestore
          .collection('users')
          .doc(userId)
          .collection('Devices')
          .where('nickname', isEqualTo: nickname)
          .get();

      if (existingDevices.docs.isEmpty && existingNicknames.docs.isEmpty) {
        // If the device name and nickname do not exist, save it
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('Devices')
            .add({
          'name': deviceName,
          'nickname': nickname,
        });
        Navigator.pop(context, nickname); // Pass the new nickname back
      } else {
        // If the device name or nickname exists, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device name or nickname already exists.')),
        );
      }
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    Navigator.pop(context);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            child: AppBar(
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 15, 94, 205),
                ),
              ),
              title: const Text(
                'Niha',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cursive',
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  'Add Device',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _deviceNameController,
                decoration: const InputDecoration(labelText: 'Enter the device code'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: 'Enter the nickname'),
              ),
              const SizedBox(height: 50),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    _saveCollectionName(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 15, 94, 205), // Background color
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
