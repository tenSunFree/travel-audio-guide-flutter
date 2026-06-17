import 'package:flutter/material.dart';
import 'nearby_models.dart';

/// Displays the correct fallback UI for every [NearbyPermissionState].
/// Returns [SizedBox.shrink] when state is [NearbyPermissionState.granted].
class LocationFallbackCard extends StatelessWidget {
  const LocationFallbackCard({
    super.key,
    required this.permissionState,
    required this.isLoading,
    required this.onRequestLocation,
    required this.onOpenSettings,
    required this.onOpenLocationService,
    required this.onBrowseAll,
  });

  final NearbyPermissionState permissionState;
  final bool isLoading;

  /// Retry / request permission
  final VoidCallback onRequestLocation;

  /// Opens the system App Settings page (for deniedForever)
  final VoidCallback onOpenSettings;

  /// Opens the system Location Service settings (for serviceDisabled)
  final VoidCallback onOpenLocationService;

  /// Navigate away to the full list
  final VoidCallback onBrowseAll;

  @override
  Widget build(BuildContext context) {
    if (permissionState == NearbyPermissionState.granted) {
      return const SizedBox.shrink();
    }
    final data = _dataFor(permissionState);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(data.message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: isLoading ? null : data.primaryAction,
                  child: isLoading && data.showLoadingOnPrimary
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(data.primaryLabel),
                ),
                if (data.secondaryLabel != null)
                  TextButton(
                    onPressed: onBrowseAll,
                    child: Text(data.secondaryLabel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _FallbackData _dataFor(NearbyPermissionState state) {
    return switch (state) {
      NearbyPermissionState.initial => _FallbackData(
        title: '開啟附近推薦',
        message: '允許定位後，我們可以依照你目前的位置推薦附近景點、語音導覽與活動。',
        primaryLabel: isLoading ? '定位中...' : '開啟定位',
        primaryAction: onRequestLocation,
        showLoadingOnPrimary: true,
        secondaryLabel: null,
      ),
      NearbyPermissionState.denied => _FallbackData(
        title: '尚未開啟定位',
        message: '你仍然可以瀏覽全部景點，或手動選擇行政區。',
        primaryLabel: '重新開啟定位',
        primaryAction: onRequestLocation,
        showLoadingOnPrimary: true,
        secondaryLabel: '瀏覽全部景點',
      ),
      NearbyPermissionState.deniedForever => _FallbackData(
        title: '定位權限已關閉',
        message: '請到系統設定開啟定位權限，才能使用附近推薦。',
        primaryLabel: '前往設定',
        primaryAction: onOpenSettings,
        showLoadingOnPrimary: false,
        secondaryLabel: '瀏覽全部景點',
      ),
      NearbyPermissionState.serviceDisabled => _FallbackData(
        title: '定位服務未開啟',
        message: '請開啟手機定位服務後再試一次。',
        primaryLabel: '開啟定位服務',
        primaryAction: onOpenLocationService,
        showLoadingOnPrimary: false,
        secondaryLabel: '稍後再說',
      ),
      NearbyPermissionState.failure => _FallbackData(
        title: '無法取得位置',
        message: '定位失敗，你仍然可以瀏覽全部景點。',
        primaryLabel: '重新嘗試',
        primaryAction: onRequestLocation,
        showLoadingOnPrimary: true,
        secondaryLabel: '瀏覽全部景點',
      ),
      NearbyPermissionState.granted => _FallbackData(
        title: '',
        message: '',
        primaryLabel: '',
        primaryAction: () {},
        showLoadingOnPrimary: false,
        secondaryLabel: null,
      ),
    };
  }
}

class _FallbackData {
  const _FallbackData({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.primaryAction,
    required this.showLoadingOnPrimary,
    required this.secondaryLabel,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback primaryAction;
  final bool showLoadingOnPrimary;
  final String? secondaryLabel;
}
