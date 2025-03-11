// src/pages/Repositorio.js
import React, { useState } from 'react';
import axios from 'axios';
import { useDropzone } from 'react-dropzone';

function Repositorio() {
  const [files, setFiles] = useState([]);
  const [asignatura, setAsignatura] = useState('');
  const [grado, setGrado] = useState('');

  const onDrop = (acceptedFiles) => {
    if (acceptedFiles.length > 0) {
      const file = acceptedFiles[0];
      // Solicitar URL pre-firmada al backend
      axios.post('/archivos', {
         nombre_archivo: file.name,
         asignatura,
         grado,
         contentType: file.type
      }, { headers: { Authorization: 'Bearer TOKEN_AQUI' } })
      .then(response => {
         const { presignedUrl, archivo } = response.data;
         // Subir el archivo a S3 usando la URL pre-firmada
         axios.put(presignedUrl, file, {
           headers: { 'Content-Type': file.type }
         }).then(() => {
            alert('Archivo subido correctamente');
            setFiles([...files, archivo]);
         }).catch(error => {
            console.error('Error al subir el archivo a S3:', error);
         });
      })
      .catch(error => console.error('Error al obtener URL pre-firmada:', error));
    }
  };

  const { getRootProps, getInputProps } = useDropzone({ onDrop });

  return (
    <div>
       <h2>Repositorio Académico</h2>
       <div>
         <label>Asignatura: </label>
         <input
           type="text"
           value={asignatura}
           onChange={(e) => setAsignatura(e.target.value)}
           required
         />
       </div>
       <div>
         <label>Grado: </label>
         <input
           type="text"
           value={grado}
           onChange={(e) => setGrado(e.target.value)}
           required
         />
       </div>
       <div {...getRootProps()} style={{ border: '2px dashed #cccccc', padding: '20px', cursor: 'pointer' }}>
         <input {...getInputProps()} />
         <p>Arrastra y suelta el archivo aquí o haz clic para seleccionar</p>
       </div>
       <div>
         <h3>Archivos Subidos:</h3>
         <ul>
           {files.map(file => (
             <li key={file.id}>
               {file.nombre_archivo} - {file.asignatura} - {file.grado}
             </li>
           ))}
         </ul>
       </div>
    </div>
  );
}

export default Repositorio;