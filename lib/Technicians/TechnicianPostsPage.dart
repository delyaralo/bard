import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';


class TechnicianPostsPage extends StatefulWidget {
  final String technicianId; // معرف الفني

  const TechnicianPostsPage({Key? key, required this.technicianId})
      : super(key: key);

  @override
  _TechnicianPostsPageState createState() => _TechnicianPostsPageState();
}

class _TechnicianPostsPageState extends State<TechnicianPostsPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _posts = []; // قائمة المنشورات الحالية

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  // جلب المنشورات الحالية
  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technicianId)
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();

      final postsData = postsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      setState(() {
        _posts = List<Map<String, dynamic>>.from(postsData);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // رفع المنشور مع النص والصور
  Future<void> _uploadNewPost(
      String description, List<XFile> selectedImages) async {
    setState(() {
      _isLoading = true;
    });
    try {
      // رفع الصور إلى Firebase Storage والحصول على روابطها
      List<String> imageUrls = [];
      for (XFile imageFile in selectedImages) {
        String fileName = const Uuid().v4();
        File file = File(imageFile.path);

        final ref = FirebaseStorage.instance
            .ref()
            .child('technician_posts')
            .child(widget.technicianId)
            .child(fileName);

        await ref.putFile(file);
        String downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // حفظ بيانات المنشور في Subcollection "posts"
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technicianId)
          .collection('posts')
          .add({
        'description': description,
        'images': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إضافة المنشور بنجاح')),
      );
      await _fetchPosts();
    } catch (e) {
      print('Error adding post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إضافة المنشور')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // عرض حوار لإضافة منشور جديد مع تقييد الأبعاد لتجنب مشكلة intrinsic dimensions
  Future<void> _showAddPostDialog() async {
    if (_posts.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يمكن إضافة أكثر من 5 منشورات')),
      );
      return;
    }

    TextEditingController descriptionController = TextEditingController();
    List<XFile> selectedImages = [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("إضافة منشور جديد"),
              content: SizedBox(
                width: 300, // تحديد عرض ثابت للمحتوى
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: "النص (اختياري)",
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final List<XFile>? pickedFiles =
                          await ImagePicker().pickMultiImage(
                            maxWidth: 1024,
                            maxHeight: 1024,
                            imageQuality: 80,
                          );
                          if (pickedFiles != null && pickedFiles.isNotEmpty) {
                            setStateDialog(() {
                              selectedImages = pickedFiles.take(3).toList();
                            });
                          }
                        },
                        child: Text("اختيار الصور (حتى 3)"),
                      ),
                      SizedBox(height: 10),
                      if (selectedImages.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.file(
                                  File(selectedImages[index].path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("إلغاء"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedImages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("يرجى اختيار صورة واحدة على الأقل")),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    await _uploadNewPost(
                        descriptionController.text, selectedImages);
                  },
                  child: Text("إضافة المنشور"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // حذف منشور
  Future<void> _deletePost(String postId, List<dynamic> imageUrls) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف المنشور'),
        content: Text('هل أنت متأكد أنك تريد حذف هذا المنشور؟'),
        actions: [
          TextButton(
            child: Text('إلغاء'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: Text('حذف'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technicianId)
          .collection('posts')
          .doc(postId)
          .delete();

      for (String url in imageUrls) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (e) {
          // تجاهل الخطأ إذا لم تتوفر الصورة
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف المنشور')),
      );

      await _fetchPosts();
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف المنشور')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // تصميم بطاقة المنشور
  Widget _buildPostCard(Map<String, dynamic> postData) {
    List<dynamic> images = postData['images'] ?? [];
    String postId = postData['id'];
    Timestamp? createdAtTS = postData['createdAt'];
    DateTime? createdAt =
    createdAtTS != null ? createdAtTS.toDate() : null;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            if (images.isNotEmpty)
              Container(
                height: 200,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 8),
            if (createdAt != null)
              Text(
                'تاريخ النشر: ${DateFormat('yyyy-MM-dd HH:mm').format(createdAt)}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _deletePost(postId, images),
              icon: Icon(Icons.delete),
              label: Text('حذف المنشور'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('منشورات الفني'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isLoading)
            Center(child: CircularProgressIndicator()),
          if (!_isLoading)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showAddPostDialog,
                    icon: Icon(Icons.add),
                    label: Text('إضافة منشور جديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: _posts.isEmpty
                        ? Center(child: Text('لا توجد منشورات بعد'))
                        : ListView.builder(
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final postData = _posts[index];
                        return _buildPostCard(postData);
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
