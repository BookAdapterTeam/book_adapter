import 'package:flutter/material.dart';

class SeriesView extends StatelessWidget {
  const SeriesView({ Key? key }) : super(key: key);

  static const routeName = '/series';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Series'),),
      body: const Center(child: Text('Books here'),),
    );
  }
}