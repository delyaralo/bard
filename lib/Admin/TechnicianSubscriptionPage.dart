import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class TechnicianSubscriptionPage extends StatefulWidget {
  final String technicianId;
  final Map<String, dynamic> technicianData;

  TechnicianSubscriptionPage({
    required this.technicianId,
    required this.technicianData,
  });

  @override
  _TechnicianSubscriptionPageState createState() =>
      _TechnicianSubscriptionPageState();
}

class _TechnicianSubscriptionPageState
    extends State<TechnicianSubscriptionPage> {
  DateTime? _selectedEndDate; // تاريخ انتهاء الاشتراك المحدد
  String? _selectedSubscriptionType; // نوع الاشتراك المحدد
  bool _isLoading = false;
  DateTime? _currentEndDate;

  final List<String> _subscriptionTypes = ['A', 'B', 'C'];

  @override
  void initState() {
    super.initState();
    // الحصول على تاريخ انتهاء الاشتراك الحالي ونوع الاشتراك إذا كان موجودًا
    final subscriptionEndDate = widget.technicianData['subscriptionEndDate'];
    final subscriptionType = widget.technicianData['subscriptionType'];

    if (subscriptionEndDate != null) {
      if (subscriptionEndDate is Timestamp) {
        _currentEndDate = subscriptionEndDate.toDate();
      } else if (subscriptionEndDate is DateTime) {
        _currentEndDate = subscriptionEndDate;
      }
    }
    // تعيين تاريخ الانتهاء المحدد إلى تاريخ الانتهاء الحالي
    _selectedEndDate = _currentEndDate;
    // تعيين نوع الاشتراك الحالي
    _selectedSubscriptionType = subscriptionType;
  }

  String _getSubscriptionStatus() {
    if (_currentEndDate == null) {
      return 'لا يوجد اشتراك حالي';
    } else {
      if (_currentEndDate!.isAfter(DateTime.now())) {
        final formattedDate =
        DateFormat('dd/MM/yyyy').format(_currentEndDate!);
        return 'الاشتراك مفعل حتى $formattedDate';
      } else {
        final formattedDate =
        DateFormat('dd/MM/yyyy').format(_currentEndDate!);
        return 'انتهى الاشتراك في $formattedDate';
      }
    }
  }

  Future<void> _updateSubscription() async {
    if (_selectedEndDate == null || _selectedSubscriptionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى تحديد تاريخ ونوع الاشتراك')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technicianId)
          .update({
        'subscriptionEndDate': Timestamp.fromDate(_selectedEndDate!),
        'subscriptionType': _selectedSubscriptionType,
        'isSubscribed': _selectedEndDate!.isAfter(DateTime.now()),
      });

      setState(() {
        _isLoading = false;
        _currentEndDate = _selectedEndDate;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث الاشتراك بنجاح')),
      );

      Navigator.pop(context, true); // العودة مع مؤشر على التحديث
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحديث الاشتراك: $e')),
      );
    }
  }

  Future<void> _deleteSubscription() async {
    // تأكيد الحذف
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد حذف الاشتراك'),
        content: Text('هل أنت متأكد أنك تريد حذف الاشتراك؟'),
        actions: [
          TextButton(
            child: Text('إلغاء'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: Text('حذف'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technicianId)
          .update({
        'subscriptionEndDate': null,
        'subscriptionType': null,
        'isSubscribed': false,
      });

      setState(() {
        _isLoading = false;
        _currentEndDate = null;
        _selectedEndDate = null;
        _selectedSubscriptionType = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف الاشتراك بنجاح')),
      );

      Navigator.pop(context, true); // العودة مع مؤشر على التحديث
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف الاشتراك: $e')),
      );
    }
  }

  Future<void> _pickEndDate() async {
    DateTime initialDate = _selectedEndDate ?? DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(DateTime.now())
          ? initialDate
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
      helpText: 'اختر تاريخ انتهاء الاشتراك',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      locale: Locale('ar', ''), // لضبط اللغة العربية
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            primaryColor: Colors.lightBlue,
            colorScheme: ColorScheme.light(
              primary: Colors.lightBlue,
            ),
          ),
          child: Directionality(
            textDirection: ui.TextDirection.rtl, // استخدم ui.TextDirection.rtl
            child: child!,
          ),
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedEndDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionStatus = _getSubscriptionStatus();
    final formattedSelectedDate = _selectedEndDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
        : 'لم يتم التحديد';

    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الاشتراك'),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عرض حالة الاشتراك الحالية
              Center(
                child: Text(
                  'حالة الاشتراك الحالية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.lightBlue[50],
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: Colors.lightBlue,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      subscriptionStatus,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Amiri',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedSubscriptionType != null)
                      Text(
                        'نوع الاشتراك: ${_selectedSubscriptionType}',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Amiri',
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              // اختيار نوع الاشتراك
              Text(
                'حدد نوع الاشتراك',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSubscriptionType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                items: _subscriptionTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text('الفئة $type'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubscriptionType = value;
                  });
                },
                hint: Text('اختر نوع الاشتراك'),
              ),
              SizedBox(height: 32),
              // اختيار تاريخ انتهاء الاشتراك
              Text(
                'تحديث تاريخ انتهاء الاشتراك',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _pickEndDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      suffixIcon: Icon(Icons.calendar_today),
                      hintText: 'اختر تاريخ انتهاء الاشتراك',
                    ),
                    controller: TextEditingController(
                        text: formattedSelectedDate),
                  ),
                ),
              ),
              SizedBox(height: 32),
              // زر حفظ الاشتراك
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _updateSubscription,
                  icon: Icon(Icons.save),
                  label: Text(
                    'حفظ الاشتراك',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // زر حذف الاشتراك
              if (_currentEndDate != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _deleteSubscription,
                    icon: Icon(Icons.delete),
                    label: Text(
                      'حذف الاشتراك',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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
    );
  }
}