# **EstudIA**  

[Versión en Español](README.md)

EstudIA is an app designed to help students manage their time and calendars effectively.

It integrates a frontend developed in **Flutter** with a backend in **Flask** and **SQLite**, ensuring a smooth experience and ease of use.  
It was built by three second-year students with no previous experience during a 3-day hackathon.

<p align="center">
  <img src="https://github.com/user-attachments/assets/50004632-7687-48be-8051-1db4f910b9eb" width="250" />
  <img src="https://github.com/user-attachments/assets/92b41219-2351-40f2-8727-a0060f11f43e" width="250" />
  <img alt="image" src="https://github.com/user-attachments/assets/e13d644e-6cef-42f6-bcf7-b3d0228dfd72" width="500" valign="top" />
</p>

_Frontend and backend documentation screenshots._

## 🚀 Technologies  
- **Frontend:** Flutter (Dart)  
- **Backend:** Flask (Python) + SQLite  
- **API:** Documentation available at `http://localhost:5000/apidocs` when the backend is running.

## 📂 Repository structure
The directory `frontend_funcional` contains the files needed to compile the frontend. Each .dart file corresponds with one of the app's main screens. The `ApiServices.dart` is a singleton used in the rest of the files to communicate with the backend using its API. 

The directory `backend_Iria` contains the latest functional backend. `models.py` defines the database schema; `run.py` starts the application; and the files in `/routes` establish the different API routes and query the database.

## 🔧 Running
The backend needs Python 3.12 and has the requirements listed in `backend_Iria/requirements.txt`.
It must be run from `backend_Iria/run.py`, and it's hosted at `localhost:5000`.

The root website is blank, but the documentation can be checked at `/apidocs`.


The frontend must be compiled with android sdk, and the resulting .apk file must then be installed in an android device.
