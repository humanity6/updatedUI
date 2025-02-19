// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initUser();
  }

  void _initUser() {
    _user = _supabase.auth.currentUser;
    notifyListeners();

    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _user = response.user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create user auth account
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // Insert user data into the users table
      if (response.user != null) {
        await _supabase.from('users').insert({
          'user_id': response.user!.id,  // This will now be a UUID
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone_number': phoneNumber,
        });
      }

      _user = response.user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _user = null;
    notifyListeners();
  }
}