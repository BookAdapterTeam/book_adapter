import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class DefaultItemImage extends StatelessWidget {
  const DefaultItemImage({
    Key? key,
    this.width = 40,
    this.title = '',
    this.subtitle,
  }) : super(key: key);
  final double width;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _CustomBackground(
            seed: title.hashCode,
          ),
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CustomImageTitle(
                  title: title,
                ),
                if (subtitle != null) ...[
                  _CustomImageSubtitle(
                    subtitle: subtitle!,
                  ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _CustomBackground extends StatelessWidget {
  const _CustomBackground({Key? key, this.seed}) : super(key: key);
  final int? seed;

  Color generateRandomColor() {
    // Define all colors you want here
    final predefinedColors = [
      Colors.red[900]!,
      Colors.green[900]!,
      Colors.blue[900]!,
      Colors.black,
      Colors.purple,
    ];
    final Random random = Random(seed);
    return predefinedColors[random.nextInt(predefinedColors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: generateRandomColor(),
    );
  }
}

class _CustomImageTitle extends StatelessWidget {
  const _CustomImageTitle({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      title,
      maxLines: 3,
    );
  }
}

class _CustomImageSubtitle extends StatelessWidget {
  const _CustomImageSubtitle({Key? key, required this.subtitle})
      : super(key: key);

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.8,
      child: FittedBox(
        child: AutoSizeText(
          subtitle,
          maxLines: 3,
        ),
      ),
    );
  }
}
