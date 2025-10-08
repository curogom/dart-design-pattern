import 'package:flutter/material.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.weekLabel});

  final String weekLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$weekLabel 데모'),
      ),
      body: Center(
        child: Text(
          '$weekLabel Flutter 데모는 준비 중입니다.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
