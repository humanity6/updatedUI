import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment Amount Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: const [
                  Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$50.00',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card Details Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Card Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card Number
                    TextFormField(
                      controller: _cardNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                    ),
                    const SizedBox(height: 16),

                    // Expiry and CVV
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            decoration: const InputDecoration(
                              labelText: 'MM/YY',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cvvController,
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cardholder Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Cardholder Name',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pay Button
            ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      setState(() {
                        _isProcessing = true;
                      });

                      try {
                        // TODO: Implement Stripe/Payment Gateway Integration
                        await Future.delayed(const Duration(seconds: 2));

                        if (mounted) {
                          Navigator.of(context).pushReplacementNamed('/confirmation');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Payment failed: ${e.toString()}')),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isProcessing = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Pay Now',
                      style: TextStyle(fontSize: 18),
                    ),
            ),

            const SizedBox(height: 16),
            // Payment Methods Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Icon(Icons.credit_card, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Icon(Icons.account_balance, color: Colors.grey[600]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}