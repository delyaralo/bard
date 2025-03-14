// lib/pages/admin_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // لإدارة تواريخ الخصم

// نموذج المحافظة (Governorate)
class Governorate {
  final String id;
  final String name;
  final bool isEntireGovernorateCovered;
  final double? price;

  Governorate({
    required this.id,
    required this.name,
    required this.isEntireGovernorateCovered,
    this.price,
  });

  factory Governorate.fromMap(Map<String, dynamic> data, String documentId) {
    return Governorate(
      id: documentId,
      name: data['name'] ?? '',
      isEntireGovernorateCovered: data['isEntireGovernorateCovered'] ?? false,
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isEntireGovernorateCovered': isEntireGovernorateCovered,
      'price': price,
    };
  }
}

// نموذج المنطقة (Area)
class Area {
  final String id;
  final String name;
  final double price;
  final bool isCoveredByApp;

  Area({
    required this.id,
    required this.name,
    required this.price,
    required this.isCoveredByApp,
  });

  factory Area.fromMap(Map<String, dynamic> data, String documentId) {
    return Area(
      id: documentId,
      name: data['name'] ?? '',
      price: (data['price'] as num).toDouble(),
      isCoveredByApp: data['isCoveredByApp'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'isCoveredByApp': isCoveredByApp,
    };
  }
}

// lib/models/discount_code.dart

class DiscountCode {
  final String id;
  final String code;
  final double discountAmount;
  final bool isPercentage;
  final DateTime expiryDate;
  final int usageLimit;
  final int usedCount;

  DiscountCode({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.isPercentage,
    required this.expiryDate,
    required this.usageLimit,
    required this.usedCount,
  });

  factory DiscountCode.fromMap(Map<String, dynamic> data, String documentId) {
    return DiscountCode(
      id: documentId,
      code: data['code'] ?? '',
      discountAmount: (data['discount_amount'] as num).toDouble(),
      isPercentage: data['is_percentage'] ?? false,
      expiryDate: (data['expiry_date'] as Timestamp).toDate(),
      usageLimit: data['usage_limit'] ?? 0,
      usedCount: data['used_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discount_amount': discountAmount,
      'is_percentage': isPercentage,
      'expiry_date': Timestamp.fromDate(expiryDate),
      'usage_limit': usageLimit,
      'used_count': usedCount,
    };
  }
}


class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _governorateFormKey = GlobalKey<FormState>();
  final _areaFormKey = GlobalKey<FormState>();
  final _technicianPriceFormKey = GlobalKey<FormState>();
  final _discountCodeFormKey = GlobalKey<FormState>(); // مفتاح النموذج لكود الخصم

  // متغيرات محافظة جديدة
  String governorateName = '';
  bool isEntireGovernorateCovered = false;
  double? governoratePrice;

  // متغيرات منطقة جديدة
  String areaName = '';
  double? areaPrice;
  bool isAreaCoveredByApp = false;
  String? selectedGovernorateForArea;

  // متغيرات سعر الفني
  double? technicianPrice;

  // متغيرات كود الخصم
  String discountCode = '';
  double discountAmount = 0.0;
  bool isPercentage = false;
  DateTime? expiryDate;
  int usageLimit = 0;

  List<Governorate> governorates = [];
  List<DiscountCode> discountCodes = []; // قائمة كودات الخصم
  bool isLoadingGovernorates = true;
  bool isLoadingDiscountCodes = true;

  @override
  void initState() {
    super.initState();
    fetchGovernorates();
    fetchTechnicianPrice();
    fetchDiscountCodes(); // جلب كودات الخصم عند بدء الصفحة
  }

  // جلب قائمة المحافظات من Firestore
  Future<void> fetchGovernorates() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('governorates').get();
      List<Governorate> loadedGovernorates = snapshot.docs
          .map((doc) => Governorate.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      setState(() {
        governorates = loadedGovernorates;
        isLoadingGovernorates = false;
      });
    } catch (e) {
      print('Error fetching governorates: $e');
      setState(() {
        isLoadingGovernorates = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل المحافظات. حاول مرة أخرى.')),
      );
    }
  }

  // جلب سعر الفني من Firestore
  Future<void> fetchTechnicianPrice() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('fees').doc('technician').get();
      setState(() {
        technicianPrice = snapshot['price'] != null ? (snapshot['price'] as num).toDouble() : 0.0;
      });
    } catch (e) {
      print('Error fetching technician price: $e');
      setState(() {
        technicianPrice = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل رسوم الفني.')),
      );
    }
  }

