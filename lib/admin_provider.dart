// lib/providers/admin_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Governorate {
  String id;
  String name;
  bool isEntireGovernorateCovered;
  double? price;

  Governorate({
    required this.id,
    required this.name,
    required this.isEntireGovernorateCovered,
    this.price,
  });


  factory Governorate.fromMap(Map<String, dynamic> map, String id) {
    return Governorate(
      id: id,
      name: map['name'],
      isEntireGovernorateCovered: map['isEntireGovernorateCovered'],
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
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


class Area {
  String id;
  String name;
  double price;
  bool isCovered;


  Area({
    required this.id,
    required this.name,
    required this.price,
    required this.isCovered,
  });


  factory Area.fromMap(Map<String, dynamic> map, String id) {
    return Area(
      id: id,
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      isCovered: map['isCovered'],
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'isCovered': isCovered,
    };
  }
}


class AdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Governorate> _governorates = [];
  List<Governorate> get governorates => _governorates;

  AdminProvider() {
    fetchGovernorates();
  }

  Future<void> fetchGovernorates() async {
    final snapshot = await _firestore.collection('governorates').get();
    _governorates = snapshot.docs
        .map((doc) => Governorate.fromMap(doc.data(), doc.id))
        .toList();
    notifyListeners();
  }

  Future<void> addGovernorate(Governorate governorate) async {
    await _firestore.collection('governorates').add(governorate.toMap());
    await fetchGovernorates();
  }

  Future<void> updateGovernorate(Governorate governorate) async {
    await _firestore
        .collection('governorates')
        .doc(governorate.id)
        .update(governorate.toMap());
    await fetchGovernorates();
  }

  Future<void> deleteGovernorate(String governorateId) async {
    await _firestore.collection('governorates').doc(governorateId).delete();
    await fetchGovernorates();
  }

  // إدارة المناطق داخل المحافظة
  Future<void> addArea(String governorateId, Area area) async {
    await _firestore
        .collection('governorates')
        .doc(governorateId)
        .collection('areas')
        .add(area.toMap());
    await fetchGovernorates();
  }

  Future<void> updateArea(String governorateId, Area area) async {
    await _firestore
        .collection('governorates')
        .doc(governorateId)
        .collection('areas')
        .doc(area.id)
        .update(area.toMap());
    await fetchGovernorates();
  }

  Future<void> deleteArea(String governorateId, String areaId) async {
    await _firestore
        .collection('governorates')
        .doc(governorateId)
        .collection('areas')
        .doc(areaId)
        .delete();
    await fetchGovernorates();
  }

  // إدارة الرسوم
  Future<void> addFee(String type, double price, {String? governorateId, String? areaId}) async {
    await _firestore.collection('fees').add({
      'type': type,
      'price': price,
      'governorateId': governorateId,
      'areaId': areaId,
    });
  }

  Future<void> updateFee(String feeId, String type, double price, {String? governorateId, String? areaId}) async {
    await _firestore.collection('fees').doc(feeId).update({
      'type': type,
      'price': price,
      'governorateId': governorateId,
      'areaId': areaId,
    });
  }

  Future<void> deleteFee(String feeId) async {
    await _firestore.collection('fees').doc(feeId).delete();
  }
}
