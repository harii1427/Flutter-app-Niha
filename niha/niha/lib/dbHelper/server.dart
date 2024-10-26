// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:niha/Home.dart'; // Ensure this path is correct to your MyHomePage and HomePage

/// Registers a new user with Firebase Authentication and stores additional data in Firestore.
Future<void> registerUser(
  BuildContext context,
  TextEditingController usernameController,
  TextEditingController emailController,
  TextEditingController passwordController,
  TextEditingController addressController,
) async {
  try {
    print('Registering user with email: ${emailController.text.trim()}');
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    String? userId = userCredential.user?.uid;

    if (userId != null) {
      print('User ID: $userId');
      // Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
        'role': 'user', // Default role is user
      });

      _showDialog(context, 'Success', 'User registered successfully.');
      // Navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      _showDialog(context, 'Error', 'User ID is null.');
    }
  } on FirebaseAuthException catch (e) {
    print('FirebaseAuthException: ${e.code} - ${e.message}');
    if (e.code == 'email-already-in-use') {
      _showDialog(context, 'Error', 'The email address is already in use.');
    } else {
      _showDialog(context, 'Registration Error',
          e.message ?? 'An unknown error occurred.');
    }
  } catch (e) {
    print('Unexpected error: $e');
    _showDialog(context, 'Error', e.toString());
  }
}

void _showDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
