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
  final Widget Function(AsyncValue<T>?)? loading;
  final Widget Function(Object, StackTrace?, AsyncData<T>?)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: loading ??
          (data) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
      error: error ??
          (e, st, data) {
            return Center(
              child: Text(
                e.toString(),
                style: Theme.of(context)
                    .textTheme
                    .headline6!
                    .copyWith(color: Colors.red),
              ),
            );
          },
    );
  }
}
