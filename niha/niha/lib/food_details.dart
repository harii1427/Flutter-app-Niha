import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_confirmation.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';

class FoodDetailPage extends StatefulWidget {
  final String address;
  final String email;
  final String food;
  final double rating;
  final String foodImageUrl;
  final String hotelName;
  final int price;

  FoodDetailPage({
    required this.address,
    required this.email,
    required this.food,
    required this.rating,
    required this.foodImageUrl,
    required this.hotelName,
    required this.price,
  });

  @override
  _FoodDetailPageState createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  int quantity = 1;
  User? user;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _imageOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _imageOpacity = 1.0;
      });
    });
  }

  void _sendCommandToFirestore(String command) {
    if (user != null) {
      _firestore.collection('commands').add({
        'command': command,
        'userId': user!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      print("User not authenticated");
    }
  }

  void _handleBuyNow() {
    String command = "order $quantity ${widget.food}";
    _sendCommandToFirestore(command);

    // Navigate to the scooter animation page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderConfirmationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AnimatedOpacity(
                  opacity: _imageOpacity,
                  duration: Duration(seconds: 2),
                  child: ClipPath(
                    clipper: OvalBottomBorderClipper(),
                    child: Container(
                      height: 580, // Increased height of the image
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(widget.foodImageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.food,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 20),
                      SizedBox(width: 5),
                      Text(
                        widget.rating.toString(),
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.hotelName,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20), // Adjust spacing as needed
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '₹${widget.price * quantity}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (quantity > 1) {
                                      setState(() {
                                        quantity--;
                                      });
                                    }
                                  },
                                  icon: Icon(Icons.remove, size: 20),
                                ),
                                Text(
                                  quantity.toString(),
                                  style: TextStyle(fontSize: 18),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      quantity++;
                                    });
                                  },
                                  icon: Icon(Icons.add, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _handleBuyNow,
                        child: Text(
                          'BUY NOW',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 29, 29, 29),
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
