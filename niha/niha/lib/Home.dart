import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'profile.dart';
import 'surveillance.dart';
import 'collection_list_page_home_automation.dart';
import 'collection_list_page_voice.dart';
import 'Food.dart';

Future<List<String>> fetchImagesFromFirebase() async {
  List<String> imageUrls = [];
  final storageRef = FirebaseStorage.instance.ref().child('images');

  final ListResult result = await storageRef.listAll();
  final List<Reference> allFiles = result.items;

  for (var file in allFiles) {
    final String downloadUrl = await file.getDownloadURL();
    imageUrls.add(downloadUrl);
  }

  return imageUrls;
}

Future<List<Map<String, dynamic>>> fetchProductsFromFirestore() async {
  List<Map<String, dynamic>> products = [];
  DocumentSnapshot snapshot = await FirebaseFirestore.instance
      .collection('E-commerce')
      .doc('Electronics')
      .get();

  if (snapshot.exists) {
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
    if (data != null) {
      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          value.forEach((nestedKey, nestedValue) {
            if (nestedValue is Map<String, dynamic>) {
              products.add(nestedValue);
            }
          });
        }
      });
    }
  }

  return products;
}

class ImageSlider extends StatelessWidget {
  final List<String> imageUrls;

  const ImageSlider({Key? key, required this.imageUrls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 2.0,
        height: 180,
        onPageChanged: (index, reason) {},
      ),
      items: imageUrls
          .map((item) => Container(
                child: Center(
                  child: Image.network(
                    item,
                    fit: BoxFit.cover,
                    width: 780,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  List<String> imageUrls = [];
  List<Map<String, dynamic>> products = [];
  bool _imagesFetched = false;
  bool _productsFetched = false;
  String username = '';
  String address = '';

  @override
  void initState() {
    super.initState();
    _currentIndex = 1;
    if (!_imagesFetched) {
      fetchImages();
    }
    if (!_productsFetched) {
      fetchProducts();
    }
    fetchUserData();
  }

  void fetchImages() async {
    try {
      List<String> urls = await fetchImagesFromFirebase();
      setState(() {
        imageUrls = urls;
        _imagesFetched = true;
      });
    } catch (e) {
      setState(() {
        _imagesFetched = true;
      });
    }
  }

  void fetchProducts() async {
    try {
      List<Map<String, dynamic>> fetchedProducts =
          await fetchProductsFromFirestore();
      setState(() {
        products = fetchedProducts;
        _productsFetched = true;
      });
    } catch (e) {
      setState(() {
        _productsFetched = true;
      });
    }
  }

  void fetchUserData() async {
    String userID = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userID.isNotEmpty) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'] ?? '';
          address = userDoc['address'] ?? '';
        });
      }
    }
  }

