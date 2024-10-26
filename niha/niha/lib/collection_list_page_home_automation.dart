import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'collection_name_page.dart';
import 'home_automation.dart';

class CollectionListPage_homeautomation extends StatefulWidget {
  const CollectionListPage_homeautomation({super.key});

  @override
  _CollectionListPage_homeautomationState createState() => _CollectionListPage_homeautomationState();
}

class _CollectionListPage_homeautomationState extends State<CollectionListPage_homeautomation> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _collectionsStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    User? user = _auth.currentUser;

    if (user != null) {
      String userId = user.uid;
      _collectionsStream = _firestore
          .collection('users')
          .doc(userId)
          .collection('Devices')
          .snapshots();
    }
  }

  void _navigateToAutomationPage(BuildContext context, String collectionName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeAutomationPage(collectionName: collectionName),
      ),
    );
  }

  void _navigateToAddCollectionPage(BuildContext context) async {
    final nickname = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionNamePage(),
      ),
    );

    if (nickname != null) {
      // Do something with the new nickname if needed
    }
  }

  void _deleteCollection(String docId) async {
    User? user = _auth.currentUser;

    if (user != null) {
      String userId = user.uid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('Devices')
          .doc(docId)
          .delete();
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(
      context,
    ); // Pop the current page to go back to the previous one
    return true;
  }

  // void _showDeleteDialog(BuildContext context, String docId) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Delete Device'),
  //         content: Text('Are you sure you want to delete this device?'),
  //         actions: [
  //           TextButton(
  //             child: Text('Cancel'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: Text('Delete'),
  //             onPressed: () {
  //               _deleteCollection(docId);
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

    void _showDeleteDialog(BuildContext context, String docId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Device'),
              onTap: () {
                _deleteCollection(docId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
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
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select the Device',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'serif',
                ),
              ),
            ),
            const SizedBox(height: 20), // Add this SizedBox for spacing
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _collectionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Something went wrong. Please try again later.'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No devices found.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var collectionName = doc['name'];
                      var nickname = doc['nickname'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          color: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: GestureDetector(
                            onLongPress: () => _showDeleteDialog(context, doc.id),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                              leading: CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(Icons.devices, color: Colors.black),
                              ),
                              title: Text(
                                nickname,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => _navigateToAutomationPage(context, collectionName),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _navigateToAddCollectionPage(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  '+ Add device',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
