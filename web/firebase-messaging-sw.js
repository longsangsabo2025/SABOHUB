importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Try to initialize firebase from a runtime config, but usually empty init works
// if the SDK manages the backend. However, it's safer to provide the config:
// We will tell the user they need to configure this file or we can serve it dynamically.
// Actually, empty init is supported when the config is passed from Flutter:
firebase.initializeApp({
  apiKey: "AIzaSyCPvd4EPxlyKWqD5DHCbyh4tCRi99yZ9lQ",
  authDomain: "sabohub-e780c.firebaseapp.com",
  projectId: "sabohub-e780c",
  storageBucket: "sabohub-e780c.firebasestorage.app",
  messagingSenderId: "605640266733",
  appId: "1:605640266733:web:db6c3ea6daa96e5d940de4"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});