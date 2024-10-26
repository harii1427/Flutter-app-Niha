import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeAutomationPage extends StatefulWidget {
  final String collectionName;

  const HomeAutomationPage({super.key, required this.collectionName});

  @override
  _HomeAutomationPageState createState() => _HomeAutomationPageState();
}

class _HomeAutomationPageState extends State<HomeAutomationPage> {
  final String userId = 'Appliances'; // Replace with actual user ID
  final List<String> _appliances = [];
  final Map<String, bool> _applianceStates = {};

  @override
  void initState() {
    super.initState();
    _fetchInitialState();
  }

  void _fetchInitialState() async {
    // Fetch all appliances from the Appliances collection
    QuerySnapshot appliancesSnapshot = await FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(userId)
        .collection('Appliances')
        .get();

    List<String> fetchedAppliances =
        appliancesSnapshot.docs.map((doc) => doc.id).toList();

    for (String appliance in fetchedAppliances) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(userId)
          .collection('home_automation')
          .doc('${appliance}_status')
          .get();

      if (snapshot.exists) {
        setState(() {
          _applianceStates[appliance] = snapshot['state'] == 'on';
        });

        FirebaseFirestore.instance
            .collection(widget.collectionName)
            .doc(userId)
            .collection('home_automation')
            .doc('${appliance}_status')
            .snapshots()
            .listen((documentSnapshot) {
          if (documentSnapshot.exists) {
            setState(() {
              _applianceStates[appliance] =
                  documentSnapshot['state'] == 'on';
            });
          }
        });
      }

      setState(() {
        _appliances.add(appliance);
      });
    }
  }

  void _updateState(String device, bool state) {
    setState(() {
      _applianceStates[device] = state;
    });

    // Update state in Firestore
    FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(userId)
        .collection('home_automation')
        .doc('${device}_status')
        .set({
      'state': state ? 'on' : 'off',
    });
  }

  void _showAddApplianceDialog() {
    String newAppliance = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Add Appliance',
            style: TextStyle(fontFamily: 'serif'),
          ),
          content: TextField(
            onChanged: (value) {
              newAppliance = value;
            },
            decoration: const InputDecoration(hintText: "Enter appliance name"),
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('ADD'),
              onPressed: () {
                setState(() {
                  _appliances.add(newAppliance);
                  _applianceStates[newAppliance] = false;
                });
                // Save the new appliance state in Firestore
                FirebaseFirestore.instance
                    .collection(widget.collectionName)
                    .doc(userId)
                    .collection('home_automation')
                    .doc('${newAppliance}_status')
                    .set({
                  'state': 'off',
                });

                // Store the new appliance in the specified collection
                FirebaseFirestore.instance
                    .collection(widget.collectionName)
                    .doc(userId)
                    .collection('Appliances')
                    .doc(newAppliance)
                    .set({
                  'name': newAppliance,
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteOption(String appliance) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Appliance'),
              onTap: () {
                _deleteAppliance(appliance);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteAppliance(String appliance) {
    setState(() {
      _appliances.remove(appliance);
      _applianceStates.remove(appliance);
    });

    // Delete appliance state from Firestore
    FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(userId)
        .collection('home_automation')
        .doc('${appliance}_status')
        .delete();

    // Remove the appliance from the Appliances collection
    FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(userId)
        .collection('Appliances')
        .doc(appliance)
        .delete();
  }

  Widget _buildApplianceCard(String appliance, bool state) {
    String onText = '${_capitalize(appliance)} on';
    String offText = '${_capitalize(appliance)} off';

    return GestureDetector(
      onLongPress: () => _showDeleteOption(appliance),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: state
              ? null // Use gradient color when state is true
              : const Color.fromARGB(
                  224, 0, 0, 0), // Use solid color when state is false
          gradient: state
              ? const LinearGradient(
                  colors: [
                    Color.fromARGB(227, 26, 26, 26),
                    Color.fromARGB(255, 25, 121, 255),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null, // No gradient when state is false
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Add this
          children: [
            Row(
              children: [
                Icon(
                  Icons.power_settings_new,
                  color: state ? Colors.yellow : Colors.white,
                  size: 35,
                ),
                const SizedBox(
                    width: 10), // Add some space between the icon and the text
                Text(
                  _capitalize(appliance),
                  style: TextStyle(
                    color: state ? Colors.white : Colors.grey,
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
            const Spacer(), // Add a spacer to push the switch to the bottom
            Text(
              state ? onText : offText,
              style: TextStyle(
                color: state ? Colors.white : Colors.grey,
                fontSize: 16.0,
              ),
            ),
            Transform.scale(
              scale: 0.7, // Reduce the size of the switch
              child: Switch(
                value: state,
                onChanged: (bool value) {
                  _updateState(appliance, value);
                },
                activeColor: Colors.yellow,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.white30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // Increased padding
        child: Column(
          children: [
            const Text(
              'Control your house using Niha',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontFamily: "serif",
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
                child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1, // Set this to 1 for a square shape
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
              ),
              itemCount: _appliances.length,
              itemBuilder: (context, index) {
                String appliance = _appliances[index];
                bool applianceState = _applianceStates[appliance] ?? false;

                return _buildApplianceCard(appliance, applianceState);
              },
            )),
            ElevatedButton(
              onPressed: _showAddApplianceDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(224, 0, 0, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
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
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) {
      return s;
    }
    return s[0].toUpperCase() + s.substring(1);
  }
}
