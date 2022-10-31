import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  final String photoUrl;
  final VoidCallback onPressed;

  const ProfileWidget({
    Key? key,
    required this.photoUrl,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Center(
      child: Stack(
        children: [
          _ProfileImage(imageUrl: photoUrl, onPressed: onPressed),

          // For editing the profile image and username
          Positioned(
            bottom: 0,
            right: 4,
            child: _EditIcon(
              color: color,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({
    Key? key,
    required this.imageUrl,
    required this.onPressed,
  }) : super(key: key);

  final String imageUrl;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ClipOval(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),

          // Ink.image(
          //   image: image,
          //   fit: BoxFit.cover,
          //   width: 200,
          //   height: 200,
          //   child: InkWell(onTap: onPressed),
          // ),
        ),
      );
}

class _EditIcon extends StatelessWidget {
  const _EditIcon({
    Key? key,
    required this.color,
    required this.onPressed,
  }) : super(key: key);
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onPressed,
        child: _Circle(
          color: Colors.white,
          all: 3,
          child: _Circle(
            color: color,
            all: 8,
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      );
}

class _Circle extends StatelessWidget {
  const _Circle({
    Key? key,
    required this.child,
    required this.all,
    required this.color,
  }) : super(key: key);
  final Widget child;
  final double all;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipOval(
        child: Container(
          padding: EdgeInsets.all(all),
          color: color,
          child: child,
        ),
      );
}
