# iniciacion de la app
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flasgger import Swagger
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from app.config import Config
from app.models import db, bcrypt
from app.routes.auth import auth_bp
from app.routes.notifications import notifications_bp
from app.routes.schedules import schedule_bp
from app.routes.activities import activities_bp


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    db.init_app(app)
    bcrypt.init_app(app)
    JWTManager(app)
    CORS(app)
    Swagger(app)

    with app.app_context():
        db.create_all()

    app.register_blueprint(auth_bp)
    app.register_blueprint(schedule_bp)
    app.register_blueprint(activities_bp)
    app.register_blueprint(notifications_bp)

    return app
