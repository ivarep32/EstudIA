from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from flasgger import swag_from
from datetime import datetime, time

"""DEPENDE DE LA BD"""
from app.models import db, GroupAdmin, Participation, Schedule, Activity, Subject, UserActivity, TimeSlot, Event, GroupEvent, Group, UserEvent

group_bp = Blueprint('group', __name__)


@group_bp.route('/subject/<int:group_id>', methods=['POST'])
@swag_from({
    'tags': ['Group'],
    'summary': 'Crear una nueva asignatura',
    'description': 'Permite al usuario añadir una nueva asignatura',
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
        {'name': 'group_id', 'in': 'path', 'type': 'integer', 'required': True, 'description': 'ID of the group'},
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
                        'curriculum': {'type': 'string', 'example': 'Víctor, hermano, siempre estás tragando,te ven en McDonalds y ya están preguntando El combo agrandado, las papas con queso, pero corre más lento que un caracol obeso'},
                        'professor': {'type':'string','example': 'Víctor'}

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
        activity_id=activity.activity_id,
        group_id=group_id,
        curriculum=data["curriculum"],
        professor=data["professor"]
    )
        
    db.session.add(subject)
    db.session.commit()
    
    return jsonify({"message": "Asignatura añadida"}), 201


@group_bp.route('/schedule/<int:group_id>', methods=['POST'])
@swag_from({
    'tags': ['Group'],
    'summary': 'Crear un nuevo horario de grupo',
    'description': 'Permite al usuario crear un nuevo horario de grupo',
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
        {'name': 'group_id', 'in': 'path', 'type': 'integer', 'required': True, 'description': 'ID of the group'},
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
    group = db.session.get(Group, group_id)
    if not group:
        return jsonify({"message": "Group not found"}),404
    
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
            schedule_id = new_schedule.schedule_id,
            day_of_week = a["day_of_week"],
            start_time = time.fromisoformat(a["start_time"]),
            end_time = time.fromisoformat(a["end_time"]),
            
            activity_id = a["activity_id"]
        )
        db.session.add(timeslot)
    
    db.session.commit()
    
    return jsonify({"message": "Horario añadido"}), 201



@group_bp.route('/schedules/<int:group_id>', methods=['GET'])
@swag_from({
    'tags': ['Group'],
    'summary': 'Obtiene el horario de un grupo',
    'description': 'Devuelve el horario de un grupo incluyendo las materias y actividades del usuario',
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
    
    schedule_subjects = db.session.query(Activity, Subject, TimeSlot)\
        .join(Activity, Activity.activity_id == Subject.activity_id)\
        .join(TimeSlot, TimeSlot.activity_id == Activity.activity_id)\
        .filter(TimeSlot.schedule_id == schedule.schedule_id)

    schedule_data = {
        "id": schedule.schedule_id,
        "subjects": [
            {
                "id": activity.activity_id,
                "name": activity.name,
                "difficulty" : activity.difficulty,
                "priority" : activity.difficulty,
                
                "day_of_week": timeslot.day_of_week,
                "start_time": timeslot.start_time.isoformat(),
                "end_time": timeslot.end_time.isoformat(),
                
                "curriculum" : subject.curriculum,
                "professor" : subject.professor
                            
            } for activity, subject, timeslot in schedule_subjects
        ]
    }
    return jsonify(schedule_data), 200

@group_bp.route('/event/<int:group_id>', methods=['POST'])
@swag_from({
    'tags': ['Group'],
    'summary': 'Crear un nuevo evento',
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
        {'name': 'group_id', 'in': 'path', 'type': 'integer', 'required': True, 'description': 'ID of the group'},
        {
            'name': 'body',
            'in': 'body',
            'required': True,
            'schema':{
                'type': 'object',
                'properties': {
                    'start_time': {'type':'string', 'format': 'date-time', 'example':'2025-03-12T13:30:00'},
                    'end_time': {'type':'string', 'format': 'date-time', 'example':'2025-03-12T14:30:00'},
                    'type': {'type':'string', 'example': 'examen parcial'},
                    'name': {'type': 'string', 'example': 'Examen de geografía'},
                    'description': {'type': 'string', 'example': 'Estudiar los rios de europa'},
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
def add_event(group_id):
    group = db.session.get(Group, group_id)
    if not group:
        return jsonify({"message": "Group not found"}), 404
    user_id = get_jwt_identity()

    if not GroupAdmin.query.filter_by(user_id=user_id, group_id=group_id).first():
        return jsonify({"message": "Admin access required"}), 403

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

    group_event = GroupEvent(
        group_id=group_id,
        event_id=event.event_id
    )
    db.session.add(group_event)

    participation = Participation.query.filter_by(group_id=group_id).all()
    for p in participation:
        user_id = p.user_id
        user_event = UserEvent(
            user_id=user_id,
            event_id=event.event_id,
            completed=False,
            seen=False
        )
        db.session.add(user_event)

    db.session.commit()

    return jsonify({"message": "Evento añadido"}), 201

@group_bp.route('/group', methods=['POST'])
@swag_from({
    'tags': ['Group'],
    'summary': 'Crear un nuevo grupo',
    'description': """Permite crear un nuevo grupo. 
                      El usuario pasa a ser el admin del grupo que crea.
                      Si se proporciona el `supergroup_id`, el grupo se genera como subgrupo de forma automática, 
                      pero no es obligatorio.""",
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
                    'name': {'type': 'string', 'example': 'Grupo de Matemáticas'},
                    'supergroup_id': {'type': 'integer', 'example': 1, 'nullable': True}
                }
            }
        }
    ],
    'responses': {
        201: {'description': 'Grupo creado exitosamente'},
        400: {'description': 'Datos inválidos'},
        401: {'description': 'No autorizado'}
    }
})

@jwt_required()
def add_group():
    user_id = get_jwt_identity()
    data = request.get_json()

    if not data or 'name' not in data:
        return jsonify({"message": "Invalid JSON format"}), 400

    new_group = Group(
        name=data["name"],
        supergroup_id=data.get('supergroup_id')
    )
    db.session.add(new_group)
    db.session.flush()

    participation = Participation(
        user_id=user_id,
        group_id=new_group.group_id
    )
    db.session.add(participation)
    
    admin = GroupAdmin(
        user_id=user_id,
        group_id=new_group.group_id
    )
    db.session.add(admin)

    db.session.commit()

    return jsonify({"message": "Grupo creado"}), 201
