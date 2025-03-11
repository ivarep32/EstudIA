// src/App.js
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Horarios from './pages/Horarios';
import Eventos from './pages/Eventos';
import Cronometro from './pages/Cronometro';
import Avisos from './pages/Avisos';
import Repositorio from './pages/Repositorio';

function App() {
  return (
    <Router>
      <Navbar />
      <div className="container">
         <Routes>
           <Route path="/horarios" element={<Horarios />} />
           <Route path="/eventos" element={<Eventos />} />
           <Route path="/cronometro" element={<Cronometro />} />
           <Route path="/avisos" element={<Avisos />} />
           <Route path="/repositorio" element={<Repositorio />} />
           <Route path="/" element={<Horarios />} />
         </Routes>
      </div>
    </Router>
  );
}

export default App;