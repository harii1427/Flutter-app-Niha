import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'Home.dart';
import 'register.dart';
import 'login.dart';
import 'ForgetPassword.dart';
import 'voice_command.dart';
import 'collection_name_page.dart';
import 'collection_list_page_voice.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> _getInitialRoute() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return '/home';
    } else {
      return '/login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final initialRoute = snapshot.data ?? '/login';
        return MaterialApp(
          title: 'Flutter Firebase Voice Command',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          initialRoute: initialRoute,
          routes: {
            '/home': (context) => const HomePage(),
            '/forgot_password': (context) => const ForgotPasswordScreen(),
            '/register': (context) => const NewUserPage(),
            '/login': (context) => const LoginPage(),
            '/voice': (context) =>
                const Voice(collectionName: 'defaultCollection'),
            '/collection_name': (context) => CollectionNamePage(),
            '/collection_list': (context) => const CollectionListPage(),
          },
        );
      },
    );
  }
}
