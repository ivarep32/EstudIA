from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from flasgger import swag_from
from datetime import date, datetime, time
"""DEPENDE DE LA BD"""
from app.models import db, User, GroupAdmin, Participation, Schedule, Activity, Subject, UserActivity, TimeSlot, Event, GroupEvent, Group, UserEvent

user_bp = Blueprint('user', __name__, url_prefix="/user")

@user_bp.route('/groups', methods=['GET'])
@swag_from({
    'tags': ['User'],
    'summary':'Devuelve los grupos de un usurario',
    'parameters':[
        {
            'name': 'Authorization',
            'in': 'header',
            'required': True,
            'description': 'Bearer token for authentication',
            'schema': {
                'type': 'string',
                'example': 'Bearer <your_jwt_token>'
            }
        }
    ],
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
    
    groups = (
    db.session.query(Group)  # Ensure we're selecting Group objects
    .join(Participation, Participation.group_id == Group.group_id)  # Join Participation with Group
    .filter(Participation.user_id == user_id)  # Filter by user_id
    .all()
    )

    return jsonify([{
        "id": g.group_id,
        "name": g.name,
        "parent_group": g.supergroup_id
    } for g in groups]), 200


@user_bp.route('/admin_of', methods=['GET'])
@swag_from({
    'tags': ['User'],
    'summary':'Devuelve los grupos de los que un usurario es admin',
    'parameters':[
        {
            'name': 'Authorization',
            'in': 'header',
            'required': True,
            'description': 'Bearer token for authentication',
            'schema': {
                'type': 'string',
                'example': 'Bearer <your_jwt_token>'
            }
        }
    ],
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
def get_admin_of_groups():
    user_id = get_jwt_identity()
    
    groups = (
        db.session.query(Group)  # Ensure we're selecting Group objects
        .join(GroupAdmin, GroupAdmin.group_id == Group.group_id)  # Join Participation with Group
        .filter(GroupAdmin.user_id == user_id)  # Filter by user_id
        .all()
    )

    return jsonify([{
        "id": g.group_id,
        "name": g.name,
        "parent_group": g.supergroup_id
    } for g in groups]), 200

@user_bp.route('/subjects', methods=['GET'])
@jwt_required()
@swag_from({
    'tags': ['User'],
    'summary': 'Obtener las materias del usuario',
    'description': 'Devuelve todas las materias relacionadas con los grupos del usuario',
    'parameters':[
        {
            'name': 'Authorization',
            'in': 'header',
            'required': True,
            'description': 'Bearer token for authentication',
            'schema': {
                'type': 'string',
                'example': 'Bearer <your_jwt_token>'
            }
        }
    ],
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
    
    db.session.query
    result = db.session.query(Group,Activity,Subject,Participation)\
        .join(Subject, Subject.group_id == Group.group_id)\
        .join(Activity, Activity.activity_id == Subject.activity_id)\
        .join(Participation, Participation.group_id == Group.group_id)\
        .filter_by(user_id = user_id).all()
        
    return jsonify([
        {
            "id": activity.activity_id,
            "name": activity.name,
            "difficulty" : activity.difficulty,
            "priority" : activity.difficulty,
            
            "curriculum" : subject.curriculum,
            "professor" : subject.professor
                        
        } for group, activity, subject, participation in result
    ]), 200

@user_bp.route('/activities', methods=['GET'])
@jwt_required()
@swag_from({
    'tags': ['User'],
    'summary': 'Obtener las actividades del usuario',
    'description': 'Devuelve todas las actividades propias del usuario',
    'parameters':[
        {
            'name': 'Authorization',
            'in': 'header',
            'required': True,
            'description': 'Bearer token for authentication',
            'schema': {
                'type': 'string',
                'example': 'Bearer <your_jwt_token>'
            }
        }
    ],
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
    result = db.session.query(Activity,UserActivity)\
        .join(Activity, Activity.activity_id==UserActivity.activity_id)\
        .filter(UserActivity.user_id==user_id).all()
    
    return jsonify([
        {
            "id": activity.activity_id,
            "name": activity.name,
            "difficulty" : activity.difficulty,
            "priority" : activity.difficulty,
            
            "hours" : user_activity.hours,
            "period" : user_activity.period
                        
        } for activity, user_activity in result
    ]), 200



@user_bp.route('/activity', methods=['POST'])
@jwt_required()
@swag_from({
    'tags': ['User'],
    'summary': 'Añadir una actividad',
    'description': 'Permite al usuario añadir una nueva actividad',
    'parameters':[
        {
            'name': 'Authorization',
            'in': 'header',
            'required': True,
            'description': 'Bearer token for authentication',
            'schema': {
                'type': 'string',
                'example': 'Bearer <your_jwt_token>'
            }
        },
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
    
    subject = UserActivity(
        activity_id=activity.activity_id,
        user_id=user_id,
        subject_id=data.get("subject_id"),
        hours=data.get("hours"),
        period=data.get("period")
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
            'name': 'Authorization',
            'in': 'header',
            'required': True,
            'description': 'Bearer token for authentication',
            'schema': {
                'type': 'string',
                'example': 'Bearer <your_jwt_token>'
            }
        },
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
                                'start_time': {'type':'string', 'format': 'date-time', 'example':'13:30:00'},
                                'end_time': {'type':'string', 'format': 'date-time', 'example':'14:30:00'},
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

    schedule = Schedule(
        user_id=user_id
    )
    
    db.session.add(schedule)
    db.session.flush()
    
    for a in data["timeslots"]:
        timeslot = TimeSlot(            
            schedule_id = schedule.schedule_id,
            day_of_week = a["day_of_week"],
            start_time=time.fromisoformat(a["start_time"]),
            end_time=time.fromisoformat(a["end_time"]),
            
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
    'parameters':[
        {
            'name': 'Authorization',
            'in': 'header',
            'required': True,
            'description': 'Bearer token for authentication',
            'schema': {
                'type': 'string',
                'example': 'Bearer <your_jwt_token>'
            }
        }
    ],
    'responses': {
        200: {
            'description': 'Lista de horarios',
            'schema': {
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
                        
                        'is_personal': {'type':'boolean', 'example': False},
                    }
                }
            }
        },
        404: {'description': 'No se encontraron horarios'},
        401: {'description': 'No autorizado'}
    }
})
def get_full_user_schedule():
    user_id = get_jwt_identity()

    result_groups = db.session.query(Schedule, TimeSlot, Activity)\
        .select_from(Schedule)\
        .join(Group, Schedule.group_id == Group.group_id)\
        .join(Participation, Participation.group_id == Group.group_id)\
        .join(TimeSlot, TimeSlot.schedule_id == Schedule.schedule_id)\
        .join(Activity, Activity.activity_id == TimeSlot.activity_id)\
        .filter(Participation.user_id == user_id).all()

    result_user = db.session.query(Schedule, TimeSlot, Activity)\
        .join(User, Schedule.user_id == User.user_id)\
        .join(TimeSlot, TimeSlot.schedule_id == Schedule.schedule_id)\
        .join(Activity, Activity.activity_id == TimeSlot.activity_id)\
        .filter(User.user_id == user_id).all()

    result = []
    for schedule, timeslot, activity in (result_groups+result_user):
        is_personal = True
        if schedule.group_id is not None:
            is_personal = False
        result.append(
            {
                "id": activity.activity_id,
                "name": activity.name,
                "difficulty" : activity.difficulty,
                "priority" : activity.difficulty,
                
                "day_of_week": timeslot.day_of_week,
                "start_time": timeslot.start_time.isoformat(),
                "end_time": timeslot.end_time.isoformat(),
                
                "is_personal": is_personal
            }
        )
    
    return jsonify(result), 200


@user_bp.route('/event', methods=['POST'])
@jwt_required()
@swag_from({
    'tags': ['User'],
    'summary': 'Añadir un evento',
    'description': 'Permite al usuario añadir un nuevo evento',
    'parameters': [
        {
            'name': 'Authorization',
            'in': 'header',
            'required': True,
            'description': 'Bearer token for authentication',
            'schema': {
                'type': 'string',
                'example': 'Bearer <your_jwt_token>'
            }
        },
        {
            'name': 'body',
            'in': 'body',
            'required': True,
            'schema': {
                'type': 'object',
                'properties': {
                    'start_time': {'type':'string', 'format': 'date-time', 'example':'2025-03-12T13:30:00'},
                    'end_time': {'type':'string', 'format': 'date-time', 'example':'2025-03-12T14:30:00'},
                    'type': {'type':'string', 'example': 'examen parcial'},
                    'name': {'type': 'string', 'example': 'Examen de geografía'},
                    'description': {'type': 'string', 'example': 'Estudiar los rios de europa'},
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
        start_time=datetime.fromisoformat(data["start_time"]),
        end_time=datetime.fromisoformat(data["end_time"]),
        type=data["type"],
        name=data["name"],
        description=data["description"]
    )
    db.session.add(event)
    db.session.flush()

    user_event = UserEvent(
        user_id=user_id,
        event_id=event.event_id,
        completed=data['completed'],
        seen=data['seen']
    )

    db.session.add(user_event)
    db.session.commit()

    return jsonify({"message": "Evento añadido"}), 201


@user_bp.route('/events', methods=['GET'])
@jwt_required()
@swag_from({
    'tags': ['User'],
    'summary': 'Obtener los eventos del usuario',
    'description': 'Devuelve todas los eventos relacionados con los grupos del usuario',
    'parameters':[
        {
            'name': 'Authorization',
            'in': 'header',
            'required': True,
            'description': 'Bearer token for authentication',
            'schema': {
                'type': 'string',
                'example': 'Bearer <your_jwt_token>'
            }
        }
    ],
    'responses': {
        200: {
            'description': 'Lista de eventos',
            'schema': {
                'type': 'array',
                'items': {
                    'type': 'object',
                    'properties': {
                        'id': {'type': 'integer', 'example': 10},
                        'start_time': {'type':'string', 'format': 'date-time', 'example':'2025-03-12T13:30:00'},
                        'end_time': {'type':'string', 'format': 'date-time', 'example':'2025-03-12T14:30:00'},
                        'type': {'type': 'string','example': 'examen'},
                        'name': {'type': 'string', 'example': 'Examen de Algebra'},
                        'description': {'type': 'string', 'example': 'Examen final de algebra, entran todos los temas'},
                        'completed': {'type': 'boolean', 'example': True},
                        'seen': {'type': 'boolean', 'example': True}
                    }
                }
            }
        },
        401: {'description': 'No autorizado'}
    }
})
def get_events():
    user_id = get_jwt_identity()
    events = db.session.query(Event, UserEvent)\
        .join(Event, Event.event_id == UserEvent.event_id)\
        .filter(UserEvent.user_id == user_id).all()

    return jsonify([
        {
            "id": event.event_id,
            "start_time": event.start_time.isoformat(),
            "end_time": event.end_time.isoformat(),
            "type": event.type,
            "name": event.name,
            "description": event.description,

            "completed": user_event.completed,
            "seen": user_event.seen

        } for event, user_event in events
    ]), 200

