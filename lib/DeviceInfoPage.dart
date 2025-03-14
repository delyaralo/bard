import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'device_provider.dart'; // تأكد من مسار الاستيراد الصحيح

class DeviceInfoPage extends StatelessWidget {
  const DeviceInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // الحصول على deviceId من DeviceProvider
    final deviceId = Provider.of<DeviceProvider>(context).deviceId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات الجهاز'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'معرف الجهاز:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                deviceId ?? 'لم يتم العثور على معرف',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              // يمكن إضافة معلومات أخرى هنا إذا كانت متوفرة في DeviceProvider
            ],
          ),
        ),
      ),
    );
  }
}
