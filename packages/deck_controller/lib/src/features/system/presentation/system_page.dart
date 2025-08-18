import 'package:commons/commons.dart';
import 'package:deck_controller/src/features/system/data/system_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemPage extends ConsumerWidget {
  final SystemPageViewModel vm;

  SystemPage({super.key, required String symbol})
    : vm = SystemPageViewModel(symbol);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (vm.fetchSystem(ref)) {
      AsyncData(:final value) => Text("System $value"),
      AsyncError(:final error) => Text("Error: $error"),
      _ => CircularProgressIndicator(),
    };
  }
}

class SystemPageViewModel {
  final String symbol;

  SystemPageViewModel(this.symbol);

  AsyncValue<System> fetchSystem(WidgetRef ref) =>
      ref.watch(fetchSystemProvider(symbol));
}
