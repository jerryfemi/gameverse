import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// Public web config (same project as the game). Not a secret: access is
// controlled by Firestore rules (isAdmin()).
const app = initializeApp({
  apiKey: 'AIzaSyCJwUj2_U8zCqMPiIpzikiN1vWa1iNipNc',
  appId: '1:30987418661:web:f97ba9acaba086944293cc',
  messagingSenderId: '30987418661',
  projectId: 'game-arcade-bball',
  authDomain: 'game-arcade-bball.firebaseapp.com',
  storageBucket: 'game-arcade-bball.firebasestorage.app',
});

export const auth = getAuth(app);
export const db = getFirestore(app);
export const googleProvider = new GoogleAuthProvider();

// Must match isAdmin() in firestore.rules. The rules are the real lock;
// this only decides what the page shows.
export const ADMIN_EMAIL = 'jeremiaholuwafemi16@gmail.com';
