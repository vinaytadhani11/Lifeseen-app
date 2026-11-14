import 'package:get/get.dart';
import 'package:tableflow_plus/screens/friends_screen_time/premium_screen.dart';
import 'package:tableflow_plus/screens/friends_screen_time/register_screen.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';

/// Premium first, then registration. The original tap is not repeated.
Future<bool> passFriendsGate() async {
  final flow = FriendsFlowController.instance;
  if (!flow.hasActiveSubscription) {
    await Get.to<void>(() => const PremiumScreen());
    return false;
  }
  if (flow.documentId.isEmpty) {
    await Get.to<void>(() => const RegisterScreen());
    return false;
  }
  return true;
}
