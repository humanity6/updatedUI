// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  // Add public method to get stylists
  Future<List<Map<String, dynamic>>> getStylists() async {
    try {
      final response = await _supabase
          .from('stylists')
          .select('stylist_id, first_name, last_name')
          .order('first_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Add public method to get unreviewed appointments
  Future<Map<String, dynamic>?> getUnreviewedAppointment(String stylistId, String userId) async {
    try {
      final appointmentsResponse = await _supabase
          .from('appointments')
          .select('''
            appointment_id,
            appointment_date,
            start_time,
            status
          ''')
          .eq('stylist_id', stylistId)
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('appointment_date', ascending: false)
          .limit(1);

      if (appointmentsResponse.isEmpty) return null;

      final latestAppointment = appointmentsResponse[0];
      final feedbackExists = await getFeedback(latestAppointment['appointment_id']);

      return feedbackExists == null ? latestAppointment : null;
    } catch (e) {
      return null;
    }
  }

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

  // Submit feedback for an appointment
  Future<void> submitFeedback({
    required String stylistId,
    required int rating,
    String? comment,
  }) async {
    if (_user == null) throw Exception('User must be authenticated to submit feedback');
    if (rating < 1 || rating > 5) throw Exception('Rating must be between 1 and 5');

    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.from('feedback').insert({
        'user_id': _user!.id,
        'stylist_id': stylistId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get feedback for a specific appointment
  Future<Map<String, dynamic>?> getFeedback(String appointmentId) async {
    try {
      final response = await _supabase
          .from('feedback')
          .select()
          .eq('appointment_id', appointmentId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Get all feedback for a stylist
  Future<List<Map<String, dynamic>>> getStylistFeedback(String stylistId) async {
    try {
      final response = await _supabase
          .from('feedback')
          .select()
          .eq('stylist_id', stylistId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Get average rating for a stylist
  Future<double> getStylistAverageRating(String stylistId) async {
    try {
      final response = await _supabase
          .from('feedback')
          .select('rating')
          .eq('stylist_id', stylistId);

      final ratings = List<int>.from(
          response.map((feedback) => feedback['rating'] as int)
      );

      if (ratings.isEmpty) return 0.0;

      return ratings.reduce((a, b) => a + b) / ratings.length;
    } catch (e) {
      return 0.0;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _user = null;
    notifyListeners();
  }
}