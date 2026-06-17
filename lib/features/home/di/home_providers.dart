import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../data/repositories/home_repository.dart';
import '../presentation/controllers/nearby_home_controller.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return HomeRepository(
    attractionDao: db.attractionDao,
    activityDao: db.activityDao,
  );
});

final nearbyHomeControllerProvider =
    StateNotifierProvider<NearbyHomeController, NearbyHomeState>(
      (ref) => NearbyHomeController(ref),
    );