  void _onItemTapped(int index) async {
    if (index == 0) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CollectionListPage()),
      );
      if (result == null) {
        setState(() {
          _currentIndex = 1;
        });
        return;
      }
    } else if (index == 1) {
      // Home, do nothing or navigate to home if needed
    } else if (index == 2) {
      _showProfileMenu(context);
    } else if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OrdersPage()),
      );
      setState(() {
        _currentIndex =
            1; // Reset to home index after returning from OrdersPage
      });
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0:
        return Image.asset(
          'images/mic.png',
          height: 40,
          width: 40,
        );
      case 2:
        return Image.asset(
          'images/profile.png',
          height: 40,
          width: 40,
        );
      case 3:
        return Image.asset(
          'images/order.png',
          height: 40,
          width: 40,
        );
      default:
        return Image.asset(
          'images/home.png',
          height: 40,
          width: 40,
        );
    }
  }

  Future<void> _showProfileMenu(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('My profile'),
                onTap: () {
                  Navigator.pop(context, 'profile');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Profile(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () {
                  Navigator.pop(context, 'signout');
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        _currentIndex = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Niha',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cursive',
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 15, 94, 205),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu,
                color: Color.fromARGB(255, 255, 255, 255)),
            onSelected: (String result) {
              if (result == 'Home Automation') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const CollectionListPage_homeautomation()),
                );
              } else if (result == 'Surveillance') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SurveillancePage()),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'Home Automation',
                child: Text('Home Automation'),
              ),
              const PopupMenuItem<String>(
                value: 'Surveillance',
                child: Text('Surveillance'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(100.0), // here the desired height
          child: Column(
            children: [
              Container(
                color: const Color.fromARGB(255, 15, 94, 205),
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: GestureDetector(
                      child: const Icon(Icons.search),
                    ),
                    hintText: 'Search...',
                    suffixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
              if (username.isNotEmpty && address.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          color: const Color.fromARGB(255, 255, 255, 255)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Deliver to $username - $address',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(
                      'Special Offers',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ]),
                  Row(
                    children: [
                      SizedBox(width: 15),
                      Text(
                        'View more>',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 64, 64, 64),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (!_imagesFetched) Center(child: CircularProgressIndicator()),
            if (imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ImageSlider(imageUrls: imageUrls),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 10, 10, 10),
              child: Text(
                'Experience seamless services of Niha',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(
                      'Categories',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ]),
                  Row(
                    children: [
                      SizedBox(width: 15),
                      Text(
                        'View more>',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 64, 64, 64),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildCategoryItem(
                      context, 'images/food.jpg', 'Food', OrderFoodPage()),
                  _buildCategoryItem(context, 'images/electronics.jpg',
                      'Electronics', OrderElectronicsPage()),
                  _buildCategoryItem(context, 'images/mobiles.jpg', 'Mobiles',
                      OrderPhonePage()),
                  _buildCategoryItem(context, 'images/medicines.jpg',
                      'Medicine', OrderMedicinePage()),
                  _buildCategoryItem(context, 'images/fashion.jpg', 'Fashion',
                      OrderFashionPage()),
                  _buildCategoryItem(context, 'images/Appliances.jpg',
                      'Appliances', OrderProductsPage()),
                  _buildCategoryItem(context, 'images/Groceries.jpg',
                      'Groceries', OrderGroceriesPage()),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(
                      'Daily deals',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ]),
                  Row(
                    children: [
                      SizedBox(width: 15),
                      Text(
                        'View more>',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 64, 64, 64),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            if (!_productsFetched) Center(child: CircularProgressIndicator()),
            if (products.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: _buildProductRows(context, products),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 1;
          });
        },
        child: _buildFloatingActionButton(),
        backgroundColor: Color.fromARGB(208, 0, 0, 0),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0)), // Add this line
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
      bottomNavigationBar: Container(
        height: 60, // Desired height
        child: BottomAppBar(
          shape: CircularNotchedRectangle(),
          notchMargin: 5.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                  _onItemTapped(0);
                },
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Image.asset(
                    'images/mic.png', // Replace with your asset path
                    height: 30, // Reduced image size
                    width: 30, // Reduced image size
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                  _onItemTapped(2);
                },
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Image.asset(
                    'images/profile.png', // Replace with your asset path
                    height: 30, // Reduced image size
                    width: 30, // Reduced image size
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                  _onItemTapped(3);
                },
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Image.asset(
                    'images/order.png', // Replace with your asset path
                    height: 30, // Reduced image size
                    width: 30, // Reduced image size
                  ),
                ),
              ),
            ],
          ),
          color: Color.fromARGB(228, 0, 0, 0),
        ),
      ),
    );
  }

  List<Widget> _buildProductRows(
      BuildContext context, List<Map<String, dynamic>> products) {
    List<Widget> rows = [];
    for (int i = 0; i < products.length; i += 2) {
      List<Widget> rowChildren = [];
      rowChildren
          .add(Expanded(child: _buildDailyDealItem(context, products[i])));
      if (i + 1 < products.length) {
        rowChildren.add(
            Expanded(child: _buildDailyDealItem(context, products[i + 1])));
      } else {
        rowChildren
            .add(Expanded(child: Container())); // Placeholder for alignment
      }
      rows.add(Row(children: rowChildren));
    }
    return rows;
  }

  Widget _buildCategoryItem(
      BuildContext context, String imageName, String label, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        ).then((_) {
          setState(() {
            _currentIndex = 1; // Reset to home index after returning from page
          });
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: [
            Container(
              width: 72, // Width of the rectangular image
              height: 72, // Height of the rectangular image
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
                image: DecorationImage(
                  image: AssetImage(imageName),
                  fit: BoxFit.cover, // Ensure the image covers the container
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyDealItem(
      BuildContext context, Map<String, dynamic> product) {
    String imageUrl = product['ImageUrl'] ?? ''; // Safe null access
    String name = product['Name'] ?? 'No Name';
    String price = product['Price']?.toString() ?? '0';

    return GestureDetector(
      onTap: () {
        // Navigate to product detail page if needed
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
        child: Column(
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '₹$price',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0F5ECD),
              ),
              onPressed: () {
                // Handle buy button click
              },
              child: Text(
                'Buy',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderGroceriesPage extends StatelessWidget {
  const OrderGroceriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class OrderPhonePage extends StatelessWidget {
  const OrderPhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class OrderElectronicsPage extends StatelessWidget {
  const OrderElectronicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Electronics",
        ),
      ),
    );
  }
}

class OrderMedicinePage extends StatelessWidget {
  const OrderMedicinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(
      "Medicines",
    )));
  }
}

class OrderFashionPage extends StatelessWidget {
  const OrderFashionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class OrderProductsPage extends StatelessWidget {
  const OrderProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
      ),
      body: Center(
        child: Text('Orders Page Content'),
      ),
    );
  }
}
