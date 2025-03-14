import 'package:flutter/material.dart';
import 'LoginPage.dart';
import 'MyOrdersPage.dart';
import 'Prize_Page.dart';
class DatPage extends StatelessWidget {
  const DatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[100], // خلفية بسيطة
        child: Column(
          children: [
            // يمكنك وضع هنا أي تصميم للهيدر (DrawerHeader) أو تركه فارغاً

            Expanded(
              child: ListView(
                children: [
                  // قسائمي
                  ListTile(
                    leading:
                    const Icon(Icons.card_giftcard, color: Colors.blueAccent),
                    title: const Text(
                      'قسائمي',
                      style: TextStyle(fontFamily: 'Amiri'),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        _createCustomRoute(const WinnerPrizePage()),
                      );
                    },
                  ),
                  const Divider(thickness: 1, color: Colors.black12),

                  // طلباتي
                  ListTile(
                    leading:
                    const Icon(Icons.card_travel, color: Colors.blueAccent),
                    title: const Text(
                      'طلباتي',
                      style: TextStyle(fontFamily: 'Amiri'),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        _createCustomRoute(const MyOrdersPage()),
                      );
                    },
                  ),
                  const Divider(thickness: 1, color: Colors.black12),

                  // نبذة عنا
                  ListTile(
                    leading: const Icon(Icons.info, color: Colors.blueAccent),
                    title: const Text(
                      'نبذة عنا',
                      style: TextStyle(fontFamily: 'Amiri'),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        _createCustomRoute( AboutPage()),
                      );
                    },
                  ),
                  const Divider(thickness: 1, color: Colors.black12),

                  // الإعدادات

                  // تسجيل دخول الفني
                  ListTile(
                    leading: const Icon(Icons.login, color: Colors.blueAccent),
                    title: const Text(
                      'تسجيل دخول الفني',
                      style: TextStyle(fontFamily: 'Amiri'),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        _createCustomRoute( LoginPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// دالة خاصة لإنشاء مسار (Route) مخصص بالانتقال (Transition)
  /// يمكنك تعديل نوع ومدة الحركة كيفما تشاء
  Route _createCustomRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      // هنا نحدد الحركة الانتقالية بين الصفحتين
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // مثال: FadeTransition (تلاشي)
        // return FadeTransition(
        //   opacity: animation,
        //   child: child,
        // );

        // مثال: SlideTransition من اليمين إلى اليسار
        const begin = Offset(1.0, 0.0); // يبدأ من خارج الشاشة على اليمين
        const end = Offset.zero;        // ينتهي في مركز الشاشة
        final tween = Tween(begin: begin, end: end);
        final slideAnimation = animation.drive(tween);

        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
// صفحات افتراضية للتوضيح (AboutPage, SettingsPage, TechnicianLoginPage)
// يمكنك استبدالها بما يناسب تطبيقك الحقيقي
class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar مع عنوان وخلفية مميزة
      appBar: AppBar(
        title: Text('نبذة عنا'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff36D1DC), Color(0xff5B86E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      // استخدام SingleChildScrollView لتجنب تجاوز المحتوى حجم الشاشة
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض شعار الشركة (تأكد من إضافة الصورة إلى مجلد assets وتحديث pubspec.yaml)
            Center(
              child: Image.asset(
                'images/k.png', // قم بتحديث مسار الصورة حسب موقعها
                height: 300,
              ),
            ),
            SizedBox(height: 20),
            // عنوان ترحيبي مركزي مع تظليل مميز
            Center(
              child: Text(
                'مرحبًا بكم في بارد هوا',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            // قسم تاريخ الشركة
            Text(
              'تاريخ الشركة:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'تأسست شركة بارد هوا بهدف تقديم أفضل المنتجات والخدمات في مجال الأجهزة الكهربائية. نعمل على توفير أحدث الأجهزة المنزلية ذات الجودة العالية وخدمة تركيب احترافية، مع الالتزام بتلبية احتياجات عملائنا بأعلى معايير الاحترافية.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // قسم المنتجات
            Text(
              'منتجاتنا:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نوفر مجموعة واسعة من الأجهزة الكهربائية:\n'
                  '- الغسالات\n'
                  '- الثلاجات\n'
                  '- المجمدات\n'
                  '- السبلت\n'
                  '- المكيفات',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // قسم الخدمات
            Text(
              'خدماتنا:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'بالإضافة إلى بيع الأجهزة، نوفر خدمة طلب الفني لتركيب الأجهزة، سواء بشكل مستقل أو مع الطلب الخاص بكم، لضمان أفضل أداء وكفاءة عالية في التركيب والصيانة.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // قسم الرؤية
            Text(
              'رؤيتنا:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نسعى لأن نكون الخيار الأول في السوق من خلال الابتكار واستخدام أحدث التقنيات، مقدمين خدمات متكاملة تجمع بين جودة المنتجات والاحترافية في الخدمة.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // قسم الرسالة
            Text(
              'رسالتنا:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نسعى لتقديم أفضل الحلول الكهربائية التي تجمع بين الراحة والجودة، مع توفير الدعم الفني المتميز لضمان رضا عملائنا وثقتهم المستمرة بنا.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // قسم القيم
            Text(
              'قيمنا:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• الجودة والابتكار\n'
                  '• الشفافية والاحترافية\n'
                  '• خدمة عملاء متميزة\n'
                  '• الالتزام والمسؤولية',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            // زر للتواصل أو الاستفسار
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // يمكن إضافة وظيفة الاتصال أو التوجه لصفحة تواصل هنا
                },
                icon: Icon(Icons.phone),
                label: Text('اتصل بنا'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff36D1DC), Color(0xff5B86E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Center(
        child: Text(
          'هذه صفحة الإعدادات',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class TechnicianLoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تسجيل دخول الفني'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Text(
          'صفحة تسجيل دخول الفني',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}