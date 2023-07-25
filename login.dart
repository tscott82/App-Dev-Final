import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showErrorDialog("Please enter email and password.");
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Login success, navigate to the main page.
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        _showErrorDialog("Invalid email or password.");
      } else {
        _showErrorDialog("Login failed. Please try again later.");
      }
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _openRegisterPage(BuildContext context) {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text("Login"),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: "Email"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              child: Text("Login"),
              style: ElevatedButton.styleFrom(
                primary: Colors.lightBlueAccent,
              ),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _openRegisterPage(context);
              },
              child: Text("Don't have an account? Register here."),
              style: TextButton.styleFrom(
                primary: Colors.lightBlueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkDisplayName();
  }

  Future<void> _checkDisplayName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName == null) {
      // Fetch the display name from your user database and set it
      // This depends on how you store user information in your database
      String? displayName = await fetchDisplayNameFromDatabase(user.uid);
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
    }
  }

  Future<String?> fetchDisplayNameFromDatabase(String uid) async {
    // Here, you need to fetch the user's display name from your database
    // This could be Firestore, Realtime Database, or any other backend you use
    // Return the user's display name if found, or null if not found
    // Example (using Firestore):
    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (snapshot.exists) {
      return snapshot.data()!['username'];
    } else {
      return null;
    }
  }
}
