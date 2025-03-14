import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final bool isWindows;

  const SplashScreen({Key? key, required this.isWindows}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // الانتقال بعد 5 ثوانٍ
    Timer(const Duration(seconds: 5), () {
      _navigateToNextPage();
    });
  }

  void _navigateToNextPage() {
    // الانتقال إلى الصفحة الرئيسية حسب النظام
    if (widget.isWindows) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,        // يملأ العرض كاملاً
        height: double.infinity,       // يملأ الارتفاع كاملاً
        child: Image.asset(
          'images/black1.gif',
          fit: BoxFit.cover,          // لجعل الصورة تملأ الشاشة
        ),
      ),
    );
  }
}
