{{flutter_js}}
{{flutter_build_config}}

// Register our push SW before loading Flutter, then start Flutter without its own SW.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js');
}

_flutter.loader.load();
