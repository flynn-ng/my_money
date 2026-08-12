{{flutter_js}}
{{flutter_build_config}}

// Register our own service worker (offline shell + web push) before loading
// Flutter, so Flutter does not register one of its own.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker.register('/sw.js');
  });
}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();

    // Flutter is painting now — dismiss the boot splash from index.html.
    const loading = document.getElementById('loading');
    if (loading) {
      loading.classList.add('fade-out');
      setTimeout(function () { loading.remove(); }, 250);
    }
  },
});
