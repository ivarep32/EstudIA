// src/components/Navbar.js
import React from 'react';
import { Link } from 'react-router-dom';

function Navbar() {
  return (
     <nav>
       <ul>
         <li><Link to="/horarios">Horarios</Link></li>
         <li><Link to="/eventos">Eventos</Link></li>
         <li><Link to="/cronometro">Cronómetro</Link></li>
         <li><Link to="/avisos">Avisos</Link></li>
         <li><Link to="/repositorio">Repositorio</Link></li>
       </ul>
     </nav>
  );
}

export default Navbar;