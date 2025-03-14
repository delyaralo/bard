import 'dart:io' show Platform; // لإجراء التحقق من النظام (Windows/Android/iOS)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';

// استورد ملفات الصفحات المطلوبة
// import 'package:bard/Technicians/TechniciansHomePage.dart';
// import 'package:bard/Employees/EmployeeHomePage.dart';
import 'package:bard/Admin/MainAdamnPage.dart';
import 'package:bard/Technicians/TechniciansHomePage.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // دالة زر تسجيل الدخول
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // 1) البحث في مجموعة الفنيين (technicians)
      final technicianSnapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .where('name', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (technicianSnapshot.docs.isNotEmpty) {
        final technicianDoc = technicianSnapshot.docs.first;
        final technicianId = technicianDoc.id;
        // استخراج الاسم من الوثيقة أو استخدام username مباشرة
        final technicianName = technicianDoc.data()['name'] ?? username;

        // إذا لم يكن التطبيق على Windows، حدّث توكن FCM
        if (!Platform.isWindows) {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await FirebaseFirestore.instance
                .collection('technicians')
                .doc(technicianId)
                .update({'fcmToken': fcmToken});
          }
        }

        // الانتقال إلى صفحة الفنيين (مع إغلاق صفحة تسجيل الدخول)
        // استبدل TechniciansHomePage بما يناسب مشروعك
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TechniciansHomePage(
              technicianName: technicianName,
              technicianId: technicianId,
            ),
          ),
        );
        return;
      }

      // 2) البحث في مجموعة الموظفين (employees)
      final employeeSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('employeeName', isEqualTo: username)
          .where('employeePassword', isEqualTo: password)
          .limit(1)
          .get();

      if (employeeSnapshot.docs.isNotEmpty) {
        final employeeDoc = employeeSnapshot.docs.first;
        final employeeId = employeeDoc.id;

        // إذا لم يكن التطبيق على Windows، حدّث توكن FCM
        if (!Platform.isWindows) {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await FirebaseFirestore.instance
                .collection('employees')
                .doc(employeeId)
                .update({'fcmToken': fcmToken});
          }
        }

        // الانتقال إلى صفحة الموظفين (مع إغلاق صفحة تسجيل الدخول)
        // استبدل EmployeeHomePage بما يناسب مشروعك
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmployeeHomePage()),
        );
        return;
      }

      // 3) في حالة عدم العثور على مستخدم في المجموعتين
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم المستخدم أو كلمة المرور غير صحيحة')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تسجيل الدخول: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إن كان التطبيق يعمل على Windows سنستخدم قياسات أكبر قليلاً
    final bool isDesktop = Platform.isWindows;

    // يمكنك تعديل قيم الأحجام هنا لنسختي الهاتف/الحاسوب
    final double iconSize = isDesktop ? 100 : 60;
    final double circleSize = isDesktop ? 130 : 90; // حجم الدائرة الخلفية للأيقونة
    final double cardElevation = isDesktop ? 10 : 6;
    final double cardPadding = isDesktop ? 24 : 16;
    final double textFontSize = isDesktop ? 18 : 14; // حجم خط مثلاً

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // في حالة الحاسوب لا نعرض زر الرجوع
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: !isDesktop,
          title: Text(
            'تسجيل الدخول',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xff5B86E5),

        body: Stack(
          children: [
            // الخلفية المتدرّجة مع موجة
            Positioned.fill(
              child: CustomPaint(
                painter: _WaveBackgroundPainter(),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    // أيقونة / شعار
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: iconSize,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // البطاقة التي تحتوي على النموذج
                    Card(
                      elevation: cardElevation,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // حقل اسم المستخدم
                              TextFormField(
                                controller: _usernameController,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.cairo(fontSize: textFontSize),
                                decoration: InputDecoration(
                                  labelText: 'اسم المستخدم',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'يرجى إدخال اسم المستخدم';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // حقل كلمة المرور
                              TextFormField(
                                controller: _passwordController,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.cairo(fontSize: textFontSize),
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'يرجى إدخال كلمة المرور';
                                  }
                                  if (value.length < 6) {
                                    return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),

                              // رابط "نسيت كلمة المرور؟"
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    // مثال: فتح صفحة "نسيت كلمة المرور" أو أي إجراء آخر
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('نسيت كلمة المرور؟')),
                                    );
                                  },
                                  child: Text(
                                    'نسيت كلمة المرور؟',
                                    style: GoogleFonts.cairo(
                                      color: Colors.blueAccent,
                                      fontSize: textFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // زر تسجيل الدخول
                              SizedBox(
                                width: double.infinity,
                                height: isDesktop ? 60 : 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff5B86E5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                    'تسجيل الدخول',
                                    style: GoogleFonts.cairo(
                                      fontSize: textFontSize,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// رسم خلفية متدرّجة مع موجة (Wave) علوية
class _WaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1) تدرّج خلفي يملأ الشاشة
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xff36D1DC),
        Color(0xff5B86E5),
      ],
    );
    final Paint paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // 2) موجة بلون أبيض شفاف قليلاً
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.2);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.10,
      size.width * 0.5,
      size.height * 0.18,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.26,
      size.width,
      size.height * 0.15,
    );

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    path.close();
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
