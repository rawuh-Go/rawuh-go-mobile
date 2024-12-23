import 'package:flutter/foundation.dart';

class NotificationProvider with ChangeNotifier {
  bool _hasUnreadNotifications = false;

  bool get hasUnreadNotifications => _hasUnreadNotifications;

  void setUnreadNotifications(bool value) {
    _hasUnreadNotifications = value;
    notifyListeners();
  }
}
