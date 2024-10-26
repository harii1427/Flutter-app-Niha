import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_details.dart'; // Import the FoodDetailPage

class HotelDetails {
  final String address;
  final String email;
  final String food;
  final String foodImageUrl;
  final String hotelName;
  final int price;

  HotelDetails({
    required this.address,
    required this.email,
    required this.food,
    required this.foodImageUrl,
    required this.hotelName,
    required this.price,
  });

  factory HotelDetails.fromMap(Map<String, dynamic> data) {
    return HotelDetails(
      address: data['Address'] ?? '',
      email: data['E-mail'] ?? '',
      food: data['Food'] ?? '',
      foodImageUrl: data['FoodImageUrl'] ?? '',
      hotelName: data['Hotel_name'] ?? '',
      price: data['Price'] ?? 0,
    );
  }
}

Future<List<HotelDetails>> fetchHotelDetails() async {
  List<HotelDetails> hotelDetailsList = [];
  try {
    final snapshot =
        await FirebaseFirestore.instance.collection('Hotel_details').get();
    for (var doc in snapshot.docs) {
      hotelDetailsList.add(HotelDetails.fromMap(doc.data()));
    }
    print("Hotel details fetched successfully");
  } catch (e) {
    print("Error fetching hotel details: $e");
  }
  return hotelDetailsList;
}

class OrderFoodPage extends StatefulWidget {
  @override
  _OrderFoodPageState createState() => _OrderFoodPageState();
}

class _OrderFoodPageState extends State<OrderFoodPage> {
  List<HotelDetails> allHotelDetails = [];
  List<HotelDetails> filteredHotelDetails = [];
  List<String> categories = [
    "Burger",
    "Pizza",
    "Biriyani",
    "Pasta",
    "Chinese",
    "Parotta"
  ];
  String selectedCategory = "";
  String searchQuery = "";
  bool isAnimated = false;
  String selectedCategoryImage = "";
  bool showImage = false;

  @override
  void initState() {
    super.initState();
    fetchHotelDetails().then((hotelDetailsList) {
      setState(() {
        allHotelDetails = hotelDetailsList;
        filteredHotelDetails = allHotelDetails;
      });
    }).catchError((error) {
      // Handle error
      print("Error fetching hotel details: $error");
    });
  }

  void filterHotels(String category, String image) {
    setState(() {
      showImage = false;
    });
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        selectedCategory = category;
        selectedCategoryImage = image;
        searchQuery = "";
        if (category.isEmpty) {
          filteredHotelDetails = allHotelDetails;
        } else {
          filteredHotelDetails = allHotelDetails
              .where((hotel) =>
                  hotel.food.toLowerCase().contains(category.toLowerCase()))
              .toList();
        }
        isAnimated = true;
        showImage = true;
      });
    });
  }

  void filterHotelsBySearch(String query) {
    setState(() {
      searchQuery = query;
      filteredHotelDetails = allHotelDetails
          .where(
              (hotel) => hotel.food.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void clearFilters() {
    setState(() {
      selectedCategory = "";
      selectedCategoryImage = "";
      searchQuery = "";
      filteredHotelDetails = allHotelDetails;
      isAnimated = false;
      showImage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 10),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => filterHotels(
                          categories[index], 'images/${categories[index]}.jpg'),
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.all(10),
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: AssetImage(
                                    'images/${categories[index]}.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Text(categories[index]),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              AnimatedContainer(
                duration: Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    AnimatedOpacity(
                      opacity: showImage ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 1000),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        width: showImage ? 80 : 0,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: AssetImage(selectedCategoryImage),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.only(left: showImage ? 10 : 0),
                        height: 50,
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: filterHotelsBySearch,
                                decoration: InputDecoration(
                                  prefixIcon: GestureDetector(
                                    child: const Icon(Icons.search),
                                  ),
                                  hintText: 'Search...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10),
                                  fillColor:
                                      const Color.fromARGB(255, 255, 255, 255),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    selectedCategory.isEmpty ? 'Recommended' : 'Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: allHotelDetails.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: ListView.builder(
                          itemCount: filteredHotelDetails.length,
                          itemBuilder: (context, index) {
                            final hotel = filteredHotelDetails[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FoodDetailPage(
                                      address: hotel.address,
                                      email: hotel.email,
                                      foodImageUrl: hotel.foodImageUrl,
                                      food: hotel.food,
                                      rating:
                                          4.5, // Replace with actual rating if available
                                      hotelName: hotel.hotelName,

                                      price: hotel.price,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(vertical: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                                child: Container(
                                  color: const Color.fromARGB(255, 255, 255,
                                      255), // Inside border color
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                                hotel.foodImageUrl),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              hotel.food,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              hotel.hotelName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Row(
                                              children: [
                                                Icon(Icons.star,
                                                    color: Colors.orange,
                                                    size: 16),
                                                SizedBox(width: 5),
                                                Text(
                                                  '4.5',
                                                  style:
                                                      TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              '₹${hotel.price}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FoodDetailPage(
                                                address: hotel.address,
                                                email: hotel.email,
                                                foodImageUrl:
                                                    hotel.foodImageUrl,
                                                food: hotel.food,
                                                rating:
                                                    4.5, // Replace with actual rating if available
                                                hotelName: hotel.hotelName,

                                                price: hotel.price,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          '+ Add',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
