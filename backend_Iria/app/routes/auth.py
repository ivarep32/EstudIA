#archivo de rutas de autenticacion
# archivo de rutas de autenticación
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
from flasgger import swag_from
"""DEPENDE DE LA BD"""
from app.models import db, User

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
@swag_from({
    'tags': ['Auth'],
    'summary': 'Registro de usuario',
    'description': 'Permite registrar un nuevo usuario en el sistema.',
    'parameters': [
        {
            'name': 'body',
            'in': 'body',
            'required': True,
            'schema': {
                'type': 'object',
                'properties': {
                    'username': {'type': 'string', 'example': 'usuario123'},
                    'email': {'type': 'string', 'example': 'usuario@example.com'},
                    'password': {'type': 'string', 'example': '123456'}
                }
            }
        }
    ],
    'responses': {
        201: {'description': 'Usuario registrado exitosamente'},
        400: {'description': 'El usuario ya existe'}
    }
})
def register():
    data = request.json

    if User.query.filter_by(username=data['username']).first():
        return jsonify({"error": "El usuario ya existe"}), 400

    user = User(username=data['username'], email=data['email'])
    user.set_password(data['password'])
    db.session.add(user)
    db.session.commit()

    return jsonify({"message": "Usuario registrado"}), 201

@auth_bp.route('/login', methods=['POST'])
@swag_from({
    'tags': ['Auth'],
    'summary': 'Inicio de sesión',
    'description': 'Permite a un usuario autenticarse y obtener un token JWT.',
    'parameters': [
        {
            'name': 'body',
            'in': 'body',
            'required': True,
            'schema': {
                'type': 'object',
                'properties': {
                    'username': {'type': 'string', 'example': 'usuario1'},
                    'password': {'type': 'string', 'example': '123456'}
                }
            }
        }
    ],
    'responses': {
        200: {
            'description': 'Inicio de sesión exitoso',
            'schema': {
                'type': 'object',
                'properties': {
                    'access_token': {'type': 'string'}
                }
            }
        },
        401: {'description': 'Credenciales inválidas'}
    }
})
def login():
    data = request.json
    user = User.query.filter_by(username=data['username']).first()
    if user and user.check_password(data['password']):
        token = create_access_token(identity=str(user.user_id))
        return jsonify({"access_token": token}), 200

    return jsonify({"error": "Credenciales inválidas"}), 401
