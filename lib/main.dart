import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Wrapper.dart';
import 'authentication/login.dart';
import 'route_observer/route_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyD7Fc89uplZmtvY-5nI85MawnZCpUbG16Y',
      authDomain: 'foundit-11ed6.firebaseapp.com',
      projectId: 'foundit-11ed6',
      storageBucket: 'foundit-11ed6.appspot.com',
      messagingSenderId: '853057745672',
      appId: '1:853057745672:web:5a5a5a5',
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fountit',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      initialRoute: '/',
      routes: {
        '/': (context) => Wrapper(),
        '/login': (context) => Login(),
      },
    );
  }
}
