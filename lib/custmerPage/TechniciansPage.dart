import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// صفحات أخرى
import 'package:bard/custmerPage/whatsappPage.dart';
import 'package:bard/custmerPage/TechnicianSelectionPage.dart';

class TechniciansPage extends StatelessWidget {
  const TechniciansPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // يمكنك تعديل الروابط أو الاحتفاظ بها كما هي
    const String firstImageUrl =
        'https://puzzxscbgswfjqzirpqa.supabase.co/storage/v1/object/public/image//a1.png';
    const String secondImageUrl =
        'https://puzzxscbgswfjqzirpqa.supabase.co/storage/v1/object/public/image//a2.png';

    return Scaffold(
      // خلفية متدرجة لكامل الصفحة
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF6F9FF),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // لمنع overflow إن كان هناك مساحة لا تتسع مستقبلاً
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // عنوان الصفحة أو أي نص توضيحي
                    Text(
                      "خدماتنا",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ----------------- البطاقة الأولى -----------------
                    _buildServiceCard(
                      context: context,
                      imageUrl: firstImageUrl,
                      title: "استفسارات",       // يمكنك إظهار نص فوق الصورة أو أسفلها
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InquiryPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // ----------------- البطاقة الثانية -----------------
                    _buildServiceCard(
                      context: context,
                      imageUrl: secondImageUrl,
                      title: "طلب فني",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TechnicianSelectionPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ودجت مساعدة لبناء بطاقة (Card) بخلفية الصورة واسم الخدمة
  Widget _buildServiceCard({
    required BuildContext context,
    required String imageUrl,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,  // لقص أي شيء خارج الحدود الدائرية
        child: SizedBox(
          width: 320,
          height: 200,
          child: Stack(
            children: [
              // صورة من الشبكة مع Placeholder
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(

                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              ),

              // يمكنك إضافة نص أعلى الصورة أو أسفلها
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                // خلفية شيفونية (شفافة جزئياً)
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
