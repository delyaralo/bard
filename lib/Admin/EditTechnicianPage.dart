import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

// تأكد من استيراد الصفحة الجديدة
import 'TechnicianSubscriptionPage.dart';

class EditTechnicianPage extends StatefulWidget {
  final String technicianId;
  final Map<String, dynamic> technicianData;

  EditTechnicianPage({
    required this.technicianId,
    required this.technicianData,
  });

  @override
  _EditTechnicianPageState createState() => _EditTechnicianPageState();
}

class _EditTechnicianPageState extends State<EditTechnicianPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _area;
  late String _number;

  @override
  void initState() {
    super.initState();
    _name = widget.technicianData['name'] ?? '';
    _area = widget.technicianData['area'] ?? '';
    _number = widget.technicianData['number'] ?? '';
  }

  Future<void> _updateTechnician() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await FirebaseFirestore.instance
            .collection('technicians')
            .doc(widget.technicianId)
            .update({
          'name': _name,
          'area': _area,
          'number': _number,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث بيانات الفني بنجاح')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التحديث: $e')),
        );
      }
    }
  }

  // وظيفة للتحقق من حالة الاشتراك
  String _getSubscriptionStatus() {
    final subscriptionEndDate = widget.technicianData['subscriptionEndDate'];
    if (subscriptionEndDate == null) {
      return 'لا يوجد اشتراك';
    } else {
      final endDate = (subscriptionEndDate as Timestamp).toDate();
      if (endDate.isAfter(DateTime.now())) {
        return 'الاشتراك مفعل حتى ${endDate.toLocal()}';
      } else {
        return 'الاشتراك منتهي';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // حالة الاشتراك الحالية
    final subscriptionStatus = _getSubscriptionStatus();

    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل بيانات الفني'),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // حقول التعديل
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'اسم الفني'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم الفني';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _area,
                decoration: InputDecoration(labelText: 'المنطقة'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال المنطقة';
                  }
                  return null;
                },
                onSaved: (value) {
                  _area = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _number,
                decoration: InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  // للسماح بالأرقام فقط
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رقم الهاتف';
                  }
                  return null;
                },
                onSaved: (value) {
                  _number = value!;
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _updateTechnician,
                child: Text('تحديث'),
              ),
              SizedBox(height: 16),
              // عرض حالة الاشتراك
              Text(
                'حالة الاشتراك: $subscriptionStatus',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              // زر إضافة الاشتراك
              ElevatedButton(
                onPressed: () {
                  // الانتقال إلى صفحة إضافة الاشتراك
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TechnicianSubscriptionPage(
                        technicianId: widget.technicianId,
                        technicianData: widget.technicianData,
                      ),
                    ),
                  ).then((value) {
                    // عند العودة، تحديث البيانات
                    setState(() {
                      // يمكنك جلب البيانات المحدثة من Firestore إذا لزم الأمر
                    });
                  });
                },
                child: Text('إضافة اشتراك'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
