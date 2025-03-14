import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';

import 'package:bard/device_provider.dart'; // عدّل المسار إن لزم

class WheelPage extends StatefulWidget {
  const WheelPage({Key? key}) : super(key: key);

  @override
  _WheelPageState createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage> {
  final StreamController<int> selected = StreamController<int>.broadcast();

  // تحكم بآلية الدوران ونتيجته
  int? _winningIndex;
  int? _pendingIndex;
  int? _lastValue;
  bool isSpinning = false;

  // قائمة الخصومات القادمة من فايرستور
  List<DocumentSnapshot> wheelDiscounts = [];
  bool isLoading = true;

  late String _deviceId;

  // تحكم بإطلاق قصاصات Confetti
  late ConfettiController _confettiController;

  // تنسيق عملة العراق
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'ar_IQ',
    symbol: 'د.ع ',
    decimalDigits: 0,
  );

  // تدرّج لوني واحد سنستخدمه للزر وللشرائح معًا
  final List<Color> _brandGradient = [
    const Color(0xff36D1DC),
    const Color(0xff5B86E5),
  ];

  @override
  void initState() {
    super.initState();

    // 1) جلب deviceId من Provider
    _deviceId = Provider.of<DeviceProvider>(context, listen: false).deviceId;

    // 2) تحميل الخصومات (isUsed=false) من فايرستور
    FirebaseFirestore.instance
        .collection('discounts')
        .where('isUsed', isEqualTo: false)
        .get()
        .then((snapshot) {
      List<DocumentSnapshot> docs = snapshot.docs;
      // إذا وجدت وثيقة واحدة فقط، نضاعفها تجنبًا لمشاكل العرض في العجلة
      if (docs.length == 1) {
        docs = [docs.first, docs.first];
      }
      setState(() {
        wheelDiscounts = docs;
        isLoading = false;
      });
    });

    // 3) تهيئة ConfettiController
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    selected.close();
    _confettiController.dispose();
    super.dispose();
  }

  /// التحقق إن كان هذا الجهاز لديه خصم يمنعه من الدوران
  Future<bool> _hasExistingPrize() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('winners')
        .where('deviceId', isEqualTo: _deviceId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final doc = snapshot.docs.first;
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return false;

    final discount = data['discount'] as Map<String, dynamic>?;
    if (discount == null) {
      return true;
    }

    final Timestamp? ts = data['timestamp'];
    if (ts == null) {
      return true;
    }

    final DateTime wonAt = ts.toDate();
    final Duration diff = DateTime.now().difference(wonAt);
    final bool isUsed = discount['isUsed'] == true;

    // إذا الخصم غير مستخدم -> لا يمكن
    if (!isUsed) return true;
    // إذا الخصم مستخدم ولم تمر 3 أيام -> لا يمكن
    if (diff.inDays < 3) return true;

    // إذا مر عليه >=3 أيام -> يمكن
    return false;
  }

