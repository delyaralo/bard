import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InquiryPage extends StatefulWidget {
  @override
  _InquiryPageState createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _deviceTypeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // دالة لإرسال الرسالة عبر واتساب
  void _sendMessage() async {
    String message = _messageController.text.trim();
    String deviceType = _deviceTypeController.text.trim();
    String location = _locationController.text.trim();

    if (message.isEmpty || deviceType.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى تعبئة جميع الحقول')),
      );
      return;
    }

    String fullMessage =
        "رسالة الاستفسار: $message\nنوع الجهاز: $deviceType\nالموقع: $location";

    String phoneNumber = "9647704915600"; // ضع رقم الواتساب هنا بدون علامة "+"

    Uri whatsappUrl = Uri.parse("whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(fullMessage)}");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      // إذا لم يتمكن من فتح واتساب عبر التطبيق، نحاول عبر المتصفح
      Uri fallbackUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(fullMessage)}");
      if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن فتح واتساب')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // لتحديد اتجاه النص والواجهة من اليمين إلى اليسار
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إرسال استفسار'),
          backgroundColor: Colors.lightBlue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // حقل رسالة الاستفسار
                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'رسالة الاستفسار',
                    hintText: 'أدخل رسالتك هنا',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // حقل نوع الجهاز
                TextField(
                  controller: _deviceTypeController,
                  decoration: InputDecoration(
                    labelText: 'نوع الجهاز',
                    hintText: 'أدخل نوع الجهاز',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // حقل مكان الزبون
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'مكان الزبون',
                    hintText: 'أدخل موقعك',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                // زر إرسال الرسالة عبر الواتساب
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: Colors.white),
                    label: Text(
                      'إرسال الرسالة عبر الواتساب',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
