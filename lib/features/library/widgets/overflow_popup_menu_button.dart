import 'package:flutter/material.dart';

class OverflowPopupMenuButton extends StatelessWidget {
  const OverflowPopupMenuButton({
    Key? key,
    required this.onRemoveDownloads,
    required this.onDeletePermanently,
  }) : super(key: key);

  final VoidCallback onRemoveDownloads;
  final VoidCallback onDeletePermanently;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      offset: const Offset(0, kToolbarHeight),
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) {
        return <PopupMenuEntry>[
          PopupMenuItem(
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
            onTap: () async {
              // Weird work around
              // See here for details: https://stackoverflow.com/questions/69568862/flutter-showdialog-is-not-shown-on-popupmenuitem-tap
              final bool? shouldDelete = await Future<bool?>.delayed(
                const Duration(),
                () => showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Remove Downloads'),
                      content: const Text(
                          'Are you sure you remove the downloads of all selected books?'),
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
                          child: const Text('REMOVE'),
                        ),
                      ],
                    );
                  },
                ),
              );
              if (shouldDelete == null || !shouldDelete) return;
              onRemoveDownloads.call();
            },
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
              final bool? shouldDelete = await Future<bool?>.delayed(
                const Duration(),
                () => showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Permanently'),
                      content: const Text(
                          'Are you sure you want to delete all selected books and series? This cannot be undone.'),
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
                          child: const Text('REMOVE'),
                        ),
                      ],
                    );
                  },
                ),
              );
              if (shouldDelete == null || !shouldDelete) return;
              onDeletePermanently.call();
            },
          ),
        ];
      },
    );
  }
}
