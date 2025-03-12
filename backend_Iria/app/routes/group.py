from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from flasgger import swag_from

"""DEPENDE DE LA BD"""
from app.models import db, GroupAdmin, Participation, Schedule, Activity, Subject, UserActivity, TimeSlot, Event, GroupEvent, Group

group_bp = Blueprint('group', __name__)


@group_bp.route('/subject/<int:group_id>', methods=['POST'])
@swag_from({
    'tags': ['group'],
    'summary': 'Crear una nueva asignatura',
    'description': 'Permite al usuario añadir una nueva asignatura',
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
                        'priority': {'type': 'integer', 'example': 2},
                        'course_id': {'type': 'integer', 'example': 3},
                        'curricululm': {'type': 'string', 'example': 'nadie sabe lo que es'},
                        'professor': {'type':'string','example': 'Víctor, hermano, siempre estás tragando,te ven en McDonalds y ya están preguntando El combo agrandado, las papas con queso, pero corre más lento que un caracol obeso'}

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
def add_subject(group_id):
    group = db.session.get(Group, group_id)
    if not group:
        return jsonify({"message": "Group not found"}),404
    user_id = get_jwt_identity()

    if not GroupAdmin.query.filter_by(user_id=user_id, group_id=group_id).first():
        return jsonify({"message": "Admin access required"}), 403

    data = request.get_json()

    if not data or 'name' not in data:
        return jsonify({"message": "Invalid JSON format"}), 400

    activity = Activity(
        name=data["name"],
        description=data["description"],
        difficulty=data["difficulty"],
        priority=data["priority"]
    )
    db.session.add(activity)
    db.session.flush()
    
    subject = Subject(
        activity_id=activity,
        group_id=group_id,
        curriculum=data["curriculum"],
        professor=data["professor"]
    )
        
    db.session.add(subject)
    db.session.commit()
    
    return jsonify({"message": "Asignatura añadida"}), 201


@group_bp.route('/schedule/<int:group_id>', methods=['POST'])
@swag_from({
    'tags': ['group'],
    'summary': 'Crear un nuevo horario de grupo',
    'description': 'Permite al usuario crear un nuevo horario de grupo',
    'parameters': [
        {
            'name': 'body',
            'in': 'body',
            'required': True,
            'schema': {
                'type': 'object',
                'properties': {
                    'timeslots': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'activity_id': {'type': 'integer', 'example': 1},
                                'day_of_week': {'type': 'string', 'example': 'Martes'},
                                'start_time': {'type': 'string', 'format': 'time', 'example': '14:30:00'},
                                'end_time': {'type': 'string', 'format': 'time', 'example': '15:30:00'}
                            }
                        }
                    }
                }
            }
        }
    ],
    'responses': {
        201: {'description': 'Horario creado exitosamente'},
        400: {'description': 'Datos inválidos'},
        401: {'description': 'No autorizado'}
    }
})

@jwt_required()
def add_group_schedule(group_id):
    """
    "timeslots": [
        {
            "id": sa.activity_id,

            "day_of_week": sa.day_of_week,
            "start_time": sa.start_time.isoformat(),
            "end_time": sa.end_time.isoformat(),

        } for sa in schedule_subjects
    ]
    
    """
    user_id = get_jwt_identity()

    if not GroupAdmin.query.filter_by(user_id=user_id, group_id=group_id).first():
        return jsonify({"message": "Admin access required"}), 403

    data = request.get_json()

    if not data:
        return jsonify({"message": "Invalid JSON format"}), 400

    new_schedule = Schedule(
        group_id=group_id
    )
    
    db.session.add(new_schedule)
    db.session.flush()
    
    for a in data["timeslots"]:
        timeslot = TimeSlot(            
            schelude_id = new_schedule.schedule_id,
            day_of_week = a["day_of_week"],
            start_time = a["start_time"],
            end_time = a["end_time"],
            
            activity_id = a["activity_id"]
        )
        db.session.add(timeslot)
    
    db.session.commit()
    
    return jsonify({"message": "Horario añadido"}), 201



