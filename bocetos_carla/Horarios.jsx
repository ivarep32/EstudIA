// src/pages/Horarios.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Calendar from 'react-calendar';
import 'react-calendar/dist/Calendar.css';

function Horarios() {
  const [horarios, setHorarios] = useState([]);
  const [nuevoHorario, setNuevoHorario] = useState({
    asignatura: '',
    hora_inicio: '',
    hora_fin: '',
    dia_semana: ''
  });
  const [date, setDate] = useState(new Date());

  useEffect(() => {
    // Petición para obtener los horarios del usuario
    axios.get('/horarios', { headers: { Authorization: 'Bearer TOKEN_AQUI' } })
      .then(response => {
         setHorarios(response.data);
      })
      .catch(error => console.error('Error al obtener horarios:', error));
  }, []);

  const handleChange = (e) => {
    setNuevoHorario({ ...nuevoHorario, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    axios.post('/horarios', nuevoHorario, { headers: { Authorization: 'Bearer TOKEN_AQUI' } })
      .then(response => {
         setHorarios([...horarios, response.data]);
         setNuevoHorario({ asignatura: '', hora_inicio: '', hora_fin: '', dia_semana: '' });
      })
      .catch(error => console.error('Error al crear horario:', error));
  };

  return (
    <div>
      <h2>Horarios</h2>
      <Calendar onChange={setDate} value={date} />
      <ul>
         {horarios.map((h) => (
           <li key={h.id}>
             {h.asignatura} - {h.dia_semana} de {h.hora_inicio} a {h.hora_fin}
           </li>
         ))}
      </ul>
      <form onSubmit={handleSubmit}>
         <input
           type="text"
           name="asignatura"
           placeholder="Asignatura"
           value={nuevoHorario.asignatura}
           onChange={handleChange}
           required
         />
         <input
           type="time"
           name="hora_inicio"
           value={nuevoHorario.hora_inicio}
           onChange={handleChange}
           required
         />
         <input
           type="time"
           name="hora_fin"
           value={nuevoHorario.hora_fin}
           onChange={handleChange}
           required
         />
         <select name="dia_semana" value={nuevoHorario.dia_semana} onChange={handleChange} required>
            <option value="">Selecciona un día</option>
            <option value="Lunes">Lunes</option>
            <option value="Martes">Martes</option>
            <option value="Miércoles">Miércoles</option>
            <option value="Jueves">Jueves</option>
            <option value="Viernes">Viernes</option>
         </select>
         <button type="submit">Agregar Horario</button>
      </form>
    </div>
  );
}

export default Horarios;