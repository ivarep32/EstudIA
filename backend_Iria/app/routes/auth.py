#archivo de rutas de autenticacion
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
"""DEPENDE DE LA BD"""
from app.models import db, User

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.json

    if User.query.filter_by(email=data['email']).first():
        return jsonify({"error": "El usuario ya existe"}), 400


    user = User(username=data['username'], email=data['email'])
    user.set_password(data['password'])
    db.session.add(user)
    db.session.commit()

    return jsonify({"message": "Usuario registrado"}), 201

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    user = User.query.filter_by(email=data['email']).first()
    if user and user.check_password(data['password']):
        token = create_access_token(identity=user.id)
        return jsonify({"access_token": token}), 200

    return jsonify({"error": "Credenciales inválidas"}), 401
