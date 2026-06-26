import 'bootstrap.dart';
import 'firebase_options_production.dart';

/// Production flavor entrypoint.
/// `flutter build apk --flavor production -t lib/main_production.dart`
Future<void> main() async {
  await bootstrap(firebaseOptions: DefaultFirebaseOptions.currentPlatform);
}