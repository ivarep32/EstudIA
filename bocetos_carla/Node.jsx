/**
 * server.js
 * Backend para la aplicación de gestión académica.
 */

const express = require('express');
const bodyParser = require('body-parser');
const admin = require('firebase-admin');
const { Pool } = require('pg');
const AWS = require('aws-sdk');
require('dotenv').config(); // Para usar variables de entorno

// Inicializar Firebase Admin con el archivo de credenciales
const serviceAccount = require('./path/to/serviceAccountKey.json'); // Asegúrate de colocar la ruta correcta
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Configurar AWS S3
AWS.config.update({ region: process.env.AWS_REGION });
const s3 = new AWS.S3();

// Configurar la conexión a PostgreSQL
const pool = new Pool({
  connectionString: process.env.DATABASE_URL, // Ejemplo: postgres://usuario:contraseña@host:puerto/basedatos
});

const app = express();
app.use(bodyParser.json());

/**
 * Middleware para verificar el token de Firebase.
 * Se espera que el token se envíe en el header Authorization en el formato "Bearer <token>".
 */
async function verifyFirebaseToken(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
         return res.status(401).json({ error: 'No autorizado' });
    }
    const token = authHeader.split(' ')[1];
    try {
         const decodedToken = await admin.auth().verifyIdToken(token);
         req.user = decodedToken; // Aquí se guarda la información del usuario
         next();
    } catch (error) {
         console.error('Error al verificar el token:', error);
         return res.status(401).json({ error: 'Token inválido' });
    }
}

/**
 * Middleware para verificar que el usuario tenga el rol de delegado.
 * Se asume que el token de Firebase incluye un claim 'role' que indica el rol del usuario.
 */
function checkRoleDelegado(req, res, next) {
   if (req.user.role && req.user.role === 'delegado') {
       next();
   } else {
       return res.status(403).json({ error: 'No tienes permiso para realizar esta acción' });
   }
}

/* ===============================
   Rutas para la Gestión de Horarios
   =============================== */

// Obtener todos los horarios del usuario autenticado
app.get('/horarios', verifyFirebaseToken, async (req, res) => {
   try {
      const userId = req.user.uid; // UID de Firebase
      const result = await pool.query('SELECT * FROM horarios WHERE usuario_id = $1', [userId]);
      res.json(result.rows);
   } catch (error) {
      console.error('Error al obtener horarios:', error);
      res.status(500).json({ error: 'Error al obtener horarios' });
   }
});

// Crear un nuevo horario
app.post('/horarios', verifyFirebaseToken, async (req, res) => {
   try {
       const { asignatura, hora_inicio, hora_fin, dia_semana } = req.body;
       const userId = req.user.uid;
       const result = await pool.query(
         'INSERT INTO horarios (usuario_id, asignatura, hora_inicio, hora_fin, dia_semana) VALUES ($1, $2, $3, $4, $5) RETURNING *',
         [userId, asignatura, hora_inicio, hora_fin, dia_semana]
       );
       res.json(result.rows[0]);
   } catch (error) {
       console.error('Error al crear horario:', error);
       res.status(500).json({ error: 'Error al crear horario' });
   }
});

// Actualizar un horario existente
app.put('/horarios/:id', verifyFirebaseToken, async (req, res) => {
   try {
       const { id } = req.params;
       const { asignatura, hora_inicio, hora_fin, dia_semana } = req.body;
       const userId = req.user.uid;
       const result = await pool.query(
         'UPDATE horarios SET asignatura = $1, hora_inicio = $2, hora_fin = $3, dia_semana = $4 WHERE id = $5 AND usuario_id = $6 RETURNING *',
         [asignatura, hora_inicio, hora_fin, dia_semana, id, userId]
       );
       res.json(result.rows[0]);
   } catch (error) {
       console.error('Error al actualizar horario:', error);
       res.status(500).json({ error: 'Error al actualizar horario' });
   }
});

