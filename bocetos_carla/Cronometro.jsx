// src/pages/Cronometro.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';

function Cronometro() {
  const [running, setRunning] = useState(false);
  const [registroId, setRegistroId] = useState(null);
  const [time, setTime] = useState(0); // tiempo en segundos
  const [tareaId, setTareaId] = useState('');

  useEffect(() => {
    let interval = null;
    if (running) {
      interval = setInterval(() => {
         setTime(prevTime => prevTime + 1);
      }, 1000);
    } else if (!running && interval) {
       clearInterval(interval);
    }
    return () => clearInterval(interval);
  }, [running]);

  const iniciarCronometro = () => {
    // Llamada al backend para iniciar el cronómetro
    axios.post('/cronometro/start', { tarea_id: tareaId }, { headers: { Authorization: 'Bearer TOKEN_AQUI' } })
      .then(response => {
         setRegistroId(response.data.id);
         setRunning(true);
         setTime(0);
      })
      .catch(error => console.error('Error al iniciar cronómetro:', error));
  };

  const detenerCronometro = () => {
    axios.post('/cronometro/stop', { registro_id: registroId }, { headers: { Authorization: 'Bearer TOKEN_AQUI' } })
      .then(response => {
         setRunning(false);
         alert("Tiempo registrado: ${response.data.duracion} segundos");
         setRegistroId(null);
         setTime(0);
      })
      .catch(error => console.error('Error al detener cronómetro:', error));
  };

  return (
    <div>
       <h2>Cronómetro de Trabajo</h2>
       <input
         type="text"
         placeholder="ID de la tarea"
         value={tareaId}
         onChange={(e) => setTareaId(e.target.value)}
       />
       <div>
         <p>Tiempo: {time} segundos</p>
         {!running ? (
           <button onClick={iniciarCronometro}>Iniciar</button>
         ) : (
           <button onClick={detenerCronometro}>Detener</button>
         )}
       </div>
    </div>
  );
}

export default Cronometro;