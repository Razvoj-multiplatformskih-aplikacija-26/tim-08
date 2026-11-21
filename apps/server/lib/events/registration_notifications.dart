import 'dart:io';

import 'package:domain/domain.dart';

abstract interface class RegistrationNotifications {
  Future<void> confirm(Prijava registration);
}

class DevelopmentRegistrationNotifications
    implements RegistrationNotifications {
  const DevelopmentRegistrationNotifications();

  @override
  Future<void> confirm(Prijava registration) async {
    stdout.writeln(
      'Demo notification: registration ${registration.id.value} confirmed '
      'for event ${registration.dogadjajId.value}.',
    );
  }
}