// Eliminar un horario
app.delete('/horarios/:id', verifyFirebaseToken, async (req, res) => {
   try {
       const { id } = req.params;
       const userId = req.user.uid;
       await pool.query('DELETE FROM horarios WHERE id = $1 AND usuario_id = $2', [id, userId]);
       res.json({ message: 'Horario eliminado' });
   } catch (error) {
       console.error('Error al eliminar horario:', error);
       res.status(500).json({ error: 'Error al eliminar horario' });
   }
});

/* =============================================
   Rutas para la Gestión de Eventos Académicos
   (Entregas y Exámenes)
   ============================================= */

// Obtener todos los eventos académicos del usuario
app.get('/eventos', verifyFirebaseToken, async (req, res) => {
   try {
       const userId = req.user.uid;
       const result = await pool.query('SELECT * FROM eventos_academicos WHERE usuario_id = $1', [userId]);
       res.json(result.rows);
   } catch (error) {
       console.error('Error al obtener eventos académicos:', error);
       res.status(500).json({ error: 'Error al obtener eventos' });
   }
});

// Crear un nuevo evento académico
app.post('/eventos', verifyFirebaseToken, async (req, res) => {
   try {
       const { tipo, fecha, descripcion, recordatorio } = req.body;
       const userId = req.user.uid;
       const result = await pool.query(
         'INSERT INTO eventos_academicos (usuario_id, tipo, fecha, descripcion, recordatorio) VALUES ($1, $2, $3, $4, $5) RETURNING *',
         [userId, tipo, fecha, descripcion, recordatorio]
       );
       res.json(result.rows[0]);
   } catch (error) {
       console.error('Error al crear evento académico:', error);
       res.status(500).json({ error: 'Error al crear evento académico' });
   }
});

// Actualizar un evento académico
app.put('/eventos/:id', verifyFirebaseToken, async (req, res) => {
   try {
       const { id } = req.params;
       const { tipo, fecha, descripcion, recordatorio } = req.body;
       const userId = req.user.uid;
       const result = await pool.query(
         'UPDATE eventos_academicos SET tipo = $1, fecha = $2, descripcion = $3, recordatorio = $4 WHERE id = $5 AND usuario_id = $6 RETURNING *',
         [tipo, fecha, descripcion, recordatorio, id, userId]
       );
       res.json(result.rows[0]);
   } catch (error) {
       console.error('Error al actualizar evento académico:', error);
       res.status(500).json({ error: 'Error al actualizar evento académico' });
   }
});

// Eliminar un evento académico
app.delete('/eventos/:id', verifyFirebaseToken, async (req, res) => {
   try {
       const { id } = req.params;
       const userId = req.user.uid;
       await pool.query('DELETE FROM eventos_academicos WHERE id = $1 AND usuario_id = $2', [id, userId]);
       res.json({ message: 'Evento académico eliminado' });
   } catch (error) {
       console.error('Error al eliminar evento académico:', error);
       res.status(500).json({ error: 'Error al eliminar evento académico' });
   }
});

/* ==========================================
   Rutas para el Cronómetro de Trabajo
   ========================================== */

// Iniciar el cronómetro para una tarea
app.post('/cronometro/start', verifyFirebaseToken, async (req, res) => {
  try {
      // Se espera recibir un identificador o nombre de la tarea
      const { tarea_id } = req.body;
      const userId = req.user.uid;
      const result = await pool.query(
         'INSERT INTO tiempos_trabajo (usuario_id, tarea_id, hora_inicio) VALUES ($1, $2, NOW()) RETURNING *',
         [userId, tarea_id]
      );
      res.json(result.rows[0]);
  } catch (error) {
      console.error('Error al iniciar cronómetro:', error);
      res.status(500).json({ error: 'Error al iniciar cronómetro' });
  }
});

// Detener el cronómetro y calcular la duración de la tarea
app.post('/cronometro/stop', verifyFirebaseToken, async (req, res) => {
   try {
       // Se espera recibir el registro_id devuelto al iniciar el cronómetro
       const { registro_id } = req.body;
       const userId = req.user.uid;
       const result = await pool.query(
         'UPDATE tiempos_trabajo SET hora_fin = NOW(), duracion = EXTRACT(EPOCH FROM (NOW() - hora_inicio)) WHERE id = $1 AND usuario_id = $2 RETURNING *',
         [registro_id, userId]
       );
       res.json(result.rows[0]);
   } catch (error) {
       console.error('Error al detener cronómetro:', error);
       res.status(500).json({ error: 'Error al detener cronómetro' });
   }
});

