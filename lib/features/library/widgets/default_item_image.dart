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
    final double height = width * 3;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _CustomBackground(
            seed: title.hashCode,
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: AutoSizeText(
                    title,
                    maxLines: 4,
                    textAlign: TextAlign.center,
                    minFontSize: 4,
                    softWrap: true,
                  ),
                ),
                SizedBox(height: height / 10),
                Expanded(
                  flex: 2,
                  child: Opacity(
                    opacity: 0.8,
                    child: AutoSizeText(
                      subtitle ?? 'Unknown Author',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      minFontSize: 4,
                      softWrap: true,
                    ),
                  ),
                ),
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
      child: AutoSizeText(
        subtitle,
        maxLines: 3,
      ),
    );
  }
}
