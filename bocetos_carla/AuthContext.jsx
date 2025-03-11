// src/contexts/AuthContext.js
import React, { createContext, useContext, useEffect, useState } from 'react';
import firebase from 'firebase/compat/app';
import 'firebase/compat/auth';

// Configuración de Firebase (reemplaza con tus datos)
const firebaseConfig = {
  apiKey: "TU_API_KEY",
  authDomain: "TU_AUTH_DOMAIN",
  projectId: "TU_PROJECT_ID",
  // ...otros campos necesarios
};

if (!firebase.apps.length) {
  firebase.initializeApp(firebaseConfig);
}

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Observa los cambios en el estado de autenticación
    const unsubscribe = firebase.auth().onAuthStateChanged(async (user) => {
      if (user) {
        // Obtenemos el token JWT
        const token = await user.getIdToken();
        localStorage.setItem('token', token);
        setUser(user);
      } else {
        localStorage.removeItem('token');
        setUser(null);
      }
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  const login = async (email, password) => {
    await firebase.auth().signInWithEmailAndPassword(email, password);
  };

  const logout = async () => {
    await firebase.auth().signOut();
  };

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {!loading && children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);