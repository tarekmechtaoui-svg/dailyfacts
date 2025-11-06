import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'supabase_service.dart';

class OneSignalService {
  static OneSignalService? _instance;

  OneSignalService._();

  static OneSignalService get instance {
    _instance ??= OneSignalService._();
    return _instance!;
  }

  Future<void> initialize(String appId) async {
    OneSignal.initialize(appId);

    await OneSignal.Notifications.requestPermission(true);

    OneSignal.User.pushSubscription.addObserver((state) {
      if (state.current.id != null) {
        _savePlayerId(state.current.id!);
      }
    });
  }

  Future<void> _savePlayerId(String playerId) async {
    final user = await SupabaseService.instance.getCurrentUser();
    if (user != null) {
      await SupabaseService.instance.saveOneSignalPlayerId(user.id, playerId);
    }
  }

  Future<String?> getPlayerId() async {
    return OneSignal.User.pushSubscription.id;
  }

  Future<void> setExternalUserId(String userId) async {
    await OneSignal.login(userId);
  }

  Future<void> removeExternalUserId() async {
    await OneSignal.logout();
  }
}
