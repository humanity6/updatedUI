import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/signin_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/new_feedback.dart';
import 'screens/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase - replace with your actual supabase URL and anon key
  await Supabase.initialize(
    url: 'https://rkkkzpscggwyxvomfijh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJra2t6cHNjZ2d3eXh2b21maWpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAxNTQwNzgsImV4cCI6MjA1NTczMDA3OH0.2wMu8K0bSTdNe4Tw-QzcShguQPOukOowt_oDewJV9L4',
  );

  runApp(
     MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],child: const MyApp()),
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