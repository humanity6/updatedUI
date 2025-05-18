import 'package:flutter/material.dart';


class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  _TryOnScreenState createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  @override
  void initState() {
    super.initState();
    // intentionally left empty
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try On Hairstyles')),
      body: const Center(
        child: Text('This screen is now empty'),
      ),
    );
  }

  @override
  void dispose() {
    // intentionally left empty
    super.dispose();
  }
}