from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from flasgger import swag_from
"""DEPENDE DE LA BD"""
from app.models import db, User, GroupAdmin, Participation, Schedule, Activity, Subject, UserActivity, TimeSlot, Event, GroupEvent, Group, UserEvent

user_bp = Blueprint('user', __name__, url_prefix="/user")

@user_bp.route('/groups', methods=['GET'])
@swag_from({
    'tags': ['User'],
    'summary':'Devuelve los grupos de un usurario',
    'responses':{
        200:{
            'description': 'lista de grupos',
            'schema': {
                'type': 'array',
                'items':{
                    'type': 'object',
                    'properties':{
                        'id': {'type': 'integer', 'example': 1},
                        'name': {'type': 'string', 'example': 'grupo de mates'},
                        'parent_group': {'type': 'integer', 'example': 2}
                    }
                }

            }
        },
        401: {'description': 'No autorizado'}
    }
})
@jwt_required()
def get_groups():
    user_id = get_jwt_identity()
    groups = Group.query.join(Participation.query.filter_by(user_id=user_id)).all()
    return jsonify([{
        "id": g.id,
        "name": g.name,
        "parent_group": g.supergroup_id
    } for g in groups]), 200

@user_bp.route('/subjects', methods=['GET'])
@jwt_required()
@swag_from({
    'tags': ['User'],
    'summary': 'Obtener las materias del usuario',
    'description': 'Devuelve todas las materias relacionadas con los grupos del usuario',
    'responses':{
        200:{
            'description': 'Lista de materias',
            'schema':{
                'type': 'array',
                'items': {
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
            }
        },
        401: {'description': 'No autorizado'}
    }
})
def get_subjects():
    user_id = get_jwt_identity()
    groups_query = Group.query.join(Participation.query.filter_by(user_id=user_id))
    subjects = groups_query.join(TimeSlot).join(Subject).all()
    
    return jsonify([
        {
            "id": s.activity_id,
            "name": s.name,
            "difficulty" : s.difficulty,
            "priority" : s.difficulty,
            
            "day_of_week": s.day_of_week,
            "start_time": s.start_time.isoformat(),
            "end_time": s.end_time.isoformat(),
            
            "curriculum" : s.curriculum,
            "professor" : s.professor
                        
        } for s in subjects
    ]), 200

@user_bp.route('/activities', methods=['GET'])
@jwt_required()
@swag_from({
    'tags': ['User'],
    'summary': 'Obtener las actividades del usuario',
    'description': 'Devuelve todas las actividades propias del usuario',
    'responses':{
        200:{
            'description': 'Lista de actividades',
            'schema':{
                'type': 'array',
                'items': {
                    'type': 'object',
                    'properties':{
                        'id': {'type': 'integer', 'example': 10},
                        'name': {'type': 'string', 'example': 'Matemáticas Avanzadas'},
                        'difficulty': {'type': 'integer', 'example': 3},
                        'priority': {'type': 'integer', 'example': 2},
                        
                        'day_of_week': {'type': 'string', 'example': 'Monday'},
                        'start_time': {'type': 'string', 'format': 'time', 'example': '08:00:00'},
                        'end_time': {'type': 'string', 'format': 'time', 'example': '10:00:00'},
                        
                        'hours': {'type': 'number', 'format': 'float', 'example': 2.5},
                        'period': {'type': 'string', 'example': 'weekly'}
                    }
                }
            }
        },
        401: {'description': 'No autorizado'}
    }
})
def get_activities():
    user_id = get_jwt_identity()
    activities = UserActivity.query.filter_by(user_id=user_id).join(Activity).outerjoin(TimeSlot).all()
    
    return jsonify([
        {
            "id": a.activity_id,
            "name": a.name,
            "difficulty" : a.difficulty,
            "priority" : a.difficulty,
            
            "day_of_week": a.day_of_week,
            "start_time": a.start_time.isoformat(),
            "end_time": a.end_time.isoformat(),
            
            "hours" : a.hours,
            "period" : a.period
                        
        } for a in activities
    ]), 200



@user_bp.route('/activity', methods=['POST'])
@jwt_required()
@swag_from({
    'tags': ['User'],
    'summary': 'Añadir una actividad',
    'description': 'Permite al usuario añadir una nueva actividad',
    'parameters':[
        {
            'name': 'body',
            'in': 'body',
            'required': True,
            'schema':{
                'type':'object',
                'properties':{
                    'name': {'type': 'string', 'example': 'Tarea de Física'},
                    'description': {'type': 'string', 'example': 'Resolver ejercicios de dinámica'},
                    'difficulty': {'type': 'integer', 'example': 4},
                    'priority': {'type': 'integer', 'example': 1},
                    'subject_id': {'type': 'integer', 'example': 2},
                    'hours': {'type': 'number', 'format': 'float', 'example': 2.5},
                    'period': {'type': 'string', 'example': 'weekly'}
                }
            }
        }
    ],
    'responses':{
        201: {'description': 'Actividad añadida exitosamente'},
        400: {'description': 'Datos inválidos'},
        401: {'description': 'No autorizado'}
    }
})
def add_activity():
    user_id = get_jwt_identity()

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
    
    if not "subject_id" in data:
        data["subject_id"] = None
    if not "hours" in data:
        data["hours"] = None
    if not "period" in data:
        data["period"] = None
    
    subject = UserActivity(
        activity_id=activity,
        user_id=user_id,
        subject_id=data["subject_id"],
        hours=data["hours"],
        period=data["period"]
    )
        
    db.session.add(subject)
    db.session.commit()
    
    return jsonify({"message": "Actividad añadida"}), 201

@user_bp.route('/schedule', methods=['POST'])
@jwt_required()
@swag_from({
    'tags': ['User'],
    'summary': 'Añadir un horario para el usuario',
    'description': 'Permite al usuario autenticado crear un nuevo horario con sus actividades.',
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
                                'day_of_week': {'type': 'string', 'example': 'Lunes'},
                                'start_time': {'type': 'string', 'format': 'time', 'example': '08:00:00'},
                                'end_time': {'type': 'string', 'format': 'time', 'example': '10:00:00'},
                                'activity_id': {'type': 'integer', 'example': 5}
                            }
                        }
                    }
                }
            }
        }
    ],
    'responses': {
        201: {'description': 'Horario añadido exitosamente'},
        400: {'description': 'Formato JSON inválido'},
        401: {'description': 'No autorizado'}
    }
})
def add_user_schedule():
    user_id = get_jwt_identity()

    data = request.get_json()

    if not data:
        return jsonify({"message": "Invalid JSON format"}), 400

    new_schedule = Schedule(
        user_id=user_id
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


@user_bp.route('/schedules', methods=['GET'])
@jwt_required()
@swag_from({
    'tags': ['User'],
    'summary': 'Obtener horarios del usuario',
    'description': 'Devuelve todos los horarios asociados al usuario autenticado.',
    'responses': {
        200: {
            'description': 'Lista de horarios',
            'schema': {
                'type': 'array',
                'items': {
                    'type': 'object',
                    'properties': {
                        'id': {'type': 'integer', 'example': 1},
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
                                    'end_time': {'type': 'string', 'format': 'time', 'example': '10:00:00'},
                                    'hours': {'type': 'number', 'format': 'float', 'example': 2.5},
                                    'period': {'type': 'string', 'example': 'weekly'}
                                }
                            }
                        }
                    }
                }
            }
        },
        404: {'description': 'No se encontraron horarios'},
        401: {'description': 'No autorizado'}
    }
})
def get_full_user_schedules():
    user_id = get_jwt_identity()

    groups = Group.query.join(Participation.query.filter_by(Participation.user_id==user_id))
    
    schedules_query = Schedule.query.join(groups)
    schedules = schedules_query.all()
    schedules.extend(Schedule.query.join(User.query.filter_by(user_id=user_id)).all())
    
    if not schedules:
        return jsonify({"message": "No schedule found for this user"}), 404
    
    for schedule in schedules:
        timeslot_query = TimeSlot.query.join(Schedule.query.filter_by(schedule_id = schedule.schedule_id)).join(Activity)
        schedule_subjects = timeslot_query.join(Subject).all()
        schedule_user_activities = timeslot_query.join(UserActivity).all()
        schedule_data = [
                {
                    "id": schedule.schedule_id,
                    "subjects": [
                        {
                            "id": s.activity_id,
                            "name": s.name,
                            "difficulty" : s.difficulty,
                            "priority" : s.difficulty,
                            
                            "day_of_week": s.day_of_week,
                            "start_time": s.start_time.isoformat(),
                            "end_time": s.end_time.isoformat(),
                            
                            "curriculum" : s.curriculum,
                            "professor" : s.professor
                                        
                        } for s in schedule_subjects
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
                            
                            "hour": sa.hour,
                            "period": sa.period
                        } for sa in schedule_user_activities
                    ]
                }
            ]
    return jsonify(schedule_data), 200