  // جلب كودات الخصم من Firestore
  Future<void> fetchDiscountCodes() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('discount_codes').get();
      List<DiscountCode> loadedDiscountCodes = snapshot.docs
          .map((doc) => DiscountCode.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      setState(() {
        discountCodes = loadedDiscountCodes;
        isLoadingDiscountCodes = false;
      });
    } catch (e) {
      print('Error fetching discount codes: $e');
      setState(() {
        isLoadingDiscountCodes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل كودات الخصم. حاول مرة أخرى.')),
      );
    }
  }

  // إضافة محافظة جديدة
  void _addGovernorate() async {
    if (_governorateFormKey.currentState!.validate()) {
      _governorateFormKey.currentState!.save();

      Map<String, dynamic> govData = {
        'name': governorateName,
        'isEntireGovernorateCovered': isEntireGovernorateCovered,
        'price': isEntireGovernorateCovered ? governoratePrice : null,
      };

      try {
        await FirebaseFirestore.instance.collection('governorates').add(govData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة المحافظة بنجاح')),
        );
        _governorateFormKey.currentState!.reset();
        fetchGovernorates();
      } catch (e) {
        print('Error adding governorate: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إضافة المحافظة')),
        );
      }
    }
  }

  // إضافة منطقة جديدة
  void _addArea() async {
    if (_areaFormKey.currentState!.validate()) {
      _areaFormKey.currentState!.save();

      Map<String, dynamic> areaData = {
        'name': areaName,
        'price': areaPrice,
        'isCoveredByApp': isAreaCoveredByApp,
      };

      try {
        await FirebaseFirestore.instance
            .collection('governorates')
            .doc(selectedGovernorateForArea)
            .collection('areas')
            .add(areaData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة المنطقة بنجاح')),
        );
        _areaFormKey.currentState!.reset();
        fetchGovernorates();
      } catch (e) {
        print('Error adding area: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إضافة المنطقة')),
        );
      }
    }
  }

  // تحديث سعر الفني
  void _updateTechnicianPrice() async {
    if (_technicianPriceFormKey.currentState!.validate()) {
      _technicianPriceFormKey.currentState!.save();

      Map<String, dynamic> feeData = {
        'price': technicianPrice,
      };

      try {
        await FirebaseFirestore.instance.collection('fees').doc('technician').set(feeData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث سعر الفني بنجاح')),
        );
      } catch (e) {
        print('Error updating technician price: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحديث سعر الفني')),
        );
      }
    }
  }

  // إضافة كود خصم جديد
  void _addDiscountCode() async {
    if (_discountCodeFormKey.currentState!.validate()) {
      _discountCodeFormKey.currentState!.save();

      Map<String, dynamic> discountData = {
        'code': discountCode,
        'discount_amount': discountAmount,
        'is_percentage': isPercentage,
        'expiry_date': Timestamp.fromDate(expiryDate!),
        'usage_limit': usageLimit,
        'used_count': 0,
      };

      try {
        // التأكد من عدم تكرار كود الخصم
        QuerySnapshot existingCode = await FirebaseFirestore.instance
            .collection('discount_codes')
            .where('code', isEqualTo: discountCode)
            .get();

        if (existingCode.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('كود الخصم موجود بالفعل. اختر كودًا آخر')),
          );
          return;
        }

        await FirebaseFirestore.instance.collection('discount_codes').add(discountData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة كود الخصم بنجاح')),
        );
        _discountCodeFormKey.currentState!.reset();
        fetchDiscountCodes();
      } catch (e) {
        print('Error adding discount code: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إضافة كود الخصم')),
        );
      }
    }
  }

  // حذف كود خصم
  void _deleteDiscountCode(String discountId) async {
    try {
      await FirebaseFirestore.instance.collection('discount_codes').doc(discountId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف كود الخصم بنجاح')),
      );
      fetchDiscountCodes();
    } catch (e) {
      print('Error deleting discount code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف كود الخصم')),
      );
    }
  }

  // حذف محافظة
  void _deleteGovernorate(String govId) async {
    try {
      await FirebaseFirestore.instance.collection('governorates').doc(govId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف المحافظة بنجاح')),
      );
      fetchGovernorates();
    } catch (e) {
      print('Error deleting governorate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف المحافظة')),
      );
    }
  }

  // حذف منطقة
  void _deleteArea(String govId, String areaId) async {
    try {
      await FirebaseFirestore.instance
          .collection('governorates')
          .doc(govId)
          .collection('areas')
          .doc(areaId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف المنطقة بنجاح')),
      );
      fetchGovernorates();
    } catch (e) {
      print('Error deleting area: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف المنطقة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('الصفحة الإدارية'),
          backgroundColor: Colors.blueAccent,
        ),
        body: (isLoadingGovernorates || isLoadingDiscountCodes)
            ? Center()
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // قسم إضافة محافظة جديدة
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _governorateFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة محافظة جديدة',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'اسم المحافظة'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال اسم المحافظة';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              governorateName = value!;
                            },
                          ),
                          SizedBox(height: 16),
                          SwitchListTile(
                            title: Text('تغطية المحافظة بالكامل'),
                            value: isEntireGovernorateCovered,
                            onChanged: (val) {
                              setState(() {
                                isEntireGovernorateCovered = val;
                                if (val) {
                                  governoratePrice = null;
                                }
                              });
                            },
                          ),
                          if (isEntireGovernorateCovered)
                            TextFormField(
                              decoration: InputDecoration(labelText: 'سعر المحافظة'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (isEntireGovernorateCovered) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال سعر المحافظة';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'يرجى إدخال رقم صالح';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) {
                                governoratePrice = double.parse(value!);
                              },
                            ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addGovernorate,
                            child: Text('إضافة المحافظة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // قسم إدارة المحافظات الحالية
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المحافظات الحالية',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: governorates.length,
                          itemBuilder: (context, index) {
                            Governorate gov = governorates[index];
                            return ListTile(
                              title: Text(gov.name),
                              subtitle: gov.isEntireGovernorateCovered
                                  ? Text('تغطية كاملة بسعر: ${gov.price} \$')
                                  : Text('تغطية جزئية'),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteGovernorate(gov.id),
                              ),
                              onTap: () {
                                // يمكنك إضافة خيارات التعديل هنا
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // قسم إضافة منطقة جديدة
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _areaFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة منطقة جديدة',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(labelText: 'اختر المحافظة'),
                            value: selectedGovernorateForArea,
                            items: governorates
                                .map(
                                  (gov) => DropdownMenuItem<String>(
                                value: gov.id,
                                child: Text(gov.name),
                              ),
                            )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedGovernorateForArea = val;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى اختيار المحافظة';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'اسم المنطقة'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال اسم المنطقة';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              areaName = value!;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'سعر المنطقة'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال سعر المنطقة';
                              }
                              if (double.tryParse(value) == null) {
                                return 'يرجى إدخال رقم صالح';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              areaPrice = double.parse(value!);
                            },
                          ),
                          SizedBox(height: 16),
                          SwitchListTile(
                            title: Text('هل المنطقة مشمولة بالتطبيق'),
                            value: isAreaCoveredByApp,
                            onChanged: (val) {
                              setState(() {
                                isAreaCoveredByApp = val;
                              });
                            },
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addArea,
                            child: Text('إضافة المنطقة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // قسم تحديد سعر الفني
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _technicianPriceFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تحديد سعر الفني',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            initialValue: technicianPrice != null ? technicianPrice.toString() : '',
                            decoration: InputDecoration(labelText: 'سعر الفني'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال سعر الفني';
                              }
                              if (double.tryParse(value) == null) {
                                return 'يرجى إدخال رقم صالح';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              technicianPrice = double.parse(value!);
                            },
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _updateTechnicianPrice,
                            child: Text('تحديث سعر الفني'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // قسم إضافة كود خصم جديد
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _discountCodeFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة كود خصم جديد',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'كود الخصم'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال كود الخصم';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              discountCode = value!.trim();
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'قيمة الخصم'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال قيمة الخصم';
                              }
                              if (double.tryParse(value) == null) {
                                return 'يرجى إدخال رقم صالح';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              discountAmount = double.parse(value!);
                            },
                          ),
                          SizedBox(height: 16),
                          SwitchListTile(
                            title: Text('نسبة مئوية'),
                            value: isPercentage,
                            onChanged: (val) {
                              setState(() {
                                isPercentage = val;
                              });
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'تاريخ انتهاء الصلاحية'),
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  expiryDate = pickedDate;
                                });
                              }
                            },
                            validator: (value) {
                              if (expiryDate == null) {
                                return 'يرجى اختيار تاريخ انتهاء الصلاحية';
                              }
                              return null;
                            },
                            controller: TextEditingController(
                                text: expiryDate != null
                                    ? DateFormat('yyyy-MM-dd').format(expiryDate!)
                                    : ''),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'حد الاستخدام'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال حد الاستخدام';
                              }
                              if (int.tryParse(value) == null) {
                                return 'يرجى إدخال عدد صالح';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              usageLimit = int.parse(value!);
                            },
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addDiscountCode,
                            child: Text('إضافة كود الخصم'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // قسم إدارة كودات الخصم الحالية
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كودات الخصم الحالية',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        discountCodes.isEmpty
                            ? Text('لا توجد كودات خصم حالياً.')
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: discountCodes.length,
                          itemBuilder: (context, index) {
                            DiscountCode discount = discountCodes[index];
                            return ListTile(
                              title: Text(discount.code),
                              subtitle: Text(
                                  '${discount.isPercentage ? discount.discountAmount.toStringAsFixed(0) + '%' : discount.discountAmount.toStringAsFixed(2) + ' \$'} - انتهاء الصلاحية: ${DateFormat('yyyy-MM-dd').format(discount.expiryDate)}'),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteDiscountCode(discount.id),
                              ),
                              onTap: () {
                                // يمكنك إضافة خيارات التعديل هنا
                                _showEditDiscountDialog(discount);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  // دالة لإظهار مربع حوار لتعديل كود الخصم
  void _showEditDiscountDialog(DiscountCode discount) {
    showDialog(
      context: context,
      builder: (context) {
        // متغيرات محلية لتخزين البيانات المعدلة
        String updatedCode = discount.code;
        double updatedDiscountAmount = discount.discountAmount;
        bool updatedIsPercentage = discount.isPercentage;
        DateTime? updatedExpiryDate = discount.expiryDate;
        int updatedUsageLimit = discount.usageLimit;

        return AlertDialog(
          title: Text('تعديل كود الخصم'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'كود الخصم'),
                      controller: TextEditingController(text: updatedCode),
                      onChanged: (value) {
                        updatedCode = value.trim();
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: 'قيمة الخصم'),
                      keyboardType: TextInputType.number,
                      controller:
                      TextEditingController(text: updatedDiscountAmount.toString()),
                      onChanged: (value) {
                        updatedDiscountAmount = double.tryParse(value) ?? 0.0;
                      },
                    ),
                    SizedBox(height: 10),
                    SwitchListTile(
                      title: Text('نسبة مئوية'),
                      value: updatedIsPercentage,
                      onChanged: (val) {
                        setState(() {
                          updatedIsPercentage = val;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: 'تاريخ انتهاء الصلاحية'),
                      readOnly: true,
                      controller: TextEditingController(
                          text: updatedExpiryDate != null
                              ? DateFormat('yyyy-MM-dd').format(updatedExpiryDate!)
                              : ''),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: updatedExpiryDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            updatedExpiryDate = pickedDate;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: 'حد الاستخدام'),
                      keyboardType: TextInputType.number,
                      controller:
                      TextEditingController(text: updatedUsageLimit.toString()),
                      onChanged: (value) {
                        updatedUsageLimit = int.tryParse(value) ?? 0;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // تحقق من صحة البيانات المعدلة
                if (updatedCode.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('يرجى إدخال كود الخصم')),
                  );
                  return;
                }
                if (updatedDiscountAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('يرجى إدخال قيمة خصم صحيحة')),
                  );
                  return;
                }
                if (updatedExpiryDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('يرجى اختيار تاريخ انتهاء الصلاحية')),
                  );
                  return;
                }
                if (updatedUsageLimit <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('يرجى إدخال حد استخدام صالح')),
                  );
                  return;
                }

                // تحديث كود الخصم في Firestore
                try {
                  await FirebaseFirestore.instance
                      .collection('discount_codes')
                      .doc(discount.id)
                      .update({
                    'code': updatedCode,
                    'discount_amount': updatedDiscountAmount,
                    'is_percentage': updatedIsPercentage,
                    'expiry_date': Timestamp.fromDate(updatedExpiryDate!),
                    'usage_limit': updatedUsageLimit,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تعديل كود الخصم بنجاح')),
                  );
                  fetchDiscountCodes();
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error updating discount code: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ أثناء تعديل كود الخصم')),
                  );
                }
              },
              child: Text('تعديل'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }
}
