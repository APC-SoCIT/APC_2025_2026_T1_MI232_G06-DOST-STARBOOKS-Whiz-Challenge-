import 'package:flutter/material.dart';

class WhizChallenge extends StatelessWidget {
  const WhizChallenge({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Whiz Challenge")),
      body: const Center(child: Text("This is the Whiz Challenge Page")),
    );
  }
}
