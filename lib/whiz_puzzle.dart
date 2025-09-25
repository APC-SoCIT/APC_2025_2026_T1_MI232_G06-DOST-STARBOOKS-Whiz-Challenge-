import 'package:flutter/material.dart';

class WhizPuzzle extends StatelessWidget {
  const WhizPuzzle({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Whiz Puzzle")),
      body: const Center(child: Text("This is the Whiz Puzzle Page")),
    );
  }
}