@user_bp.route('/event', methods=['POST'])
@jwt_required()
@swag_from({
    'tags': ['User'],
    'summary': 'Añadir un evento',
    'description': 'Permite al usuario añadir un nuevo evento',
    'parameters': [
        {
            'name': 'body',
            'in': 'body',
            'required': True,
            'schema': {
                'type': 'object',
                'properties': {
                    'completed': {'type':'boolean', 'example': False},
                    'seen': {'type':'boolean', 'example': False}
                }
            }
        }
    ],
    'responses': {
        201: {'description': 'Evento añadido exitosamente'},
        400: {'description': 'Datos inválidos'},
        401: {'description': 'No autorizado'}
    }
})
def add_event():
    user_id = get_jwt_identity()

    data = request.get_json()

    if not data or 'name' not in data:
        return jsonify({"message": "Invalid JSON format"}), 400

    event = Event(
        start_time=data["start_time"],
        end_time=data["end_time"],
        type=data["type"],
        name=data["name"],
        description=data["description"]
    )
    db.session.add(event)
    db.session.flush()

    user_event = UserEvent(
        user_id=user_id,
        event_id=event.id,
        completed=data['completed'],
        seen=data['seen']
    )

    db.session.add(user_event)
    db.session.commit()

    return jsonify({"message": "Evento añadido"}), 201