  /// تسجيل بيانات الخصم الفائز في Firestore
  Future<void> _recordWinningDiscount(DocumentSnapshot discountDoc) async {
    final discountData = discountDoc.data() as Map<String, dynamic>;

    // 1) تخزينه ضمن winners
    await FirebaseFirestore.instance.collection('winners').add({
      'deviceId': _deviceId,
      'discount': discountData,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2) إنشاء خصم جديد بنفس البيانات لكن بكود مختلف
    final String newCode = 'DISC-${DateTime.now().millisecondsSinceEpoch}';
    final newDiscountData = Map<String, dynamic>.from(discountData);
    newDiscountData['code'] = newCode;
    newDiscountData['isUsed'] = false;
    newDiscountData['used_count'] = 0;

    await FirebaseFirestore.instance.collection('discounts').add(newDiscountData);

    // 3) حذف الخصم القديم
    await discountDoc.reference.delete();
  }

  /// عرض رسالة تنبيه
  Future<void> _showWarningDialog(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "تنبيه",
          style: TextStyle(color: Colors.blue),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.blueAccent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("حسناً", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  /// بناء الشرائح بلون (Gradient) موحّد
  List<FortuneItem> _buildFortuneItems() {
    return wheelDiscounts.asMap().entries.map((entry) {
      final index = entry.key;
      final discountDoc = entry.value;
      final discountData = discountDoc.data() as Map<String, dynamic>;
      final discountType = discountData['type'];
      final discountValue = discountData['value'];

      // إنشاء نص العرض
      String displayText;
      if (discountType == 'percentage') {
        displayText = '$discountValue% خصم';
      } else if (discountType == 'fixed') {
        displayText = '${currencyFormat.format(discountValue)} خصم';
      } else {
        displayText = 'خصم غير معروف';
      }

      // الشريحة: نفس التدرّج في كل شريحة
      return FortuneItem(
        style: FortuneItemStyle(
          color: Colors.transparent, // نجعل خلفية style شفافة
          borderColor: Colors.white,
          borderWidth: 2,
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _brandGradient, // نفس التدرّج
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _brandGradient.last.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: Text(
            '🎉 $displayText',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }).toList();
  }

  /// زر الدوران - تدرج بنفس الألوان
  Widget _buildSpinButton() {
    return ElevatedButton(
      onPressed: isSpinning
          ? null
          : () async {
        final blocked = await _hasExistingPrize();
        if (blocked) {
          await _showWarningDialog(
            "لديك خصم حالي أو لم تمضِ 3 أيام على آخر خصم!",
          );
          return;
        }

        if (wheelDiscounts.isEmpty) {
          await _showWarningDialog("لا توجد خصومات متاحة حالياً");
          return;
        }

        setState(() {
          isSpinning = true;
          _winningIndex = null;
        });

        int randomValue = Fortune.randomInt(0, wheelDiscounts.length);

        // منع تكرار القيمة السابقة مباشرة
        if (_lastValue != null && randomValue == _lastValue) {
          randomValue = (randomValue + 1) % wheelDiscounts.length;
        }
        _lastValue = randomValue;
        _pendingIndex = randomValue;

        Future.delayed(const Duration(milliseconds: 100), () {
          selected.add(randomValue);
        });
      },
      style: ButtonStyle(
        padding: MaterialStateProperty.all(EdgeInsets.zero),
        elevation: MaterialStateProperty.all(5),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _brandGradient, // نفس التدرّج
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          constraints: const BoxConstraints(minWidth: 140, minHeight: 50),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.casino, size: 26, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'ابدأ الدوران!',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // خلفية بيضاء
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          // تأثير القصاصات الورقية
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.03,
              numberOfParticles: 20,
              gravity: 0.4,
            ),
          ),

          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // العجلة
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: FortuneWheel(
                          selected: selected.stream,
                          animateFirst: false,
                          duration: const Duration(seconds: 4),
                          rotationCount: 6,
                          curve: Curves.decelerate,
                          onAnimationEnd: () {
                            setState(() {
                              _winningIndex = _pendingIndex;
                              isSpinning = false;
                            });
                            // إطلاق القصاصات
                            _confettiController.play();

                            if (_winningIndex != null &&
                                _winningIndex! < wheelDiscounts.length) {
                              final doc = wheelDiscounts[_winningIndex!];
                              _recordWinningDiscount(doc);
                            }
                          },
                          // الشرائح
                          items: _buildFortuneItems(),
                          // المؤشر (سهم علوي)
                          indicators: [
                            FortuneIndicator(
                              alignment: Alignment.topCenter,
                              child: Transform.translate(
                                offset: const Offset(0, -10),
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  size: 50,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // عرض الخصم الفائز
                  if (_winningIndex != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Builder(builder: (context) {
                        final discountDoc = wheelDiscounts[_winningIndex!];
                        final discountData =
                        discountDoc.data() as Map<String, dynamic>;
                        final discountType = discountData['type'];
                        final discountValue = discountData['value'];

                        String displayText;
                        if (discountType == 'percentage') {
                          displayText = '$discountValue% خصم';
                        } else if (discountType == 'fixed') {
                          displayText =
                          '${currencyFormat.format(discountValue)} خصم';
                        } else {
                          displayText = 'خصم غير معروف';
                        }

                        return Text(
                          'لقد ربحت: $displayText',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        );
                      }),
                    ),

                  // زر الدوران بالألوان نفسها
                  _buildSpinButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
