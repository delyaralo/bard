// lib/pages/technician_requests_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TechnicianRequestsPage extends StatelessWidget {
  final String technicianName;

  const TechnicianRequestsPage({Key? key, required this.technicianName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // تحديد اتجاه النص من اليمين لليسار
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "طلباتك الحالية",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          backgroundColor: Colors.lightBlue,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .where('technicianName', isEqualTo: technicianName)
              .where('status', isEqualTo: 'online')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(); // مؤشر تحميل
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('لا توجد طلبات حالية')); // رسالة عند عدم وجود بيانات
            }

            final requests = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final doc = requests[index];
                final requestData = doc.data() as Map<String, dynamic>;
                final requestId = doc.id; // الحصول على معرف المستند

                return RequestCard(
                  requestData: requestData,
                  requestId: requestId,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> requestData;
  final String requestId; // معرف الطلب

  const RequestCard({Key? key, required this.requestData, required this.requestId}) : super(key: key);

  // دالة لفتح واتساب مع رقم الفني أو الزبون
  void _openWhatsApp(String phone, BuildContext context) async {
    final Uri whatsappUri = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar(context, 'لا يمكن فتح واتساب على هذا الجهاز.');
    }
  }

  // دالة لفتح تطبيق الهاتف مع الرقم
  void _makePhoneCall(String phone, BuildContext context) async {
    final Uri phoneUri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar(context, 'لا يمكن فتح تطبيق الهاتف على هذا الجهاز.');
    }
  }

  // دالة لإظهار SnackBar
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    String customerName = requestData['customerName'] ?? 'غير متوفر';
    String customerPhone = requestData['customerPhone'] ?? '';
    String technicianName = requestData['technicianName'] ?? 'غير متوفر';
    String technicianNumber = requestData['technicianNumber'] ?? '';
    String technicianSpecialty = requestData['technicianSpecialty'] ?? 'غير متوفر';
    String technicianArea = requestData['technicianArea'] ?? 'غير متوفر';
    String status = requestData['status'] ?? 'غير متوفر'; // حالة الطلب

    // تحديد لون حالة الطلب
    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'online':
        statusColor = Colors.green;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.grey;
        break;
      case 'canceled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.black;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // **معلومات الزبون**
            Text(
              'اسم الزبون: $customerName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'رقم الهاتف: $customerPhone',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // **أزرار الاتصال بالزبون**
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // زر الاتصال بالزبون عبر الهاتف
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.blueAccent),
                  tooltip: 'اتصل بالزبون',
                  onPressed: () {
                    if (customerPhone.isNotEmpty) {
                      _makePhoneCall(customerPhone, context);
                    } else {
                      _showSnackBar(context, 'رقم الزبون غير متوفر.');
                    }
                  },
                ),
                const SizedBox(width: 8),
                // زر التواصل عبر واتساب للزبون
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.teal),
                  tooltip: 'تواصل عبر واتساب مع الزبون',
                  onPressed: () {
                    if (customerPhone.isNotEmpty) {
                      _openWhatsApp(customerPhone, context);
                    } else {
                      _showSnackBar(context, 'رقم الزبون غير متوفر.');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // **معلومات الفني**
            Text(
              'معلومات الفني',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent.shade700,
              ),
            ),
            Divider(color: Colors.blueAccent.shade700),
            const SizedBox(height: 8),
            Text(
              'اسم الفني: $technicianName',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'التخصص: $technicianSpecialty',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'رقم الفني: $technicianNumber',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'المنطقة: $technicianArea',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // **عرض حالة الطلب**
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'حالة الطلب: $status',
                  style: TextStyle(
                    fontSize: 16,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // **أزرار الاتصال بالفني**
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // زر الاتصال بالفني عبر الهاتف
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  tooltip: 'اتصل بالفني',
                  onPressed: () {
                    if (technicianNumber.isNotEmpty) {
                      _makePhoneCall(technicianNumber, context);
                    } else {
                      _showSnackBar(context, 'رقم الفني غير متوفر.');
                    }
                  },
                ),
                const SizedBox(width: 8),
                // زر التواصل عبر واتساب للفني
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.teal),
                  tooltip: 'تواصل عبر واتساب مع الفني',
                  onPressed: () {
                    if (technicianNumber.isNotEmpty) {
                      _openWhatsApp(technicianNumber, context);
                    } else {
                      _showSnackBar(context, 'رقم الفني غير متوفر.');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// **امتداد لتحويل الحرف الأول إلى كبير**
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
