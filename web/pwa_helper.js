// Install-to-home-screen support for the Dart side (see lib/features/pwa/).
//
// Chromium fires `beforeinstallprompt` once the app is installable; the event
// has to be stashed because `prompt()` can only be called from it later on.
// iOS Safari never fires it — there the app shows manual instructions instead.
(function () {
  let deferredPrompt = null;

  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault();
    deferredPrompt = e;
  });

  window.addEventListener('appinstalled', function () {
    deferredPrompt = null;
  });

  window.meownyPwa = {
    canInstall: function () {
      return deferredPrompt !== null;
    },

    isStandalone: function () {
      return (
        window.matchMedia('(display-mode: standalone)').matches ||
        window.navigator.standalone === true
      );
    },

    isIos: function () {
      return (
        /iphone|ipad|ipod/i.test(window.navigator.userAgent) &&
        !window.MSStream
      );
    },

    // Resolves to 'accepted', 'dismissed' or 'unavailable'.
    promptInstall: async function () {
      if (!deferredPrompt) return 'unavailable';
      try {
        deferredPrompt.prompt();
        const choice = await deferredPrompt.userChoice;
        deferredPrompt = null;
        return choice.outcome === 'accepted' ? 'accepted' : 'dismissed';
      } catch (e) {
        console.error('[meownyPwa] install prompt failed:', e);
        deferredPrompt = null;
        return 'unavailable';
      }
    },
  };
})();
