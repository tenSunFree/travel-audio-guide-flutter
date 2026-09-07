import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/features/home/data/repositories/home_repository.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/controllers/nearby_home_controller.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return HomeRepository(
    attractionDao: db.attractionDao,
    activityDao: db.activityDao,
  );
});

final nearbyHomeControllerProvider =
    StateNotifierProvider<NearbyHomeController, NearbyHomeState>(
      NearbyHomeController.new,
    );
