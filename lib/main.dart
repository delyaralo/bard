import 'dart:io' show Platform;
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bard/custmerPage/SpinWheelScreen.dart';
import 'custmerPage/HomePage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'device_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:bard/Admin/upimage.dart';
import 'Admin/PrizeSetupPage.dart';
import 'package:bard/custmerPage/LoginPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bard/Admin/StatisticsPage.dart';
import 'package:bard/statements/OrdersCalculatorPage.dart';
import 'package:bard/Admin/MainAdamnPage.dart';
import 'package:bard/SplashScreen.dart';

/// معالجة الرسائل في الخلفية
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ========== تهيئة Supabase ==========
  await Supabase.initialize(
    url: 'https://puzzxscbgswfjqzirpqa.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB1enp4c2NiZ3N3ZmpxemlycHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg3MDI1NDMsImV4cCI6MjA1NDI3ODU0M30.pO6EwQFKYXniH3r_vnju744s8KkCJiwCCF1323bF9Gw',
  );

  // ========== تهيئة Hive ==========
  await Hive.initFlutter();
  await Hive.openBox('categories');
  await Hive.openBox('products');

  // ========== تهيئة Firebase ==========
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تسجيل معالج الرسائل الخلفية فقط على الهواتف
  if (!Platform.isWindows) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // إعداد UUID وتخزينه في SharedPreferences (إذا لم يكن موجود)
  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'device_id';
    String? deviceId = prefs.getString(key);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString(key, deviceId);
    }
    return deviceId;
  }

  // الحصول على UUID للجهاز
  final String deviceId = await getOrCreateDeviceId();

  // الحصول على توكن FCM على الهواتف فقط
  String? fcmToken;
  if (!Platform.isWindows) {
    fcmToken = await getFCMToken();
  } else {
    fcmToken = null;
  }

  // تخزين أو تحديث معلومات الجهاز في Firestore
  await createOrUpdateDeviceDoc(deviceId, fcmToken);

  // مستمع لتحديث توكن FCM على الهواتف فقط
  if (!Platform.isWindows) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(deviceId)
          .update({
        'fcmToken': newToken,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    });
  }

  // منع الوضع الليلي على مستوى النظام
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  // تشغيل التطبيق وتغليفه بـ Provider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DeviceProvider(deviceId),
        ),
      ],
      child: MyApp(isWindows: Platform.isWindows),
    ),
  );

  // في حالة نظام ويندوز، تكبير النافذة أو جعلها ملء الشاشة
  if (Platform.isWindows) {
    doWhenWindowReady(() {
      appWindow.maximize();
      // أو: appWindow.setFullScreen(true);
    });
  }
}

// الدالة للحصول على توكن FCM
Future<String?> getFCMToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    return await messaging.getToken();
  } else {
    print('User declined or has not accepted permission');
    return null;
  }
}

// الدالة لإنشاء أو تحديث وثيقة الجهاز في Firestore
Future<void> createOrUpdateDeviceDoc(String deviceId, String? fcmToken) async {
  final docRef = FirebaseFirestore.instance.collection('devices').doc(deviceId);
  await docRef.set(
    {
      'deviceId': deviceId,
      'fcmToken': fcmToken,
      'lastSeen': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}

class MyApp extends StatelessWidget {
  final bool isWindows;
  const MyApp({Key? key, required this.isWindows}) : super(key: key);

  ThemeData _buildLightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blueAccent,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Amiri',
      colorScheme: const ColorScheme.light(
        primary: Colors.blueAccent,
        secondary: Colors.blueAccent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: GoogleFonts.cairoTextTheme(
        Theme.of(context).textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
    );
  }

  /// هذه الدالة تبني خريطة المسارات (routes) بحسب النظام
  Map<String, WidgetBuilder> _buildRoutes() {
    if (isWindows) {
      // في حال ويندوز: لا نسجل SplashScreen ولا MyHomePage
      return {
        '/login': (context) => const LoginPage(),
      };
    } else {
      // في حال الأجهزة الأخرى: نسجل كل المسارات
      return {
        '/': (context) => const SplashScreen(isWindows: false),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MyHomePage(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // إذا كان التطبيق يعمل على ويندوز، نبدأ بالمسار '/login'
    // وإذا كان غير ويندوز، نبدأ بالمسار '/'
    final String initialRoute = isWindows ? '/login' : '/';

    return MaterialApp(
      title: 'تطبيقك',
      locale: const Locale('ar', ''),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', ''),
      ],
      theme: _buildLightTheme(context),
      initialRoute: initialRoute,
      routes: _buildRoutes(),
      debugShowCheckedModeBanner: false,
    );
  }
}
