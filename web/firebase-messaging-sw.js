// Import and configure the Firebase SDK
// These scripts are made available when the app is served or deployed on Firebase Hosting
// or you can use the CDN as shown below
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCNjkV_P_hyAIcwcRpeYDAybPVNnOUqU1s",
  authDomain: "qwicktalk.firebaseapp.com",
  projectId: "qwicktalk",
  storageBucket: "qwicktalk.firebasestorage.app",
  messagingSenderId: "919082993592",
  appId: "1:919082993592:web:56bc536b8f8b5f0369b14d",
});

const messaging = firebase.messaging();

// Optional: Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
