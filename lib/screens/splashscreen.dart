import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rakshak/globalscaffold/global_scaffold.dart';
import 'package:lottie/lottie.dart';
import 'package:rakshak/screens/auth/login_screen.dart';
import 'package:rakshak/screens/auth/user_data.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: MediaQuery.of(context).size.width * 0.6,
            ),
            LottieBuilder.asset(
              'assets/animations/dots.json',
              height: MediaQuery.of(context).size.width * 0.5,
              fit: BoxFit.fill,
            ),
          ],
        ),
      ),
    );
  }

  void checkUserData(String uid, BuildContext context) async {
    final doc = await FirebaseFirestore.instance.collection("userData").doc(uid).get();
    print(doc.exists);
    if(!context.mounted)return;
    if (doc.exists) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalScaffold()));
    } else {
      print("user data not found : $uid");
      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserDataScreen()));
    }
  }

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 1), () {
      // Navigator.pushReplacement(
      //     context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        print("User state changed: $user");
        if (user == null) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const LoginScreen()));
        } else {
          checkUserData(user.uid, context);
        }
      });
    });
  }
}
