import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery App',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/main': (context) => MainPage(),
      },
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  Future<void> _register() async {
    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String username = _usernameController.text.trim();

      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        _showErrorDialog("Please enter email, password, and username.");
        return;
      }

      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;

        // Save the username in Firebase Firestore (or Realtime Database) for later retrieval
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'username': username,
          // You can add more user-related data here if needed
        });

        // Update the display name on Firebase Authentication
        await userCredential.user!.updateDisplayName(username);

        // Registration success, navigate to the login page.
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showErrorDialog("User registration failed. Please try again later.");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _showErrorDialog("The password provided is too weak.");
      } else if (e.code == 'email-already-in-use') {
        _showErrorDialog("The account already exists for that email.");
      } else {
        _showErrorDialog("Registration failed. Please try again later.");
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

  void _goToLoginPage() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text("Register"),
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
            SizedBox(height: 16),
            TextField( // New
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _register,
              child: Text("Register"),
              style: ElevatedButton.styleFrom(
                primary: Colors.lightBlueAccent,
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: _goToLoginPage,
              child: Text("Already have an account? Login"),
              style: TextButton.styleFrom(
                primary: Colors.lightBlueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}