// File generated via FlutterFire CLI.
// You should run `flutterfire configure` to generate the correct file for your project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBnPw-MRsZ73O74vFsghoF5Yz6qDg3pJJY',
    appId: '1:437694016028:android:19bad37a6e374035458dd9',
    messagingSenderId: '437694016028',
    projectId: 'tmconnect-367fe',
    storageBucket: 'tmconnect-367fe.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBnPw-MRsZ73O74vFsghoF5Yz6qDg3pJJY',
    appId: '1:437694016028:ios:placeholder',
    messagingSenderId: '437694016028',
    projectId: 'tmconnect-367fe',
    storageBucket: 'tmconnect-367fe.firebasestorage.app',
    iosBundleId: 'com.truckmitr.employee',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBnPw-MRsZ73O74vFsghoF5Yz6qDg3pJJY',
    appId: '1:437694016028:ios:placeholder',
    messagingSenderId: '437694016028',
    projectId: 'tmconnect-367fe',
    storageBucket: 'tmconnect-367fe.firebasestorage.app',
    iosBundleId: 'com.truckmitr.employee',
  );
}
