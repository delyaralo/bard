import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // لاستعمال Timer
import 'package:cached_network_image/cached_network_image.dart'; // لتحميل الصور بكفاءة
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:hive/hive.dart';

// تأكد من استيراد صفحة عرض الملف الشخصي للفني
import 'package:bard/custmerPage/catalage.dart';

class TechnicianListPage extends StatefulWidget {
  final String specialty;
  final String province;
  final String area;
  final String userName;
  final String userPhone;

  TechnicianListPage({
    required this.specialty,
    required this.province,
    required this.area,
    required this.userName,
    required this.userPhone,
  });

  @override
  _TechnicianListPageState createState() => _TechnicianListPageState();
}

class _TechnicianListPageState extends State<TechnicianListPage> {
  bool _isLoadingSplash = true; // شاشة التحميل (Splash Screen)
  bool _isLoadingData = true; // تحميل بيانات الفنيين
  List<Map<String, dynamic>> _technicians = [];
  List<Map<String, dynamic>> _userRequests = [];

  // بوكسات الكاش باستخدام Hive لتخزين بيانات الفنيين وطلبات المستخدم
  Box? _techniciansBox;
  Box? _requestsBox;

  @override
  void initState() {
    super.initState();
    _initializeBoxes();
    _fetchTechnicians();
    _fetchUserRequests();
    _startSplashTimer();
  }

  Future<void> _initializeBoxes() async {
    _techniciansBox = await Hive.openBox('technicians');
    _requestsBox = await Hive.openBox('userRequests');
    setState(() {});
  }

  // بدء مؤقت شاشة التحميل لمدة 5 ثوانٍ
  void _startSplashTimer() {
    Timer(Duration(seconds: 5), () {
      setState(() {
        _isLoadingSplash = false;
      });
    });
  }

  // دالة تحدد أولوية الفئة: A → 1، B → 2، C → 3، وإذا لم يكن محدداً → 4.
  int _subscriptionPriority(String? subscriptionType) {
    if (subscriptionType == 'A') return 1;
    if (subscriptionType == 'B') return 2;
    if (subscriptionType == 'C') return 3;
    return 4;
  }

  // جلب بيانات الفنيين من Firestore بناءً على التخصص والمنطقة
  // ويتم تصفية الفنيين بحيث يُعرض فقط من لديهم اشتراك نشط (تاريخ انتهاء الاشتراك بعد الآن)
  Future<void> _fetchTechnicians() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .where('specialty', isEqualTo: widget.specialty)
          .where('province', isEqualTo: widget.province)
          .where('area', isEqualTo: widget.area)
          .get();

