import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
  static Future<bool> signUp(
  String name,
  String email,
  String password,
) async {
  try {
    UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
   
    User? user = userCredential.user;

    if (user == null) {
      print('User is NULL after signup');
      return false;
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'profilePicture': '',
      'createdAt': FieldValue.serverTimestamp(),
      // numeric counts for consistency with follow logic
      'followers': 0,
      'following': 0,
      'posts': 0,
      'likes': 0,
    });

    print('Signup successful: ${user.email}');
    return true;
  } on FirebaseAuthException catch (e) {
    print('FirebaseAuthException');
    print('Code: ${e.code}');
    print('Message: ${e.message}');
    return false;
  } catch (e) {
    print('Unknown error: $e');
    return false;
  }
}}
