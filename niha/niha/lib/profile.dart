import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isEditing = false;
  File? _profileImage;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
      }
    });
  }

  Future<String> _uploadProfileImage() async {
    if (_profileImage == null) return '';

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child(currentUser!.uid);

    await storageRef.putFile(_profileImage!);

    return await storageRef.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    final String uid = currentUser!.uid;
    final DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(uid);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F5ECD),
        title: Row(
          children: [
            Text(
              'Niha',
              style: TextStyle(
                fontFamily: 'Cursive',
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

          ],
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: userDoc.get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found'));
          }

          Map<String, dynamic> data =
              snapshot.data!.data()! as Map<String, dynamic>;
          if (!isEditing) {
            usernameController.text = data['username'] ?? '';
            emailController.text = data['email'] ?? '';
            phoneController.text = data['phone'] ?? '';
            addressController.text = data['address'] ?? '';
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Serif',
                          ),
                        ),
                        SizedBox(height: 20),
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: isEditing ? _pickImage : null,
                              child: CircleAvatar(
                                radius: 90,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : data['profileImageUrl'] != null
                                        ? NetworkImage(data['profileImageUrl'])
                                        : AssetImage(
                                            'assets/default_profile.png')
                                            as ImageProvider,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 4.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: CircleAvatar(
                                    backgroundColor: Color(0xFF0F5ECD),
                                    radius: 20,
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Container(
                          height: 2,
                          width: 300,
                          color: Color(0xFF0F5ECD),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 50),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'User name',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !isEditing,
                  ),
                  SizedBox(height: 30),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !isEditing,
                  ),
                  SizedBox(height: 30),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !isEditing,
                  ),
                  SizedBox(height: 30),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !isEditing,
                  ),
                  SizedBox(height: 40),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0F5ECD),
                        padding: EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                      ),
                      onPressed: () async {
                        if (isEditing) {
                          String profileImageUrl = _profileImage != null
                              ? await _uploadProfileImage()
                              : data['profileImageUrl'] ?? '';
                          await userDoc.update({
                            'username': usernameController.text,
                            'email': emailController.text,
                            'phone': phoneController.text,
                            'address': addressController.text,
                            'profileImageUrl': profileImageUrl,
                          });
                        }
                        setState(() {
                          isEditing = !isEditing;
                        });
                      },
                      child: Text(
                        isEditing ? 'SAVE' : 'EDIT',
                        style: TextStyle(fontSize: 18,color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
