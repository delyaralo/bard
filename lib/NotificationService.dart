// NotificationService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final Map<String, dynamic> serviceAccountJson;
  final String projectId;
  final BuildContext context; // لاستخدام ScaffoldMessenger لعرض الرسائل

  NotificationService({
    required this.serviceAccountJson,
    required this.projectId,
    required this.context,
  });

  /// إنشاء JWT لحساب الخدمة وتوقيعه
  String createJwt(Map<String, dynamic> serviceAccountJson) {
    final claims = JsonWebTokenClaims.fromJson({
      'iss': serviceAccountJson['client_email'],
      'scope': 'https://www.googleapis.com/auth/firebase.messaging',
      'aud': 'https://oauth2.googleapis.com/token',
      'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600, // 1 ساعة
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    final key = JsonWebKey.fromPem(serviceAccountJson['private_key']);
    final builder = JsonWebSignatureBuilder()
      ..jsonContent = claims.toJson()
      ..addRecipient(key, algorithm: 'RS256');

    final jws = builder.build();
    return jws.toCompactSerialization();
  }

  /// الحصول على Access Token باستخدام حساب الخدمة
  Future<String> getAccessToken() async {
    final String tokenUri = 'https://oauth2.googleapis.com/token';
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final Map<String, dynamic> body = {
      "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
      "assertion": createJwt(serviceAccountJson),
    };

    final http.Response response = await http.post(
      Uri.parse(tokenUri),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      print('Error obtaining access token: ${response.body}');
      throw Exception('Failed to obtain access token');
    }
  }

  /// جلب توكنات الموظفين من Firestore
  Future<List<String>> getEmployeeTokens() async {
    List<String> tokens = [];

    // جلب التوكنات من مجموعة "employees" بشرط أن يكون الدور 'admin'
    QuerySnapshot employeesSnapshot = await FirebaseFirestore.instance
        .collection('employees') // تأكد من جلب توكنات الإداريين فقط
        .get();

    for (var doc in employeesSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (doc.exists && data.containsKey('fcmToken')) {
        tokens.add(data['fcmToken']);
      } else {
        print('fcmToken not found for employee: ${doc.id}');
      }
    }

    return tokens;
  }

  /// إرسال الإشعار إلى Firebase Cloud Messaging
  Future<void> sendEmployeeNotification(String customerName,
      {String? discountCode, double? discountAmount}) async {
    try {
      final String accessToken = await getAccessToken(); // الحصول على Access Token
      final String fcmEndpoint =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final String title = '🚚 طلب جديد';
      String body = 'لديك طلب جديد من $customerName';

      // إذا كان هناك خصم، أضف التفاصيل إلى نص الإشعار
      if (discountCode != null && discountAmount != null) {
        body += '\nتم تطبيق كود الخصم: $discountCode\nقيمة الخصم: $discountAmount \$';
      }

      List<String> tokens = await getEmployeeTokens(); // جلب توكنات الموظفين

      if (tokens.isEmpty) {
        print('لا توجد توكنات لإرسال الإشعارات.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا توجد توكنات لإرسال الإشعارات.')),
        );
        return;
      }

      // إعداد الرسالة بشكل موحد لكل توكن
      for (String token in tokens) {
        final Map<String, dynamic> message = {
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'notification': {
                'sound': 'custom_sound', // نغمة الإشعار المخصصة (بدون الامتداد)
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'custom_sound.caf', // نغمة الإشعار المخصصة لنظام iOS
                },
              },
            },
          },
        };

        final http.Response response = await http.post(
          Uri.parse(fcmEndpoint),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(message),
        );

        if (response.statusCode == 200) {
          print('تم إرسال الإشعار إلى $token بنجاح');
        } else {
          print('فشل إرسال الإشعار إلى $token: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      }

      // عرض رسالة النجاح بعد إرسال جميع الإشعارات
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال الإشعارات للموظفين بنجاح!')),
      );
    } catch (e) {
      print('Error sending notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إرسال الإشعارات للموظفين')),
      );
    }
  }
}
