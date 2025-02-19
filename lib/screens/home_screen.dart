import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'payment_screen.dart';
import 'tryon_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _dateController = TextEditingController();
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> stylists = [];
  List<Map<String, dynamic>> upcomingAppointments = [];
  String? selectedStylist;
  String? selectedService;
  String? selectedTime;
  double? selectedServicePrice;
  bool isLoading = true;

  // Available time slots
  final List<String> timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final servicesResponse = await _supabase
          .from('services')
          .select('service_id, service_name, price, duration, description');

      final stylistsResponse = await _supabase
          .from('stylists')
          .select('stylist_id, first_name, last_name, bio');

      // Fetch upcoming appointments for the current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final appointmentsResponse = await _supabase
            .from('appointments')
            .select('''
              appointment_id,
              appointment_date,
              start_time,
              status,
              services(service_name, price),
              stylists(first_name, last_name)
            ''')
            .eq('user_id', userId)
            .eq('status', 'scheduled')
            .gte('appointment_date', today)
            .order('appointment_date', ascending: true)
            .order('start_time', ascending: true)
            .limit(5);

        setState(() {
          upcomingAppointments = List<Map<String, dynamic>>.from(appointmentsResponse);
        });
      }

      setState(() {
        services = List<Map<String, dynamic>>.from(servicesResponse);
        stylists = List<Map<String, dynamic>>.from(stylistsResponse);
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _bookAppointment() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to book an appointment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedStylist == null ||
        selectedService == null ||
        _dateController.text.isEmpty ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Insert the appointment in the appointments table
      await _supabase.from('appointments').insert({
        'user_id': userId,
        'stylist_id': selectedStylist,
        'service_id': selectedService,
        'appointment_date': _dateController.text,
        'start_time': selectedTime,
        'status': 'scheduled'
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the appointments list
      _fetchData();

      // Navigate to payment screen if booking was successful
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PaymentScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking appointment: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  // Update service price when a service is selected
  void _updateServicePrice(String serviceId) {
    final selectedServiceData = services.firstWhere(
          (service) => service['service_id'] == serviceId,
      orElse: () => {'price': 0.0},
    );

    setState(() {
      selectedServicePrice = double.tryParse(selectedServiceData['price'].toString()) ?? 0.0;
    });
  }

  // Format date for better display
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Helper to cancel an appointment
  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('appointment_id', appointmentId);

      // Refresh the appointments list
      _fetchData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling appointment: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = Colors.pinkAccent.shade100;

    return Scaffold(
      appBar:AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'GlamAI Salon',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        iconTheme: IconThemeData(color: primaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await _supabase.auth.signOut();
              // Navigate to login screen after sign out
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        )
            : Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Upcoming Appointments Section
                if (upcomingAppointments.isEmpty) ...[
                  Text(
                    'Your Upcoming Appointments',
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No upcoming appointments',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Book a new appointment below',
                            style: GoogleFonts.lato(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                ] else ...[
                  Text(
                    'Your Upcoming Appointments',
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: upcomingAppointments.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          final appointment = upcomingAppointments[index];
                          final serviceData = appointment['services'];
                          final stylistData = appointment['stylists'];

                          return Container(
                            color: Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              title: Text(
                                serviceData['service_name'],
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${stylistData['first_name']} ${stylistData['last_name']}',
                                        style: GoogleFonts.lato(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(appointment['appointment_date']),
                                        style: GoogleFonts.lato(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        appointment['start_time'],
                                        style: GoogleFonts.lato(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${serviceData['price']}',
                                    style: GoogleFonts.lato(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _cancelAppointment(appointment['appointment_id']),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.lato(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  const SizedBox(height: 16),
                  Text(
                    'Book a New Appointment',
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Booking Form with improved styling
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Stylist',
                            labelStyle: GoogleFonts.lato(color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon: Icon(Icons.person, color: Colors.grey.shade600),
                          ),
                          items: stylists.map<DropdownMenuItem<String>>((stylist) {
                            return DropdownMenuItem<String>(
                              value: stylist['stylist_id'],
                              child: Text(
                                '${stylist['first_name']} ${stylist['last_name']}',
                                style: GoogleFonts.lato(),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedStylist = value),
                          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                          dropdownColor: Colors.white,
                        ),

                        const SizedBox(height: 20),

                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Service',
                            labelStyle: GoogleFonts.lato(color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon: Icon(Icons.spa, color: Colors.grey.shade600),
                          ),
                          items: services.map<DropdownMenuItem<String>>((service) {
                            return DropdownMenuItem<String>(
                              value: service['service_id'],
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    service['service_name'],
                                    style: GoogleFonts.lato(),
                                  ),
                                  Text(
                                    '\$${service['price']}',
                                    style: GoogleFonts.lato(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedService = value);
                            if (value != null) {
                              _updateServicePrice(value);
                            }
                          },
                          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                          dropdownColor: Colors.white,
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            labelText: 'Select Date',
                            labelStyle: GoogleFonts.lato(color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon: Icon(Icons.calendar_today, color: Colors.grey.shade600),
                          ),
                          style: GoogleFonts.lato(),
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: primaryColor,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _dateController.text = pickedDate.toIso8601String().split('T')[0];
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Select Time:',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children: timeSlots.map((time) {
                              final isSelected = selectedTime == time;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedTime = time;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.grey.shade300,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Text(
                                    time,
                                    style: GoogleFonts.lato(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Book Appointment',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),


                if (selectedServicePrice != null && selectedService != null)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Details',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Selected Stylist
                          if (selectedStylist != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Stylist: ${stylists.firstWhere((s) => s['stylist_id'] == selectedStylist)['first_name']} ${stylists.firstWhere((s) => s['stylist_id'] == selectedStylist)['last_name']}',
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Selected Service
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.spa,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Service: ${services.firstWhere((s) => s['service_id'] == selectedService)['service_name']}',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Price
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Price: \$${selectedServicePrice!.toStringAsFixed(2)}',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: Text(
                              'Try on Virtual Look',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TryOnScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }
}