@group_bp.route('/schedules/<int:group_id>', methods=['GET'])
@swag_from({
    'tags': ['group'],
    'summary': 'Obtiene el horario de un grupo',
    'description': 'Devuelve el horario de un grupo incluyendo las materias y actividades del usuario',
    'parameters':[
        {
            'name': 'group_id',
            'in':'path',
            'required': True,
            'type': 'integer',
            'description': 'ID del grupo al q queremos ir'
        }
    ],
    'responses':{
        200: {
            'description': 'Horario del grupo con sus materias y actividades',
            'schema':{
                'type': 'object',
                'properties':{
                    'id': {'type':'integer','example': '1'},
                    'subjects':{
                        'type': 'array',
                        'items':{
                            'type': 'object',
                            'properties':{
                                'id': {'type': 'integer', 'example': 10},
                                'name': {'type': 'string', 'example': 'Matemáticas Avanzadas'},
                                'difficulty': {'type': 'integer', 'example': 3},
                                'priority': {'type': 'integer', 'example': 2},
                                'day_of_week': {'type': 'string', 'example': 'Monday'},
                                'start_time': {'type': 'string', 'format': 'time', 'example': '08:00:00'},
                                'end_time': {'type': 'string', 'format': 'time', 'example': '10:00:00'},
                                'curriculum': {'type': 'string', 'example': 'Álgebra, Cálculo Diferencial'},
                                'professor': {'type': 'string', 'example': 'Dr. Juan Pérez'}
                            }
                        }
                    },
                    'user_activities':{
                        'type': 'array',
                        'items':{
                            'type': 'object',
                            'properties':{
                                'id': {'type': 'integer', 'example': 10},
                                'name': {'type': 'string', 'example': 'Matemáticas Avanzadas'},
                                'difficulty': {'type': 'integer', 'example': 3},
                                'priority': {'type': 'integer', 'example': 2},
                                'day_of_week': {'type': 'string', 'example': 'Monday'},
                                'start_time': {'type': 'string', 'format': 'time', 'example': '08:00:00'},
                                'end_time': {'type': 'string', 'format': 'time', 'example': '10:00:00'}
                            }
                        }
                    }
                }
            }
        },
        403: {'description': 'Acceso denegado. El usuario no pertenece al grupo.'},
        404: {'description': 'Grupo o horario no encontrado.'}
    }
})
@jwt_required()
def get_group_schedules(group_id):
    group = db.session.get(Group, group_id)
    if not group:
        return jsonify({"message": "Group not found"}),404

    user_id = get_jwt_identity()
    participation = Participation.query.filter_by(user_id=user_id, group_id=group_id).first()
    if not participation:
        return jsonify({"message": "Group access required"}), 403

    group = db.session.get(Group, group_id)
    if not group:
        return jsonify({"message": "Group not found"}), 404

    schedule = Schedule.query.filter_by(group_id=group_id).first()
    if not schedule:
        return jsonify({"message": "No schedule found for this group"}), 404
    
    q = Activity.query.join(TimeSlot.query.filter_by(schedule_id = schedule.schedule_id))
    schedule_subjects = q.join(Subject).all()
    schedule_user_activities = q.join(UserActivity).all()

    schedule_data = {
        "id": schedule.schedule_id,
        "subjects": [
            {
                "id": sa.activity_id,
                "name": sa.name,
                "difficulty" : sa.difficulty,
                "priority" : sa.difficulty,
                
                "day_of_week": sa.day_of_week,
                "start_time": sa.start_time.isoformat(),
                "end_time": sa.end_time.isoformat(),
                
                "curriculum" : sa.curriculum,
                "professor" : sa.professor
                            
            } for sa in schedule_subjects
        ],
        "user_activities": [
            {
                "id": sa.activity_id,
                "name": sa.name,
                "difficulty" : sa.difficulty,
                "priority" : sa.difficulty,
                
                "day_of_week": sa.day_of_week,
                "start_time": sa.start_time.isoformat(),
                "end_time": sa.end_time.isoformat(),
            } for sa in schedule_user_activities
        ]
    }
    return jsonify(schedule_data), 200