      List<Map<String, dynamic>> technicians = snapshot.docs.map((doc) {
        return {
          'id': doc.id, // إضافة معرف الوثيقة
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      // تصفية الفنيين بحيث يتم عرض فقط من لديهم اشتراك نشط
      technicians = technicians.where((tech) {
        Timestamp? subTS = tech['subscriptionEndDate'];
        if (subTS == null) return false;
        DateTime subDate = subTS.toDate();
        return subDate.isAfter(DateTime.now());
      }).toList();

      // ترتيب الفنيين:
      technicians.sort((a, b) {
        Timestamp aTS = a['subscriptionEndDate'];
        Timestamp bTS = b['subscriptionEndDate'];
        DateTime aDate = aTS.toDate();
        DateTime bDate = bTS.toDate();

        int aPriority = _subscriptionPriority(a['subscriptionType']);
        int bPriority = _subscriptionPriority(b['subscriptionType']);
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        // ضمن الفنيين ذوي نفس الفئة، الفني الذي ينتهي اشتراكه في وقت لاحق يأتي أولاً
        return bDate.compareTo(aDate);
      });

      // تحديث الكاش بعد جلب البيانات
      if (_techniciansBox != null) {
        await _techniciansBox!.put('techniciansData', technicians);
      }

      setState(() {
        _technicians = technicians;
        _isLoadingData = false;
      });
    } catch (e) {
      print('Error fetching technicians: $e');
      // في حال حدوث خطأ، نحاول استرجاع البيانات من الكاش
      if (_techniciansBox != null &&
          _techniciansBox!.containsKey('techniciansData')) {
        setState(() {
          _technicians = List<Map<String, dynamic>>.from(
              _techniciansBox!.get('techniciansData'));
          _isLoadingData = false;
        });
      } else {
        setState(() {
          _isLoadingData = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء جلب قائمة الفنيين'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // جلب الطلبات الحالية للمستخدم
  Future<void> _fetchUserRequests() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('customerName', isEqualTo: widget.userName)
          .get();

      List<Map<String, dynamic>> requests = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();

      // تحديث الكاش لطلبات المستخدم
      if (_requestsBox != null) {
        await _requestsBox!.put('requestsData', requests);
      }

      setState(() {
        _userRequests = requests;
      });
    } catch (e) {
      print('Error fetching user requests: $e');
      // محاولة استرجاع الطلبات من الكاش في حال حدوث خطأ
      if (_requestsBox != null && _requestsBox!.containsKey('requestsData')) {
        setState(() {
          _userRequests =
          List<Map<String, dynamic>>.from(_requestsBox!.get('requestsData'));
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء جلب طلباتك الحالية'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // إرسال طلب لفني محدد
  Future<void> _requestTechnician(Map<String, dynamic> technician) async {
    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'customerName': widget.userName,
        'customerPhone': widget.userPhone,
        'technicianName': technician['name'],
        'technicianSpecialty': technician['specialty'],
        'technicianArea': technician['area'],
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // تحديث الطلبات بعد الإضافة
      await _fetchUserRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم طلب الفني بنجاح'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error requesting technician: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء طلب الفني'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // الحصول على حالة الطلب لفني معين إن وجدت
  String? _getRequestStatus(String technicianName) {
    for (var request in _userRequests) {
      if (request['technicianName'] == technicianName) {
        return request['status'];
      }
    }
    return null;
  }

  // تصميم البطاقة الخاصة بكل فني
  Widget _buildTechnicianCard(Map<String, dynamic> technician) {
    final status = _getRequestStatus(technician['name']);

    return Card(
      elevation: 8,
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.lightBlue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بيانات الفني: الصورة، الاسم والتخصص
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: technician['profileImage'] != null
                      ? CachedNetworkImageProvider(technician['profileImage'])
                      : AssetImage('images/t1.jpg') as ImageProvider,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        technician['name'] ?? 'اسم غير متوفر',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'التخصص: ${technician['specialty'] ?? 'غير متوفر'}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(thickness: 1.5),
            SizedBox(height: 16),
            // بيانات الاتصال (الموقع)
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    technician['area'] ?? 'غير متوفر',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // صف يحتوي على أزرار "عرض الملف الشخصي" و"طلب الفني" أو حالة الطلب
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TechnicianProfilePage(
                          technicianId: technician['id'], // تمرير المعرف
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.person),
                  label: Text('الملف الشخصي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                _getRequestStatus(technician['name']) == null
                    ? ElevatedButton.icon(
                  onPressed: () => _requestTechnician(technician),
                  icon: Icon(Icons.person_add),
                  label: Text('طلب الفني'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                )
                    : Container(
                  padding:
                  EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _getRequestStatus(technician['name']) ==
                        'pending'
                        ? Colors.orange.shade100
                        : _getRequestStatus(technician['name']) ==
                        'accepted'
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'حالة الطلب: ${_getRequestStatus(technician['name'])}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _getRequestStatus(technician['name']) ==
                          'pending'
                          ? Colors.orange.shade800
                          : _getRequestStatus(technician['name']) ==
                          'accepted'
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl, // استخدام ui.TextDirection.rtl
      child: Scaffold(
        appBar: _isLoadingSplash
            ? null
            : AppBar(
          title: Text('الفنيين المتاحين',
              style: TextStyle(fontWeight: FontWeight.bold)),
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
        body: Stack(
          children: [
            // المحتوى الرئيسي
            _isLoadingData
                ? Center(child: CircularProgressIndicator())
                : _technicians.isNotEmpty
                ? ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _technicians.length,
              itemBuilder: (context, index) {
                final technician = _technicians[index];
                return _buildTechnicianCard(technician);
              },
            )
                : Center(
              child: Text(
                'لا يوجد فنيين متاحين في هذه المنطقة',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            // شاشة التحميل (Splash Screen)
            if (_isLoadingSplash)
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.white,
                child: Image.asset(
                  'images/s1.gif',
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//---------------------------------------------------------
// مكون عرض الصور المنشورة (يستخدم CachedNetworkImage للكاش)
//---------------------------------------------------------
class PostImagesCarousel extends StatefulWidget {
  final List<dynamic> images;
  const PostImagesCarousel({Key? key, required this.images}) : super(key: key);

  @override
  _PostImagesCarouselState createState() => _PostImagesCarouselState();
}

class _PostImagesCarouselState extends State<PostImagesCarousel> {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.images[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error,
                          size: 40, color: Colors.red),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 10 : 8,
              height: _currentPage == index ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index ? Colors.white : Colors.white54,
              ),
            );
          }),
        )
      ],
    );
  }
}

//---------------------------------------------------------
// صفحة عرض الملف الشخصي للفني
//---------------------------------------------------------
class TechnicianProfilePage extends StatefulWidget {
  final String technicianId;

  const TechnicianProfilePage({Key? key, required this.technicianId})
      : super(key: key);

  @override
  _TechnicianProfilePageState createState() => _TechnicianProfilePageState();
}

class _TechnicianProfilePageState extends State<TechnicianProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _technicianData; // بيانات الفني
  List<Map<String, dynamic>> _posts = []; // منشورات الفني

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchTechnicianData(), _fetchPosts()]);
    setState(() {
      _isLoading = false;
    });
  }

  // جلب بيانات الفني
  Future<void> _fetchTechnicianData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technicianId)
          .get();

      if (doc.exists) {
        setState(() {
          _technicianData = doc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error fetching technician data: $e');
    }
  }

  // جلب منشورات الفني (حتى 5 منشورات)
  Future<void> _fetchPosts() async {
    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technicianId)
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final postsData = postsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      setState(() {
        _posts = List<Map<String, dynamic>>.from(postsData);
      });
    } catch (e) {
      print('Error fetching posts: $e');
    }
  }

  // القسم العلوي للملف الشخصي بخلفية متدرجة
  Widget _buildProfileHeader() {
    final profileImage = _technicianData?['profileImage'];
    final name = _technicianData?['name'] ?? 'غير متوفر';
    final specialty = _technicianData?['specialty'] ?? 'غير متوفر';
    final province = _technicianData?['province'] ?? 'غير متوفر';
    final area = _technicianData?['area'] ?? 'غير متوفر';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff36D1DC), Color(0xff5B86E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'profile_${widget.technicianId}',
            child: CircleAvatar(
              radius: 50,
              backgroundImage: profileImage != null
                  ? CachedNetworkImageProvider(profileImage)
                  : AssetImage('images/t1.jpg') as ImageProvider,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  specialty,
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white70, size: 18),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$province, $area',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // تصميم بطاقة المنشور بطريقة مشابهة لمنشورات التواصل الاجتماعي
  Widget _buildPostCard(Map<String, dynamic> postData) {
    List<dynamic> images = postData['images'] ?? [];
    Timestamp? createdAtTS = postData['createdAt'];
    DateTime? createdAt = createdAtTS != null ? createdAtTS.toDate() : null;
    String postDate = createdAt != null ? DateFormat('yyyy-MM-dd').format(createdAt) : '';
    String description = postData['description'] ?? '';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عرض الصور باستخدام PostImagesCarousel مع CachedNetworkImage
          images.isNotEmpty
              ? PostImagesCarousel(images: images)
              : Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
          ),
          // عرض الوصف إذا وُجد
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                description,
                style: TextStyle(fontSize: 16),
              ),
            ),
          // عرض تاريخ النشر
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'تاريخ النشر: $postDate',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    if (_posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'لا توجد منشورات بعد',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeader(),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'منشورات الفني',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          _buildPostsSection(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ملف الفني',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff36D1DC), Color(0xff5B86E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }
}
