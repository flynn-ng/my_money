import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/locale_tracker.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('vi');

  void set(Locale locale) {
    setActiveLocale(locale.languageCode);
    state = locale;
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
