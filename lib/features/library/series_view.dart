import 'dart:ui';

import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:book_adapter/features/library/widgets/item_list_tile_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';

class SeriesView extends ConsumerWidget {
  const SeriesView({ Key? key }) : super(key: key);

  static const routeName = '/series';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, dynamic> bookMap = ModalRoute.of(context)!.settings.arguments! as Map<String, dynamic>;
    final series = Series.fromMapFirebase(bookMap);
    final data = ref.watch(libraryViewController);

    final books = data.books?.where((book) {
      return series.id == book.seriesId;
    }).toList();
    books?.sort((a, b) => a.title.compareTo(b.title));

    final imageUrl = series.imageUrl;

    // ignore: prefer_const_constructors
    return Scaffold(
      // appBar: AppBar(title: const Text('Series'),),
      // body: const Center(child: Text('Books here'),),
      // ignore: prefer_const_constructors
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            flexibleSpace: imageUrl != null ? FlexibleSpaceBar(
              title: Text(series.title),
              stretchModes: const <StretchMode>[
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
                StretchMode.fadeTitle,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                      child: CachedNetworkImage(
                        fit: BoxFit.fitWidth,
                        imageUrl: imageUrl,
                        width: 40,
                      ),  // Widget that is blurred
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0.0, 0.5),
                        end: Alignment.center,
                        colors: <Color>[
                          Color(0x60000000),
                          Color(0x00000000),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ) : null,
          ),
          SliverImplicitlyAnimatedList<Book>(
            items: books ?? [],
            itemBuilder: (context, animation, item, index) => itemBuilder(context, animation, item, index, books),
            areItemsTheSame: (oldItem, newItem) { 
              return oldItem.id == newItem.id;
            },
            
          ),
        ],
      ),
    );
  }

  Widget itemBuilder(BuildContext context, Animation<double> animation, Book item, int index, List<Book>? books) {
    return ItemListTileWidget(
      item: item,
    );
  }
}