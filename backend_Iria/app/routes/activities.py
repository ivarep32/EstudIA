#archivo rutas de tareas y tests
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from flasgger import swag_from
"""DEPENDEN DE LA BD"""
from app.models import db, Activity

activities_bp = Blueprint('activities', __name__)

@activities_bp.route('/activities', methods=['GET'])
@swag_from({
    'tags': ['activities'],
    'summary': 'Actividades del usuario',
    'description': 'almacena las actividades y tareas del usuario en el sistema',
    'responses':
        {
        200: {
            'description': 'Lista de actividades',
            'schema': {
                'type': 'array',
                'items':{
                    'type': 'object',
                    'properties': {
                        'name': {'type': 'string', 'example': 'Estudiar mates'},
                        'description': {'type': 'string', 'example': 'Estudiar los temas de geometría'},
                        'difficulty': {'type': 'integer', 'example': 8},
                        'priority': {'type': 'integer', 'example': 4}
                    }
                }
            }
        },
            401: {'description': 'No autorizado'}
        }
})
@jwt_required()
def get_activities():
    user_id = get_jwt_identity()
    activities = Activity.query.filter_by(user_id=user_id).all()
    return jsonify([{
        "id": t.id,
        "title": t.title,
        "due_date": str(t.due_date),
        "completed": t.completed
    } for t in activities]), 200



@activities_bp.route('/activities', methods=['POST'])
@swag_from({
    'tags': ['activities'],
    'summary': 'Crear una nueva actividad',
    'description': 'Permite al usuario añadir una nueva actividad',
    'parameters': [
        {
            'name': 'body',
            'in': 'body',
            'required': True,
            'schema':{
                'type': 'object',
                'properties':{
                        'name': {'type': 'string', 'example': 'Estudiar geografía'},
                        'description': {'type': 'string', 'example': 'Estudiar los rios de europa'},
                        'difficulty': {'type': 'integer', 'example': 9999},
                        'priority': {'type': 'integer', 'example': 2}
                }
            }
        }
    ],
    'responses':{
        201:{'description': 'actividad creada exitosamente'},
        400:{'description': 'datos inválidos'},
        401:{'description': 'no autorizado'}
    }
})
@jwt_required()
def add_activity():
    data = request.json
    user_id = get_jwt_identity()
    new_activity = Activity(
        user_id=user_id,
        title=data['title'],
        due_date=data['due_date'],
        completed=False
    )
    db.session.add(new_activity)
    db.session.commit()
    return jsonify({"message": "Actividad añadida"}), 201
