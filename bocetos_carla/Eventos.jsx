// src/pages/Eventos.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';

function Eventos() {
  const [eventos, setEventos] = useState([]);
  const [nuevoEvento, setNuevoEvento] = useState({
    tipo: 'entrega', // o 'examen'
    fecha: '',
    descripcion: '',
    recordatorio: false
  });

  useEffect(() => {
    axios.get('/eventos', { headers: { Authorization: 'Bearer TOKEN_AQUI' } })
      .then(response => setEventos(response.data))
      .catch(error => console.error('Error al obtener eventos:', error));
  }, []);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setNuevoEvento({ ...nuevoEvento, [name]: type === 'checkbox' ? checked : value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    axios.post('/eventos', nuevoEvento, { headers: { Authorization: 'Bearer TOKEN_AQUI' } })
      .then(response => {
         setEventos([...eventos, response.data]);
         setNuevoEvento({ tipo: 'entrega', fecha: '', descripcion: '', recordatorio: false });
      })
      .catch(error => console.error('Error al crear evento:', error));
  };

  return (
    <div>
      <h2>Eventos Académicos</h2>
      <ul>
         {eventos.map(evento => (
           <li key={evento.id}>
             {evento.tipo} - {new Date(evento.fecha).toLocaleString()} - {evento.descripcion}
           </li>
         ))}
      </ul>
      <form onSubmit={handleSubmit}>
         <label>
           Tipo:
           <select name="tipo" value={nuevoEvento.tipo} onChange={handleChange}>
             <option value="entrega">Entrega</option>
             <option value="examen">Examen</option>
           </select>
         </label>
         <label>
           Fecha:
           <input
             type="datetime-local"
             name="fecha"
             value={nuevoEvento.fecha}
             onChange={handleChange}
             required
           />
         </label>
         <label>
           Descripción:
           <input
             type="text"
             name="descripcion"
             value={nuevoEvento.descripcion}
             onChange={handleChange}
             required
           />
         </label>
         <label>
           Recordatorio:
           <input
             type="checkbox"
             name="recordatorio"
             checked={nuevoEvento.recordatorio}
             onChange={handleChange}
           />
         </label>
         <button type="submit">Agregar Evento</button>
      </form>
    </div>
  );
}

export default Eventos;