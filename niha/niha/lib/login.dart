import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:niha/Home.dart';
import 'register.dart';
import 'controllers/user_controller.dart';
import 'package:twitter_login/twitter_login.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailOrPhoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isObscure = true;
  late TabController _tabController;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    emailOrPhoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void togglePasswordVisibility() {
    setState(() {
      isObscure = !isObscure;
    });
  }

  Future<void> _handleTwitterSignIn() async {
    try {
      final twitterLogin = TwitterLogin(
          apiKey: 'SVTrzjB8VFu3EVb7OCHPzhiQL',
          apiSecretKey: 'nXHZyLKKrbSccUW4gPyBfxxbUWjzfuqQ1lgYn2PLUsmey0EVS5',
          redirectURI: 'Niha://' // Replace with your custom scheme
          );

      final authResult = await twitterLogin.login();

      if (authResult.status == TwitterLoginStatus.loggedIn) {
        final twitterAuthCredential = TwitterAuthProvider.credential(
          accessToken: authResult.authToken!,
          secret: authResult.authTokenSecret!,
        );

        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(twitterAuthCredential);

        if (userCredential.user != null) {
          await _storeUserData(userCredential.user!);
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()));
        }
      } else {
        print('Twitter login failed: ${authResult.errorMessage}');
      }
    } catch (e) {
      print('Twitter Sign-In Error: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final user = await UserController.loginWithGoogle();
      if (user != null && mounted) {
        await _storeUserData(user);
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()));
      }
    } on FirebaseAuthException catch (error) {
      print(error.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        error.message ?? "Something went wrong",
      )));
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        error.toString(),
      )));
    }
  }

  Future<void> _storeUserData(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      await userDoc.set({
        'email': user.email,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error storing user data: $e');
    }
  }

  Future<String?> _getEmailFromPhoneNumber(String phoneNumber) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      final List<DocumentSnapshot> documents = result.docs;
      if (documents.isNotEmpty) {
        return documents.first['email'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> login() async {
    String emailOrPhone = emailOrPhoneController.text.trim();
    String password = passwordController.text.trim();

    if (emailOrPhone.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please fill in all fields.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    String? email;

    if (emailOrPhone.contains('@')) {
      email = emailOrPhone;
    } else {
      email = await _getEmailFromPhoneNumber(emailOrPhone);
    }

    if (email == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('No account found for this phone number.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Invalid email-id.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget buildLoginTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            controller: emailOrPhoneController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Email Address',
              prefixIcon: Icon(Icons.email),
              hintStyle: TextStyle(
                fontSize: 18.0,
                color: Colors.grey,
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 250,
          child: TextField(
            controller: passwordController,
            obscureText: isObscure,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              hintStyle: const TextStyle(
                fontSize: 18.0,
                color: Colors.grey,
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: togglePasswordVisibility,
                icon: Icon(
                  isObscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 250,
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/forgot_password');
            },
            child: const Text(
              'Forget password?',
              style: TextStyle(
                fontSize: 14.0,
                color: Color.fromARGB(255, 34, 90, 187),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 200,
          height: 45,
          child: MaterialButton(
            onPressed: login,
            color: const Color.fromARGB(255, 15, 94, 205), // Adjust button color as necessary
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('or connect with'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Image.asset(
                'images/google_logo.png',
                height: 60,
              ),
              onPressed: () {
                _handleGoogleSignIn();
              },
            ),
            const SizedBox(width: 20), // Add some space between the icons
            IconButton(
              icon: Image.asset(
                'images/twitter.png',
                height: 52,
              ),
              onPressed: () {
                _handleTwitterSignIn();
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: Color.fromARGB(255, 15, 94, 205),),
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
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 300,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Niha',
                  style: TextStyle(
                    fontSize: 46.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cursive',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),
                TabBar(
                  controller: _tabController,
                  labelColor: Color.fromARGB(255, 15, 94, 205),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color.fromARGB(255, 15, 94, 205),
                  tabs: const [
                    Tab(text: 'Login'),
                    Tab(text: 'Register'),
                  ],
                ),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      buildLoginTab(),
                      const NewUserPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomPaint(
        painter: BottomWavePainter(),
        child: Container(height: 60), // Adjust height as needed
      ),
    );
  }
}

class BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 15, 94, 205)
      ..style = PaintingStyle.fill;

    Path path = Path()
      ..moveTo(0, 20)
      ..quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 20)
      ..quadraticBezierTo(size.width * 0.75, 40, size.width, 20)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
