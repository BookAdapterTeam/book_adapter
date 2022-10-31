// Generic AsyncValueWidget to work with values of type T
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    Key? key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  }) : super(key: key);

  // input async value
  final AsyncValue<T> value;
  // output builder function
  final Widget Function(T) data;
  final Widget Function()? loading;
  final Widget Function(Object, StackTrace?)? error;

  @override
  Widget build(BuildContext context) => value.when(
        data: data,
        loading: loading ??
            () => const Center(
                  child: CircularProgressIndicator(),
                ),
        error: error ??
            (e, st) => Center(
                  child: Text(
                    e.toString(),
                    style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.red),
                  ),
                ),
      );
}
