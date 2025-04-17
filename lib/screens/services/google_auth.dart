import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuth {
  static Future<UserCredential?> signIn() async {
    try {
      await GoogleSignIn().signOut(); // Explicitly sign out first (optional)
      final GoogleSignInAccount? googleSignIn = await GoogleSignIn().signIn();
      print('GoogleSignInAccount: $googleSignIn');
      final GoogleSignInAuthentication? googleAuth = await googleSignIn?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
      // print('GoogleSignInAuthentication: $googleAuth');
      //   if (googleAuth != null) {
      //     // Check for successful authentication
      //     final credential = GoogleAuthProvider.credential(
      //       accessToken: googleAuth.accessToken,
      //       idToken: googleAuth.idToken,
      //     );
      //     return await FirebaseAuth.instance.signInWithCredential(credential);
      // if (googleSignIn != null) {
      //   } else {
      //     print('Google Sign-In authentication failed');
      //     return null;
      //   }
      // } else {
      //   print('Google Sign-In cancelled');
      //   return null;
      // }
    } catch (error) {
      print('Error signing in: $error');
      return null;
    }
  }

  static Future<String?> signUp({
    required String fname,
    required String lname,
    required String phno,
  }) async {
    try {
      final userCred = await GoogleAuth.signIn();
      if (userCred == null) {
        print("usercred is null");
      }
      if (userCred != null) {
        // Check if user signed in successfully
        await writeUserDataToFirestore(userCred.user!, fname, lname, phno);
        return null;
      } else {
        return 'Sign-in cancelled';
      }
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> writeUserDataToFirestore(
      User user, String fname, String lname, String phno) async {
    final docRef =
        FirebaseFirestore.instance.collection('userData').doc(user.uid);
    await docRef.set({
      'fname': fname,
      'lname': lname,
      'phno': phno,
      'uid': user.uid,
      'profileurl': user.photoURL,
      'email': user.email,
    });
  }

  static Future<String?> createUser({
    required String fname,
    required String lname,
    required String phno,
  }) async {
    try {
      User user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('userData')
          .doc(user.uid)
          .set({
        'fname': fname,
        'lname': lname,
        'phno': phno,
        'uid': user.uid,
        'profileurl': user.photoURL,
        'email': user.email,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
