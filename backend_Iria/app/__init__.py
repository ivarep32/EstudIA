# iniciacion de la app
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flasgger import Swagger
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from datetime import timedelta
from app.config import Config
from app.models import db, bcrypt
from app.routes.auth import auth_bp
from app.routes.group import group_bp
from app.routes.user import user_bp
from app.routes.files import files_bp

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    db.init_app(app)
    bcrypt.init_app(app)
    JWTManager(app)
    CORS(app)
    Swagger(app)

    app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(days=365 * 100)
    
    with app.app_context():
        db.create_all()

    app.register_blueprint(auth_bp)
    app.register_blueprint(group_bp)
    app.register_blueprint(user_bp)
    app.register_blueprint(files_bp)
    
    return app
