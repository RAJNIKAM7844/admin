import 'package:flutter/material.dart';

class TotalCollectionScreen extends StatelessWidget {
  const TotalCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Total Collection')),
      body: const Center(child: Text('Total Collection Details Here')),
    );
  }
}
