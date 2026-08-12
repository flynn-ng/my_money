// Native builds have no browser online/offline events — connectivity is
// inferred from failed requests instead (see ConnectivityNotifier).
bool connectivityIsOnline() => true;

void connectivityListen(void Function(bool online) onChange) {}
