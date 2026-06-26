import 'bootstrap.dart';
import 'firebase_options.dart';

/// Staging flavor entrypoint.
/// `flutter build apk --flavor staging -t lib/main_staging.dart`
Future<void> main() async {
  await bootstrap(firebaseOptions: DefaultFirebaseOptions.currentPlatform);
}
