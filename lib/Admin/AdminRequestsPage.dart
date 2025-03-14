// lib/pages/admin_requests_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:bard/NotificationService.dart';

class AdminRequestsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // تحديد اتجاه النص من اليمين لليسار
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'طلبات الفنيين',
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
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(); // مؤشر تحميل
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('لا توجد طلبات حاليا'));
            }

            final requests = snapshot.data!.docs;

            return ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final doc = requests[index];
                final requestData = doc.data() as Map<String, dynamic>;
                final requestId = doc.id;

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
  final String requestId;

  RequestCard({required this.requestData, required this.requestId});

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

  /// دالة لإرسال إشعار للفني عند تحويل حالة الطلب إلى "online"
  Future<void> _sendTechnicianNotification(BuildContext context) async {
    // نفترض أن الفني له حقل "technicianName" أو "technicianId" في requestData.
    // هنا نقوم أولاً بجلب وثيقة الفني من مجموعة "technicians" باستخدام اسم الفني أو معرف الفني
    final String? technicianName = requestData['technicianName'];

    if (technicianName == null || technicianName.isEmpty) {
      _showSnackBar(context, 'لا يوجد اسم فني لجلب توكن الإشعار.');
      return;
    }

    try {
      // جلب وثيقة الفني بناءً على الاسم (أو يمكن استخدام حقل technicianId)
      // ملاحظة: إذا كان الاسم فريداً. أما إن لم يكن فريداً فستحتاج حقل معرف فريد
      final QuerySnapshot techSnapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .where('name', isEqualTo: technicianName)
          .limit(1)
          .get();

      if (techSnapshot.docs.isEmpty) {
        _showSnackBar(context, 'لم يتم العثور على وثيقة الفني في قاعدة البيانات.');
        return;
      }

      final technicianDoc = techSnapshot.docs.first;
      final techData = technicianDoc.data() as Map<String, dynamic>;

      // تأكد من أن حقل التوكن موجود (مثلاً: "fcmToken")
      final String? technicianFcmToken = techData['fcmToken'];
      if (technicianFcmToken == null || technicianFcmToken.isEmpty) {
        _showSnackBar(context, 'لا يوجد توكن لإشعار الفني.');
        return;
      }

      // تهيئة NotificationService باستخدام بيانات السيرفر اكونت
      final notificationService = NotificationService(
        serviceAccountJson: {
          "type": "service_account",
          "project_id": "bard-bfaf2",
          "private_key_id": "faae723dea1013678fe3b6f6ed4ae28503b40438",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC13mbfu+afRvDV\nkCENnXV6fT6fODhPKlR7QlnjA4w5hOuII8c6Pk0i6KBb2aVVaclIl3w05HP8ATMX\nOlkMqCUQZZdrEzetiKRw6WRxjTRNrLrVkYfSK8/GD/uP//odvdKtHswUA4KWQ2Y3\nOQy8nge0Qf+ETreewAwMj0QGVKgt7NUIbuf29h81IzpJWXUsxLZynskUKqeLE5+L\nAubTihCzGOwbr4t3ip2165fVuOPpoFpciXwi02ZF4R2612PEvgYUxuWyAU+oJh8d\n6iRQg0rYcR9QElHDW5tEaJsMaCmMKzIQIB2attlrdCeOGr4AZ3pq8LvPU6VHP143\niChrOoPdAgMBAAECggEAC+ymIBtI1r6nAcmucR8W2c4mcfgUsRQcb+x8ykasRgUy\nED4QTQBSvGw2P294yK3j9a+BBFLKTAakG+zGc+7+ZyHSGMIsz2L7LTAQVuWkPUeL\nBH/DQQOAXwMjQmDNPG/6xUEUrmdAg6utowdJj4BpDueY4krq/SyoXZZzJlscn84g\nIsl4TbxP4aLtyn8+7EeRmemS2uLs1cU5x/3bUpzX3ZFo2y/+8t5htBie5vVmVKEA\nD6qqrg2MqA7vF+YVQDTfAx0SBYEWwjrZppjfLf0W4Aae3ODUbEKw9/tOT927tc6G\nu2mCHjhpwJns7WJZDZdUlfCnQub7tebuZtZbSdXCQQKBgQDhqrGruFXzXnH8xFHA\naVB5Zzwey4CqMXymsntwK2gY9qnag9KUfnFZHUk3g7xbvB1raprYdEBA2uNA/SSW\np9VPmtn2+mk6kpzN47upt9CX5iO90zc/nPMGHuSTicW4rRvuOMBI6fhprdzIwin8\nqKM9VNQO9eaOGAUdwA3AZkO+bQKBgQDOUJimZcpQinIflj7ZT+fxac2852OG/Vyd\nJQwAm5ybbXqKrTNIbA/C3q1HYf6ZkoiNUbAQPzZ2Z9vGh2nuKR1sx/c7LdjER4tZ\nmdSIIO7wXOoiEZOuLOVDMFegnIwvPtgvLASls2SoChtM9v9xz9mOc6H+yxz7ugCf\nkIPAmSC1MQKBgQCMg0OD4BCsq+cf84HP5AN2xIAb0Kz5zDyIc2QG8RAtUxFp/WDW\nk3Cyg1i+l2lmWVicNNHb627Cs0iDg9wPbsuUeKA1d7CkBvxZ+u4z/D+HBYbFwMmK\n84gjDINZFpUlq6xThcS84eqKqvZpjvSj3MFgA/zSn+yCF5S/9IDbhxGxdQKBgQCj\nF4VEbMz81CSZIa03HnqNFYWE4imESX7P3rxZMqofF/E59ObIRlxDQMIb3rRj9Dkr\n9bpHbaEBAuLyUpODqE7RclXXG0vzBVd8EiW3IsmfiuOu4NQsaOMnNOzgU0BiDLza\ntWJLFr/oMm0Yb1zJPHSProsNnsSfnY7mlFgChUoc0QKBgBcRSu7hKJS3kOVmoA2b\nuiGw90T/wo8PHarrk+2P88fZsqJnIMUTfchY2N2fCpTR9DE741LwhDBN8eTNhDu+\ni2fkrvrFh81KUNcGz2wsvL06lc/y140ZRbmO3iHYJfAkxReqbPDoFNOyJtM0NczA\nizpa75w2JWGpqQZAeQwbWpfH\n-----END PRIVATE KEY-----\n",
          "client_email": "bard-811@bard-bfaf2.iam.gserviceaccount.com",
          "client_id": "112943468032516999921",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/bard-811%40bard-bfaf2.iam.gserviceaccount.com",
          "universe_domain": "googleapis.com",
        },
        projectId: 'bard-bfaf2',
        context: context,
      );

      // الحصول على Access Token
      final String accessToken = await notificationService.getAccessToken();
      final String fcmEndpoint =
          'https://fcm.googleapis.com/v1/projects/${notificationService.projectId}/messages:send';

      // إعداد بيانات الإشعار للفني
      final Map<String, dynamic> message = {
        'message': {
          'token': technicianFcmToken,
          'notification': {
            'title': 'لديك طلب جديد',
            'body': 'لديك طلب جديد  يرجى المتابعة.',
          },
          'android': {
            'notification': {
              'sound': 'custom_sound',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'custom_sound.caf',
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        _showSnackBar(context, 'تم إرسال إشعار للفني بنجاح.');
      } else {
        print('فشل إرسال الإشعار للفني: ${response.statusCode}');
        print('Response body: ${response.body}');
        _showSnackBar(context, 'فشل في إرسال الإشعار للفني.');
      }
    } catch (e) {
      print('Error sending technician notification: $e');
      _showSnackBar(context, 'فشل في إرسال إشعار للفني.');
    }
  }

  /// دالة لتحديث حالة الطلب، وفي حالة تحويلها إلى "online" يتم إرسال إشعار للفني
  Future<void> _updateRequestStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'status': newStatus});

      _showSnackBar(context, 'تم تحديث حالة الطلب إلى "$newStatus" بنجاح.');

      // إذا تم تحويل الحالة إلى online، نرسل إشعار للفني
      if (newStatus == 'online') {
        await _sendTechnicianNotification(context);
      }
    } catch (e) {
      print('Error updating request status: $e');
      _showSnackBar(context, 'حدث خطأ أثناء تحديث حالة الطلب.');
    }
  }

  /// دالة لإظهار نافذة التأكيد قبل تغيير الحالة
  Future<void> _confirmUpdateStatus(BuildContext context, String newStatus) async {
    String confirmationText = newStatus == 'online'
        ? 'هل أنت متأكد من تحويل حالة الطلب إلى "online"؟'
        : 'هل أنت متأكد من إعادة حالة الطلب إلى "pending"؟';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تأكيد التغيير'),
          content: Text(confirmationText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('تأكيد'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _updateRequestStatus(context, newStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    String customerName = requestData['customerName'] ?? 'غير متوفر';
    String customerPhone = requestData['customerPhone'] ?? '';
    String technicianName = requestData['technicianName'] ?? 'غير متوفر';
    String technicianNumber = requestData['technicianNumber'] ?? '';
    String technicianSpecialty = requestData['technicianSpecialty'] ?? 'غير متوفر';
    String technicianArea = requestData['technicianArea'] ?? 'غير متوفر';
    String status = requestData['status'] ?? 'غير متوفر';

    // تحديد لون الحالة
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

    // تحديد الإجراء التالي بناءً على الحالة
    String? nextStatus;
    String? buttonText;
    Color? buttonColor;

    if (status == 'pending') {
      nextStatus = 'online';
      buttonText = 'تفعيل الطلب';
      buttonColor = Colors.green;
    } else if (status == 'online') {
      nextStatus = 'pending';
      buttonText = 'إرجاع الطلب';
      buttonColor = Colors.orange;
    } else {
      nextStatus = null;
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الزبون
            Text(
              'اسم الزبون: $customerName',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'رقم الهاتف: $customerPhone',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            // أزرار الاتصال بالزبون
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.phone, color: Colors.blueAccent),
                  tooltip: 'اتصل بالزبون',
                  onPressed: () {
                    if (customerPhone.isNotEmpty) {
                      _makePhoneCall(customerPhone, context);
                    } else {
                      _showSnackBar(context, 'رقم الزبون غير متوفر.');
                    }
                  },
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.chat, color: Colors.teal),
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
            SizedBox(height: 16),
            // معلومات الفني
            Text(
              'معلومات الفني',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            Divider(color: Colors.blueAccent),
            SizedBox(height: 8),
            Text(
              'اسم الفني: $technicianName',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'التخصص: $technicianSpecialty',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'رقم الفني: $technicianNumber',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'المنطقة: $technicianArea',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            // عرض حالة الطلب وزر التحديث
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
                if (nextStatus != null && buttonText != null && buttonColor != null)
                  ElevatedButton(
                    onPressed: () => _confirmUpdateStatus(context, nextStatus!),
                    child: Text(buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            // أزرار الاتصال بالفني
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.phone, color: Colors.green),
                  tooltip: 'اتصل بالفني',
                  onPressed: () {
                    if (technicianNumber.isNotEmpty) {
                      _makePhoneCall(technicianNumber, context);
                    } else {
                      _showSnackBar(context, 'رقم الفني غير متوفر.');
                    }
                  },
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.chat, color: Colors.teal),
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

// امتداد لتحويل الحرف الأول إلى كبير (قد لا تحتاجه)
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}
