import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class StylistFeedbackScreen extends StatefulWidget {
  const StylistFeedbackScreen({super.key});

  @override
  State<StylistFeedbackScreen> createState() => _StylistFeedbackScreenState();
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() {
    return 'NetworkException: $message';
  }
}

class ServerErrorException implements Exception {
  final String message;
  ServerErrorException(this.message);

  @override
  String toString() {
    return 'ServerErrorException: $message';
  }
}

class ValidationException implements Exception {
  final String message;
  final dynamic details;
  ValidationException(this.message, {this.details});

  @override
  String toString() {
    String detailString = details != null ? 'Details: $details' : '';
    return 'ValidationException: $message $detailString';
  }
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() {
    return 'AuthenticationException: $message';
  }
}

class _StylistFeedbackScreenState extends State<StylistFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  String? _selectedStylistId;
  String? _selectedStylistName;
  bool _isLoading = false;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _stylists = [];
  Map<String, dynamic>? _unreviewedAppointment;
  int _rating = 0;
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _loadingAppointment = false;

  @override
  void initState() {
    super.initState();
    _loadStylists();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadStylists() async {
    setState(() => _isLoading = true);
    try {
      final response = await Provider.of<AuthProvider>(context, listen: false).getStylists();
      setState(() => _stylists = response);
    } catch (e) {
      _showError('Failed to load stylists: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUnreviewedAppointment(String stylistId) async {
    setState(() => _loadingAppointment = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw AuthenticationException('User not authenticated');
      }

      final appointment = await authProvider.getUnreviewedAppointment(stylistId, userId);
      setState(() => _unreviewedAppointment = appointment);
    } catch (e) {
      _showError('Failed to load appointment: ${e.toString()}');
    } finally {
      setState(() => _loadingAppointment = false);
    }
  }

  Future<void> _loadReviews(String stylistId) async {
    setState(() {
      _isLoading = true;
      _reviews = [];
    });

    try {
      final reviews = await Provider.of<AuthProvider>(context, listen: false)
          .getStylistFeedback(stylistId);
      setState(() => _reviews = reviews);
    } catch (e) {
      _showError('Failed to load reviews: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _handleSubmit() async {
    if (_rating == 0) {
      setState(() => _errorMessage = 'Please select a rating');
      return;
    }

    if (_unreviewedAppointment == null) {
      setState(() => _errorMessage = 'No recent completed appointment found to review');
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        // Update submitFeedback in auth_provider.dart to match this signature
        // We need to modify auth_provider to include appointment_id parameter
        await _modifiedSubmitFeedback(
          Provider.of<AuthProvider>(context, listen: false),
          stylistId: _selectedStylistId!,
          appointmentId: _unreviewedAppointment!['appointment_id'],
          rating: _rating,
          comment: _commentController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _rating = 0;
            _commentController.clear();
            _unreviewedAppointment = null; // Clear appointment after successful review
          });
          _loadReviews(_selectedStylistId!);
          _showSuccess('Thank you for your feedback!');
        }
      } catch (e) {
        String errorMessage = 'Failed to submit feedback. Please try again.';

        if (e is NetworkException) {
          errorMessage = 'Network issue. Please check your connection.';
        } else if (e is ServerErrorException) {
          errorMessage = 'Server error. Please try again later.';
        } else if (e is ValidationException) {
          errorMessage = e.details != null
              ? 'Validation error: ${e.details}'
              : 'Please check your rating and comment.';
        } else if (e is AuthenticationException) {
          errorMessage = 'Please sign in again to submit feedback.';
        } else {
          print('Error submitting feedback: $e');
        }

        setState(() => _errorMessage = errorMessage);
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  // This is a temporary wrapper function since we need to modify the auth provider
  Future<void> _modifiedSubmitFeedback(
      AuthProvider provider, {
        required String stylistId,
        required String appointmentId,
        required int rating,
        String? comment,
      }) async {
    if (provider.user == null) throw AuthenticationException('User must be authenticated');
    if (rating < 1 || rating > 5) throw ValidationException('Rating must be between 1 and 5');

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('feedback').insert({
        'user_id': provider.user!.id,
        'stylist_id': stylistId,
        'appointment_id': appointmentId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      rethrow;
    }
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${review['rating']}/5',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateTime.parse(review['created_at'])
                        .toLocal()
                        .toString()
                        .split('.')[0],
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review['comment'] ?? 'No comment',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentInfoSection() {
    if (_loadingAppointment) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_unreviewedAppointment == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: const Text(
          'You don\'t have any recent completed appointments with this stylist to review.',
          style: TextStyle(color: Colors.orange),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Format appointment date and time
    final appointmentDate = DateTime.parse(_unreviewedAppointment!['appointment_date']);
    final formattedDate = '${appointmentDate.year}-${appointmentDate.month.toString().padLeft(2, '0')}-${appointmentDate.day.toString().padLeft(2, '0')}';
    final startTime = _unreviewedAppointment!['start_time'] ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reviewing Appointment:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Date: $formattedDate'),
          const SizedBox(height: 4),
          Text('Time: $startTime'),
          const SizedBox(height: 4),
          Text('Status: ${_unreviewedAppointment!['status'] ?? 'Completed'}'),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Leave Your Feedback',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Show appointment info
            if (_selectedStylistId != null)
              _buildAppointmentInfoSection(),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 32,
                    color: index < _rating ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () => setState(() {
                    _rating = index + 1;
                    _errorMessage = null;
                  }),
                );
              }),
            ),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedStylistId == null ||
                  _isSubmitting ||
                  _unreviewedAppointment == null ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Submit Feedback'),
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
        title: const Text('Stylist Reviews'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Stylist',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              value: _selectedStylistId,
              items: _stylists.map<DropdownMenuItem<String>>((stylist) {
                return DropdownMenuItem<String>(
                  value: stylist['stylist_id'] as String,
                  child: Text('${stylist['first_name']} ${stylist['last_name']}'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStylistId = newValue;
                    _selectedStylistName =
                    '${_stylists.firstWhere((s) => s['stylist_id'] == newValue)['first_name']} '
                        '${_stylists.firstWhere((s) => s['stylist_id'] == newValue)['last_name']}';
                    _errorMessage = null;
                    _rating = 0;
                    _commentController.clear();
                  });
                  _loadReviews(newValue);
                  _loadUnreviewedAppointment(newValue);
                }
              },
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_selectedStylistId != null)
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadReviews(_selectedStylistId!);
                  await _loadUnreviewedAppointment(_selectedStylistId!);
                },
                child: CustomScrollView(
                  slivers: [
                    if (_selectedStylistName != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Reviews for $_selectedStylistName',
                                  style: Theme.of(context).textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${_reviews.length} reviews',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    _reviews.isEmpty
                        ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No reviews yet for this stylist',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                        : SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildReviewCard(_reviews[index]),
                        childCount: _reviews.length,
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
                  ],
                ),
              ),
            ),
          _buildFeedbackSection(),
        ],
      ),
    );
  }
}