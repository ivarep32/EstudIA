// src/pages/Avisos.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';

function Avisos() {
  const [avisos, setAvisos] = useState([]);
  const [mensaje, setMensaje] = useState('');

  useEffect(() => {
    axios.get('/avisos', { headers: { Authorization: 'Bearer TOKEN_AQUI' } })
      .then(response => setAvisos(response.data))
      .catch(error => console.error('Error al obtener avisos:', error));
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();
    axios.post('/avisos', { mensaje }, { headers: { Authorization: 'Bearer TOKEN_AQUI' } })
      .then(response => {
         setAvisos([response.data, ...avisos]);
         setMensaje('');
      })
      .catch(error => console.error('Error al crear aviso:', error));
  };

  return (
    <div>
      <h2>Avisos (Solo Delegados)</h2>
      <form onSubmit={handleSubmit}>
         <textarea
           placeholder="Escribe un aviso"
           value={mensaje}
           onChange={(e) => setMensaje(e.target.value)}
           required
         />
         <button type="submit">Publicar Aviso</button>
      </form>
      <ul>
         {avisos.map(aviso => (
           <li key={aviso.id}>
             <p>{aviso.mensaje}</p>
             <small>{new Date(aviso.fecha_publicacion).toLocaleString()}</small>
           </li>
         ))}
      </ul>
    </div>
  );
}

export default Avisos;