import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '_pwa_helper_stub.dart' if (dart.library.js_interop) '_pwa_helper_web.dart';

enum InstallPromptResult { accepted, dismissed, unavailable }

/// Add-to-home-screen state for the web build.
class PwaInstallService {
  const PwaInstallService();

  /// Already running as an installed app — nothing left to offer.
  bool get isInstalled => kIsWeb && pwaIsStandalone();

  /// Chromium has fired `beforeinstallprompt`, so a native prompt is available.
  bool get canPrompt => kIsWeb && pwaCanInstall();

  /// iOS Safari never offers a prompt; the user has to use the Share menu.
  bool get needsManualSteps =>
      kIsWeb && pwaIsIos() && !pwaIsStandalone() && !pwaCanInstall();

  /// Whether to show the install entry point at all.
  bool get isVisible => !isInstalled && (canPrompt || needsManualSteps);

  Future<InstallPromptResult> prompt() async {
    if (!kIsWeb) return InstallPromptResult.unavailable;
    return switch (await pwaPromptInstall()) {
      'accepted' => InstallPromptResult.accepted,
      'dismissed' => InstallPromptResult.dismissed,
      _ => InstallPromptResult.unavailable,
    };
  }
}

final pwaInstallServiceProvider =
    Provider<PwaInstallService>((ref) => const PwaInstallService());