// Obtener resumen del tiempo trabajado (por ejemplo, total por tarea)
app.get('/cronometro/resumen', verifyFirebaseToken, async (req, res) => {
   try {
       const userId = req.user.uid;
       const result = await pool.query(
         `SELECT tarea_id, SUM(duracion) as total_segundos
          FROM tiempos_trabajo
          WHERE usuario_id = $1 AND hora_fin IS NOT NULL
          GROUP BY tarea_id`,
         [userId]
       );
       res.json(result.rows);
   } catch (error) {
       console.error('Error al obtener resumen del cronómetro:', error);
       res.status(500).json({ error: 'Error al obtener resumen del cronómetro' });
   }
});

/* ==============================================
   Rutas para Avisos (Funcionalidad del Delegado)
   ============================================== */

// Crear un aviso (solo para usuarios con rol 'delegado')
app.post('/avisos', verifyFirebaseToken, checkRoleDelegado, async (req, res) => {
    try {
        const { mensaje } = req.body;
        const delegado_id = req.user.uid;
        const result = await pool.query(
          'INSERT INTO avisos (delegado_id, mensaje, fecha_publicacion) VALUES ($1, $2, NOW()) RETURNING *',
          [delegado_id, mensaje]
        );
        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error al crear aviso:', error);
        res.status(500).json({ error: 'Error al crear aviso' });
    }
});

// Obtener todos los avisos (accesible para cualquier usuario autenticado)
app.get('/avisos', verifyFirebaseToken, async (req, res) => {
    try {
         const result = await pool.query('SELECT * FROM avisos ORDER BY fecha_publicacion DESC');
         res.json(result.rows);
    } catch (error) {
         console.error('Error al obtener avisos:', error);
         res.status(500).json({ error: 'Error al obtener avisos' });
    }
});

/* ===============================================
   Rutas para el Repositorio Académico (Archivos)
   =============================================== */

// Subir archivo: generar URL pre-firmada para S3 y guardar metadatos en la BD
app.post('/archivos', verifyFirebaseToken, async (req, res) => {
   try {
       const { nombre_archivo, asignatura, grado, contentType } = req.body;
       const userId = req.user.uid;
       // Crear una clave única para el archivo
       const fileKey = ${userId}/${Date.now()}_${nombre_archivo};
       const params = {
           Bucket: process.env.AWS_S3_BUCKET, // Debes definirlo en tus variables de entorno
           Key: fileKey,
           Expires: 60, // URL válida por 60 segundos
           ContentType: contentType
       };
       // Generar URL pre-firmada para la operación de PUT
       const url = s3.getSignedUrl('putObject', params);
       // Guardar metadatos del archivo en la BD
       const result = await pool.query(
         'INSERT INTO archivos_academicos (usuario_id, nombre_archivo, url, asignatura, grado) VALUES ($1, $2, $3, $4, $5) RETURNING *',
         [userId, nombre_archivo, fileKey, asignatura, grado]
       );
       res.json({ presignedUrl: url, archivo: result.rows[0] });
   } catch (error) {
       console.error('Error al generar URL pre-firmada:', error);
       res.status(500).json({ error: 'Error al generar URL pre-firmada' });
   }
});

// Obtener archivos de una asignatura específica
app.get('/archivos/:asignatura', verifyFirebaseToken, async (req, res) => {
   try {
       const { asignatura } = req.params;
       const result = await pool.query(
         'SELECT * FROM archivos_academicos WHERE asignatura = $1 ORDER BY id DESC',
         [asignatura]
       );
       res.json(result.rows);
   } catch (error) {
       console.error('Error al obtener archivos:', error);
       res.status(500).json({ error: 'Error al obtener archivos' });
   }
});

/* =====================
   Inicio del Servidor
   ===================== */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
   console.log("Servidor escuchando en el puerto ${PORT}");
});