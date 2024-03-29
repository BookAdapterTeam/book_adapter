import 'package:flutter/material.dart';

import '../../../../constants/constants.dart';

class OverflowLibraryAppBarPopupMenuButton extends StatelessWidget {
  const OverflowLibraryAppBarPopupMenuButton({
    Key? key,
    required this.onRemoveDownloads,
    required this.onDeletePermanently,
    required this.onDownload,
  }) : super(key: key);

  final VoidCallback onRemoveDownloads;
  final VoidCallback onDeletePermanently;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) => PopupMenuButton(
        offset: const Offset(0, kToolbarHeight),
        icon: const Icon(Icons.more_vert),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(kCornerRadius),
          ),
        ),
        itemBuilder: (context) => <PopupMenuEntry>[
          PopupMenuItem(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.download),
                SizedBox(
                  width: 8,
                ),
                Text('Download Books'),
              ],
            ),
            onTap: () async {
              onDownload.call();
            },
          ),
          PopupMenuItem(
            onTap: onRemoveDownloads,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.file_download_off),
                SizedBox(
                  width: 8,
                ),
                Text('Remove Downloads'),
              ],
            ),
          ),
          PopupMenuItem(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.delete_forever,
                  color: Colors.redAccent,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  'Delete Permanently',
                ),
              ],
            ),
            onTap: () async {
              // Weird work around
              // See here for details: https://stackoverflow.com/questions/69568862/flutter-showdialog-is-not-shown-on-popupmenuitem-tap
              final shouldDelete = await Future<bool?>.delayed(
                Duration.zero,
                () => showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Permanently'),
                    content: const Text('Are you sure you want to delete all selected books '
                        'and series? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('DELETE'),
                      ),
                    ],
                  ),
                ),
              );
              if (shouldDelete == null || !shouldDelete) return;
              onDeletePermanently.call();
            },
          ),
        ],
      );
}
