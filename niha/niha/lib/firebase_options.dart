// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBecrsfBVRVCEDSPu9QtOkBcOebO50NJLk',
    appId: '1:999273367121:web:fa0246b92171f319635a70',
    messagingSenderId: '999273367121',
    projectId: 'niha-5d949',
    authDomain: 'niha-5d949.firebaseapp.com',
    databaseURL: 'https://niha-5d949-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'niha-5d949.appspot.com',
    measurementId: 'G-40BDX0Q1DB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA54gW1-TPCRUr7vPfzYefvV2D-U3_UNB0',
    appId: '1:999273367121:android:934f3394a9aa43c7635a70',
    messagingSenderId: '999273367121',
    projectId: 'niha-5d949',
    databaseURL: 'https://niha-5d949-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'niha-5d949.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCciOet4qjt_N2sR8YgFGDKat8mKKlAQV0',
    appId: '1:999273367121:ios:bae5f853e7c2389e635a70',
    messagingSenderId: '999273367121',
    projectId: 'niha-5d949',
    databaseURL: 'https://niha-5d949-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'niha-5d949.appspot.com',
    iosBundleId: 'com.example.niha',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCciOet4qjt_N2sR8YgFGDKat8mKKlAQV0',
    appId: '1:999273367121:ios:bae5f853e7c2389e635a70',
    messagingSenderId: '999273367121',
    projectId: 'niha-5d949',
    databaseURL: 'https://niha-5d949-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'niha-5d949.appspot.com',
    iosBundleId: 'com.example.niha',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBecrsfBVRVCEDSPu9QtOkBcOebO50NJLk',
    appId: '1:999273367121:web:d9c418f6e3877c24635a70',
    messagingSenderId: '999273367121',
    projectId: 'niha-5d949',
    authDomain: 'niha-5d949.firebaseapp.com',
    databaseURL: 'https://niha-5d949-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'niha-5d949.appspot.com',
    measurementId: 'G-L7057Z3JJD',
  );
}
