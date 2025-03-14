// discount_setup_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // مكتبة لتنسيق الأرقام والعملات
import 'package:bard/custmerPage/SpinWheelScreen.dart'; // صفحة العجلة

class DiscountSetupPage extends StatefulWidget {
  @override
  _DiscountSetupPageState createState() => _DiscountSetupPageState();
}

class _DiscountSetupPageState extends State<DiscountSetupPage> {
  final TextEditingController _discountController = TextEditingController();
  // مجموعة الخصومات في Firestore (سيتم إنشاء مجموعة باسم "discounts")
  final CollectionReference discountsCollection =
  FirebaseFirestore.instance.collection('discounts');

  // نوع الخصم: "percentage" (نسبة) أو "fixed" (مبلغ ثابت)
  String _discountType = 'percentage';

  // دالة لإضافة خصم جديد
  Future<void> _addDiscount() async {
    String discountText = _discountController.text.trim();
    if (discountText.isNotEmpty) {
      double discountValue = double.tryParse(discountText) ?? 0.0;
      if (discountValue > 0) {
        // إذا كان الخصم من نوع مبلغ ثابت، نضرب القيمة في 1000
        if (_discountType == 'fixed') {
          discountValue = discountValue * 1000;
        }
        // توليد كود الخصم الفريد باستخدام الطابع الزمني
        String discountCode =
            'DISC-' + DateTime.now().millisecondsSinceEpoch.toString();
        await discountsCollection.add({
          'value': discountValue,
          'type': _discountType,
          'code': discountCode,
          'isUsed': false, // الخصم يُستخدم مرة واحدة فقط
        });
        _discountController.clear();
      }
    }
  }

  /// دالة لإعادة توليد الكود
  /// - نسخ بيانات الخصم القديم
  /// - إنشاء مستند جديد بكود مختلف
  /// - حذف المستند القديم
  Future<void> _regenerateDiscount(DocumentSnapshot oldDoc) async {
    final oldData = oldDoc.data() as Map<String, dynamic>;
    final oldRef = oldDoc.reference;

    // توليد كود جديد
    String newCode = 'DISC-' + DateTime.now().millisecondsSinceEpoch.toString();

    // إنشاء بيانات الخصم الجديد
    Map<String, dynamic> newDiscountData = {
      'value': oldData['value'],
      'type': oldData['type'],
      'isUsed': false,
      'code': newCode,
    };
    // إذا لديك حقول إضافية مثل 'formatted' أو 'usage_limit' أو 'expiry_date' فأضفها
    if (oldData.containsKey('formatted')) {
      newDiscountData['formatted'] = oldData['formatted'];
    }
    if (oldData.containsKey('usage_limit')) {
      newDiscountData['usage_limit'] = oldData['usage_limit'];
    }
    if (oldData.containsKey('expiry_date')) {
      newDiscountData['expiry_date'] = oldData['expiry_date'];
    }
    if (oldData.containsKey('used_count')) {
      newDiscountData['used_count'] = 0; // إعادة التهيئة
    }

    // إضافة المستند الجديد
    await discountsCollection.add(newDiscountData);

    // حذف المستند القديم
    await oldRef.delete();
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تنسيق العملة: نستخدم الدنيار العراقي مع فواصل لكل 3 أرقام وبدون أرقام عشرية
    final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'ar_IQ', symbol: 'د.ع ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('إعداد الخصومات'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // اختيار نوع الخصم
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // خصم بالنسبة
                Row(
                  children: [
                    Radio<String>(
                      value: 'percentage',
                      groupValue: _discountType,
                      onChanged: (value) {
                        setState(() {
                          _discountType = value!;
                        });
                      },
                    ),
                    Text('نسبة'),
                  ],
                ),
                SizedBox(width: 20),
                // خصم بمبلغ ثابت
                Row(
                  children: [
                    Radio<String>(
                      value: 'fixed',
                      groupValue: _discountType,
                      onChanged: (value) {
                        setState(() {
                          _discountType = value!;
                        });
                      },
                    ),
                    Text('مبلغ ثابت'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            // حقل إدخال قيمة الخصم
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'قيمة الخصم (مثلاً 10 أو 20 أو 30 أو قيمة أخرى)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            // زر إضافة الخصم
            ElevatedButton(
              onPressed: _addDiscount,
              child: Text('أضف الخصم'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            // عرض قائمة الخصومات الحالية من Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: discountsCollection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data;
                  if (data == null || data.docs.isEmpty) {
                    return Center(child: Text('لا توجد خصومات بعد'));
                  }
                  return ListView(
                    children: data.docs.map((doc) {
                      // تحديد طريقة عرض القيمة حسب نوع الخصم
                      String displayValue;
                      if (doc['type'] == 'percentage') {
                        displayValue = '${doc['value'].toString()}%';
                      } else {
                        // يتم تنسيق قيمة الخصم بمبلغ ثابت باستخدام تنسيق العملة
                        displayValue = currencyFormat.format(doc['value']);
                      }
                      return ListTile(
                        title: Text('كود: ${doc['code']} - $displayValue'),
                        subtitle:
                        Text(doc['isUsed'] ? 'تم الاستخدام' : 'غير مستخدم'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // زر إعادة توليد الكود
                            IconButton(
                              icon: Icon(Icons.cached, color: Colors.orange),
                              onPressed: () async {
                                await _regenerateDiscount(doc);
                              },
                            ),
                            // زر الحذف
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await doc.reference.delete();
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            // زر الانتقال إلى صفحة العجلة
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WheelPage()),
                );
              },
              child: Text('اذهب إلى العجلة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
