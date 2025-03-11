# iniciacion de la app
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from config import Config
"""Esto va en el archivo q configure la base de datos"""
#from .models import db, bcrypt

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    """depende de la base de datos, está comentado para evitar errores"""
    #db.init_app(app)
    #bcrypt.init_app(app)
    JWTManager(app)
    CORS(app)

    with app.app_context():
        """
        db.create_all()
        """



    return app
