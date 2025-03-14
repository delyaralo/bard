// lib/pages/technicians_home_page.dart
import 'package:flutter/material.dart';
import 'TechnicianRequestsPage.dart'; // تأكد من تغيير المسار حسب هيكل المشروع الخاص بك
import 'TechnicianPostsPage.dart';
class TechniciansHomePage extends StatelessWidget {
  final String technicianName;
  final String technicianId;



  const TechniciansHomePage({Key? key, required this.technicianName,required this.technicianId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استخدام خلفية متدرجة
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB2EBF2), Color(0xFF80DEEA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView( // لضمان توافق المحتوى مع شاشات صغيرة
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // إضافة صورة شخصية للفني
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage('images/t1.jpg'), // تأكد من إضافة الصورة في مجلد assets
                  ),
                  const SizedBox(height: 20),
                  // نص ترحيبي مخصص
                  Text(
                    "أهلاً وسهلاً بك في بارد،\n$technicianName",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // زر عرض الطلبات بتصميم مخصص
                  ElevatedButton.icon(
                    onPressed: () {
                      // التنقل إلى صفحة الطلبات الخاصة بالفني
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TechnicianRequestsPage(
                            technicianName: technicianName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list_alt, size: 28),
                    label: const Text(
                      'عرض طلباتي',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.lightBlue, backgroundColor: Colors.white, // لون النص والأيقونة
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // إضافة زر خروج (اختياري)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TechnicianPostsPage(technicianId: technicianId),
                        ),
                      );
                      // إضافة منطق الخروج هنا
                    },
                    icon: const Icon(Icons.logout, size: 28),
                    label: const Text(
                      'الملف الشخصي',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.redAccent, // لون النص والأيقونة
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // إضافة زر خروج (اختياري)
                  ElevatedButton.icon(
                    onPressed: () {
                      // إضافة منطق الخروج هنا
                    },
                    icon: const Icon(Icons.logout, size: 28),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.redAccent, // لون النص والأيقونة
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
