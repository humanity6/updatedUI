import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/signin_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/payment_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase - replace with your actual supabase URL and anon key
  await Supabase.initialize(
    url: 'https://pvelqzevgmwgdyhzmbpn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2ZWxxemV2Z213Z2R5aHptYnBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk4Nzg3ODAsImV4cCI6MjA1NTQ1NDc4MH0.Rhq62p3su53B2XNR31lNBIKKgaTCXgRmcH02RbRipj0',
  );

  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ], child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Salon Manager',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SignInScreen(),
    );
  }
}