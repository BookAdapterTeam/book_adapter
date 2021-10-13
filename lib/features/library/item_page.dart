import 'package:flutter/material.dart';

// TODO: For now this only contains options for image. It can be modified to handle multiple options like pdf, epub etc
class ItemPage extends StatelessWidget {
  final List<String> urlImages;

  const ItemPage({
    Key? key,
    required this.urlImages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Selected Items'),
          centerTitle: true,
        ),
        body: ListView(
          children: urlImages
              .map((urlImage) => Image.network(
                    urlImage,
                    fit: BoxFit.cover,
                    height: 300,
                  ))
              .toList(),
        ),
      );
}
