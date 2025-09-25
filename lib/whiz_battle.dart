import 'package:flutter/material.dart';

class WhizBattle extends StatelessWidget {
  const WhizBattle({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Whiz Battle")),
      body: const Center(child: Text("This is the Whiz Battle Page")),
    );
  }
}
