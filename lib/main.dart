import 'main_production.dart' as production;

/// Default entrypoint, equivalent to a production flavor.
/// This file is retained so that `flutter run` / `flutter analyze` will still have default behavior when `-t lib/main_xxx.dart` is not specified (directly clicking Run in the IDE will not cause problems).
///
/// When running flavors via CI/CD or locally, please use:
/// flutter run --flavor staging    -t lib/main_staging.dart
/// flutter run --flavor production -t lib/main_production.dart
Future<void> main() async {
  await production.main();
}
