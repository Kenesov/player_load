import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/athlete_dashboard.dart';
import 'screens/coach_dashboard.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sport RPE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  _checkAuthStatus() async {
    await Future.delayed(Duration(seconds: 2)); // Splash screen uchun

    bool isLoggedIn = await AuthService().isLoggedIn();

    if (isLoggedIn) {
      User? user = await AuthService().getCurrentUser();
      print('Current user: $user');

      if (user != null) {
        print('User role: ${user.role}');

        if (user.role == 'ATHLETE') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AthleteDashboard(user: user),
            ),
          );
        } else if (user.role == 'COACH') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CoachDashboard(user: user),
            ),
          );
        } else {
          print('Unknown role: ${user.role}');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      } else {
        print('User is null');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'Sport RPE',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sportchilar va murabbiylar uchun',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
