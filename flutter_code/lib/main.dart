import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/studentDashboard.dart';
import 'pages/adminDashboard.dart';
import 'package:provider/provider.dart';
import 'pages/createExam.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyCKgrX0kv-eEG3ZowADmeMpFOFwoP2l_7s",
          authDomain: "project-c5492.firebaseapp.com",
          projectId: "project-c5492",
          //storageBucket: "project-c5492.firebasestorage.app",
          messagingSenderId: "190964414726",
          appId: "1:190964414726:web:9b778801ea248fc860c687",
          measurementId: "G-8D8L9YS00T"));

  runApp(
  ChangeNotifierProvider(
    create: (_) => QuestionList(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MainApp',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color.fromARGB(255, 226, 228, 224),
        primaryColor: const Color(0xFF354F52),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2F3E46)),
          bodyMedium: TextStyle(color: Color(0xFF2F3E46)),
          bodySmall: TextStyle(color: Color(0xFF2F3E46)),
        ),
        fontFamily: 'San Francisco',
      ),
      themeMode: ThemeMode.light,
      home: const MainApp(),
    ),
  ),
);

}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MainApp',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color.fromARGB(255, 226, 228, 224),
        primaryColor: const Color(0xFF354F52),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2F3E46), fontSize: 15),
          bodyMedium: TextStyle(color: Color(0xFF2F3E46), fontSize: 15),
          bodySmall: TextStyle(color: Color(0xFF2F3E46), fontSize: 15),
        ),
        fontFamily: 'San Francisco',
      ),
      themeMode: ThemeMode.light,
      home: LoginPage(),
    );
  }
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Login",
                style: TextStyle(
                  fontSize: 35,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold
                )
                              ),
              const SizedBox(
                height: 140,
              ),

              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                    child: Text("Email", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                  ),
                ],
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.email),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),  
                  borderSide: BorderSide.none
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 176, 43, 33)
				)
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),

                ),
              ),
              const SizedBox(
                height: 20,
              ),
                const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                    child: Text("Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                  ),
                ],
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.lock_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),  
                  borderSide: BorderSide.none
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(255, 176, 43, 33)
				)
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton.icon(
                onPressed: loginCheck,
                label: const Text(
                  '    Login',
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white,),
                iconAlignment: IconAlignment.end,
                style: ButtonStyle(
                        backgroundColor:
                            const WidgetStatePropertyAll(Color(0xFF354F52)),
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                        padding: const WidgetStatePropertyAll(
                            EdgeInsetsDirectional.only(
                                top: 15, bottom: 15, start: 40, end: 40))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> loginCheck() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password');
      return;
    }

    String hashedPassword = md5.convert(utf8.encode(password)).toString();

    try {
      var usersCollection = FirebaseFirestore.instance.collection('Users');
      var querySnapshot =
          await usersCollection.where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isEmpty) {
        _showMessage('No user found with that email');
        return;
      }

      var userDoc = querySnapshot.docs.first;
      String storedHashedPassword = userDoc['hashedPassword'];

      if (storedHashedPassword == hashedPassword) {
        if (userDoc['role'] == 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => adminDashboard(
                userId: userDoc.id,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => studentDashboard(
                userId: userDoc.id,
              ),
            ),
          );
        }
        print("hi");
      } else {
        _showMessage('Incorrect password');
      }
    } catch (e) {
      _showMessage('An error occurred. Please try again later.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white), // White text for contrast
        ),
        backgroundColor: Colors.red, // Red background for errors
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
