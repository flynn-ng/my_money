function _urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
  const rawData = window.atob(base64);
  const output = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; i++) output[i] = rawData.charCodeAt(i);
  return output;
}

window.meownyPush = {
  isSupported: function () {
    return 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
  },

  getPermission: function () {
    return typeof Notification !== 'undefined' ? Notification.permission : 'denied';
  },

  subscribe: async function (vapidPublicKey) {
    try {
      const permission = await Notification.requestPermission();
      if (permission !== 'granted') return null;
      const reg = await navigator.serviceWorker.ready;
      const existing = await reg.pushManager.getSubscription();
      if (existing) return JSON.stringify(existing.toJSON());
      const sub = await reg.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: _urlBase64ToUint8Array(vapidPublicKey),
      });
      return JSON.stringify(sub.toJSON());
    } catch (e) {
      console.error('[meownyPush] subscribe failed:', e);
      return null;
    }
  },

  unsubscribe: async function () {
    try {
      const reg = await navigator.serviceWorker.ready;
      const sub = await reg.pushManager.getSubscription();
      if (sub) await sub.unsubscribe();
      return true;
    } catch (e) {
      return false;
    }
  },

  getSubscription: async function () {
    try {
      const reg = await navigator.serviceWorker.ready;
      const sub = await reg.pushManager.getSubscription();
      return sub ? JSON.stringify(sub.toJSON()) : null;
    } catch (e) {
      return null;
    }
  },
};
