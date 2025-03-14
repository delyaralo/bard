// winner_prize_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:bard/device_provider.dart';

class WinnerPrizePage extends StatefulWidget {
  const WinnerPrizePage({Key? key}) : super(key: key);

  @override
  _WinnerPrizePageState createState() => _WinnerPrizePageState();
}

class _WinnerPrizePageState extends State<WinnerPrizePage> {
  late Future<QueryDocumentSnapshot?> _winnerFuture;

  @override
  void initState() {
    super.initState();
    final deviceId =
        Provider.of<DeviceProvider>(context, listen: false).deviceId;
    _winnerFuture = _fetchWinner(deviceId);
  }

  /// جلب بيانات الفائز (الخصم) من مجموعة 'winners' باستخدام deviceId
  /// نستخدم QueryDocumentSnapshot بدلاً من DocumentSnapshot
  /// كي نحصل على reference للمستند بسهولة
  Future<QueryDocumentSnapshot?> _fetchWinner(String deviceId) async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('winners')
        .where('deviceId', isEqualTo: deviceId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }
    return null;
  }

  /// توليد كود خصم جديد بنفس قيمة الكود القديم في مجموعة "discounts"

  /// تطبيق الخصم:
  ///  1) حفظ بيانات الخصم في SharedPreferences (يعتبر مُطبّق)
  ///  2) توليد كود جديد بنفس القيمة في مجموعة "discounts"
  ///  3) تحديث مستند الفائز في مجموعة "winners" بجعل discount.isUsed = true
  Future<void> _applyDiscountAndRegenerate({
    required Map<String, dynamic> oldDiscountData,
    required QueryDocumentSnapshot winnerDoc,
  }) async {
    // 1) حفظ بيانات الخصم في SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('applied_discount', jsonEncode(oldDiscountData));

    // 2) توليد كود جديد في "discounts"

    // 3) تحديث حقل isUsed في نفس مستند الفائز
    await winnerDoc.reference.update({
      'discount.isUsed': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تطبيق الخصم على الطلب')),
    );

    Navigator.pop(context, oldDiscountData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("جائزة الفائز"),
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
      body: FutureBuilder<QueryDocumentSnapshot?>(
        future: _winnerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                "حدث خطأ أثناء جلب بيانات الجائزة",
                style: TextStyle(fontSize: 18),
              ),
            );
          } else {
            // في حال عدم وجود فائز مسجل
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Text(
                  "لم يتم تسجيل جائزة لهذا الجهاز",
                  style: TextStyle(fontSize: 20),
                ),
              );
            }

            // winnerDoc هو المستند الذي عثرنا عليه
            final winnerDoc = snapshot.data!;
            final data = winnerDoc.data() as Map<String, dynamic>;

            String displayText = '';
            String codeText = '';

            // التحقق من وجود بيانات الخصم في المستند
            if (data.containsKey('discount')) {
              final discountData = data['discount'] as Map<String, dynamic>;
              final discountType = discountData['type'] ?? '';
              final discountValue = discountData['value'] ?? 0;
              final discountCode = discountData['code'] ?? '';

              // هل الخصم مستخدم؟
              final bool isUsed = discountData['isUsed'] == true;

              // تكوين النص
              if (discountType == 'percentage') {
                displayText = '$discountValue% خصم';
              } else if (discountType == 'fixed') {
                displayText = '${discountData["formatted"] ?? discountValue} خصم';
              } else {
                displayText = 'خصم غير معروف';
              }
              codeText = discountCode;

              // في حال الخصم مستخدم، نخفي زر التطبيق
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            size: 80,
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "مبروك!",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "لقد ربحت الخصم التالي:",
                            style: TextStyle(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  displayText,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurpleAccent,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (codeText.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'الكود: $codeText',
                                    style: const TextStyle(
                                        fontSize: 20, color: Colors.black87),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  // إذا لم يكن الخصم مستخدمًا، نعرض الزر
                                  if (!isUsed)
                                    ElevatedButton(
                                      onPressed: () async {
                                        await _applyDiscountAndRegenerate(
                                          oldDiscountData: discountData,
                                          winnerDoc: winnerDoc,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                      ),
                                      child: const Text(
                                        "تطبيق الخصم على الطلب",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    )
                                  else
                                    Text(
                                      'هذا الخصم مستخدم مسبقًا',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: const Text(
                              "العودة",
                              style: TextStyle(fontSize: 20),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              // إذا لم يكن هناك بيانات خصم
              final timestamp = data['timestamp'] != null
                  ? (data['timestamp'] as Timestamp).toDate().toString()
                  : '';
              String prizeText = data['prize'] ?? 'جائزة غير معروفة';

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            size: 80,
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "مبروك!",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "لقد ربحت: $prizeText",
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.deepPurpleAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (timestamp.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              "تاريخ الفوز: $timestamp",
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: const Text(
                              "العودة",
                              style: TextStyle(fontSize: 20),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
