# **EstudIA**  

EstudIA es una aplicación diseñada para ayudar a los estudiantes a gestionar sus horarios y calendarios de manera efectiva. Combina un frontend desarrollado en **Flutter** con un backend en **Flask y SQLite**, proporcionando una experiencia fluida y fácil de usar.  

## 🚀 Tecnologías utilizadas  
- **Frontend:** Flutter (Dart)  
- **Backend:** Flask (Python) con SQLite  
- **API:** Documentación disponible en `/apidocs`  

## 📌 Frontend y Backend: Definiciones  
- **Frontend:** La interfaz gráfica con la que interactúa el usuario. Se ha desarrollado en **Flutter**.  
- **Backend:** La lógica y gestión de datos detrás de la aplicación, que procesa solicitudes y se comunica con la base de datos. Se ha desarrollado en **Flask (Python) con SQLite**.  

## 📂 Estructura del repositorio  
La carpeta "frontend_funcional" contiene los archivos necesarios para el frontend. Cada archivo .dart contiene una de las pantallas principales de la aplicación, tanto en estructura como en lógica. El código ApiServices.dart es un singleton que se utiliza desde el resto de archivos para comunicarse con el backend a través de la API de este.

La carpeta "backend_Iria" contiene todos los codigos y archivos necesarios para el correcto funcionamiento de la aplicación: models.py define el esquema de la base de datos, __init__.py inicia la aplicación, y en /routes/ tenemos diferentes archivos con funciones que establecen las rutas de la API y realizan las queries a la base de datos.

## 🔧 Instalación y Ejecución  
El programa debe ejecutarse desde run.py (backend_Iria/run.py), es posible que ejecutar otros archivos por separado dé errores, pero esto se debe a direcciones de importación y no afectan al programa final.

En la página principal no sale nada, pero si en la url se añade '/apidocs' se puede ver la documentación.


El frontend hay que compilarlo con android sdk, e instalar el .apk resultante en un teléfono móbil con sistema android.
