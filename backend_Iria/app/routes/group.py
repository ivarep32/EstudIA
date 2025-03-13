from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from flasgger import swag_from
from datetime import datetime, time

"""DEPENDE DE LA BD"""
from app.models import db, GroupAdmin, Participation, Schedule, Activity, Subject, UserActivity, TimeSlot, Event, GroupEvent, Group, UserEvent, User

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
        401:{'description': 'no autorizado'},
        404: {'descrption': 'group not found'},
    }
})
@jwt_required()
def add_subject(group_id):
    group = db.session.get(Group, group_id)
    if not group:
        return jsonify({"message": "Group not found"}),404
    user_id = get_jwt_identity()

    if not GroupAdmin.query.filter_by(user_id=user_id, group_id=group_id).first():
        return jsonify({"message": "Admin access required"}), 401

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


@group_bp.route('/schedule/<int:group_id>', methods=['PUT'])
@swag_from({
    'tags': ['Group'],
    'summary': 'Crear un nuevo horario de grupo o sobreescribe el existente',
    'description': 'Permite al usuario crear o sobreescribir un horario de grupo',
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
        401: {'description': 'No autorizado'},
        404: {'descrption': 'group not found'}
    }
})

@jwt_required()
def add_group_schedule(group_id):
    group = db.session.get(Group, group_id)
    if not group:
        return jsonify({"message": "Group not found"}),404
    
    user_id = get_jwt_identity()

    if not GroupAdmin.query.filter_by(user_id=user_id, group_id=group_id).first():
        return jsonify({"message": "Admin access required"}), 401

    data = request.get_json()

    if not data:
        return jsonify({"message": "Invalid JSON format"}), 400

    schedule = Schedule.query.filter_by(group_id=group_id).first()
    if schedule:
        db.session.query(TimeSlot).filter(TimeSlot.schedule_id == schedule.schedule_id)\
            .delete(synchronize_session='fetch')
        db.session.commit()
    else:
        schedule = Schedule(
            group_id=group_id
        )
    
        db.session.add(schedule)
        db.session.flush()
    
    for a in data["timeslots"]:
        timeslot = TimeSlot(            
            schedule_id = schedule.schedule_id,
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
        403:{'description': 'no autorizado'},
        404: {'descrption': 'group not found'}
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


@group_bp.route('/event/<int:event_id>', methods=['PATCH'])
@swag_from({
    'tags': ['Group'],
    'summary': 'Modifica un evento exitente',
    'description': 'Permite al usuario modificar un evento existente',
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
        {'name': 'event_id', 'in': 'path', 'type': 'integer', 'required': True, 'description': 'ID of the event'},
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
        403:{'description': 'no autorizado'},
        404: {'descrption': 'event not found'}

    }
})
@jwt_required()
def modify_event(event_id):
    event = db.session.get(Event, event_id)
    if not event:
        return jsonify({"message": "Event not found"}), 404
    
    group_event = db.session.get(GroupEvent, event_id)
    
    if not group_event:
        return jsonify({"message": "The given event is not a assigned to any group"})
    
    group_id = group_event.group_id
    user_id = get_jwt_identity()

    if not GroupAdmin.query.filter_by(user_id=user_id, group_id=group_id).first():
        return jsonify({"message": "Admin access required"}), 403

    data = request.get_json()

    if not data or 'name' not in data:
        return jsonify({"message": "Invalid JSON format"}), 400

    event.name = data["name"]
    event.type = data["type"]
    event.description = data["description"]
    event.start_time = datetime.fromisoformat(data["start_time"])
    event.end_time = datetime.fromisoformat(data["end_time"])

    participation = Participation.query.filter_by(group_id=group_id).all()
    for p in participation:
        user_id = p.user_id
        user_event = UserEvent.query.get({"user_id": user_id, "event_id": event_id})
        user_event.seen = False

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

@group_bp.route('/group/<int:group_id>', methods=['PUT'])
@swag_from({
    'summary': 'Add a user to a group',
    'description': 'Allows a group admin to add a user to a specified group.',
    'parameters': [
        {
            'name': 'group_id',
            'in': 'path',
            'type': 'integer',
            'required': True,
            'description': 'The ID of the group to which the user will be added.'
        },
        {
            'name': 'body',
            'in': 'body',
            'required': True,
            'schema': {
                'type': 'object',
                'properties': {
                    'user_id': {
                        'type': 'integer',
                        'description': 'The ID of the user to be added to the group.'
                    }
                },
                'required': ['user_id']
            }
        }
    ],
    'responses': {
        200: {
            'description': 'User successfully added to the group',
            'schema': {
                'type': 'object',
                'properties': {
                    'message': {'type': 'string'}
                }
            }
        },
        400: {
            'description': 'Invalid JSON format',
            'schema': {
                'type': 'object',
                'properties': {
                    'message': {'type': 'string'}
                }
            }
        },
        403: {
            'description': 'Admin access required',
            'schema': {
                'type': 'object',
                'properties': {
                    'message': {'type': 'string'}
                }
            }
        }
    }
})

@jwt_required()
def add_user_to_group(group_id):
    user_id = get_jwt_identity()
    data = request.get_json()

    if not data or 'name' not in data:
        return jsonify({"message": "Invalid JSON format"}), 400

    if not GroupAdmin.query.filter_by(user_id=user_id, group_id=group_id).first():
        return jsonify({"message": "Admin access required"}), 403

    new_user=Participation(user_id=data["user_id"], group_id=group_id)
    db.session.add(new_user)
    db.session.commit()
    return jsonify({"message": "Usuario añadido"}), 200


@group_bp.route('/subjects/<int:group_id>', methods=['GET'])
@swag_from({
    'tags': ['Group'],
    'summary': 'Obtiene las asignaturas de un grupo',
    'description': 'Devuelve las asignaturas de un grupo con los asignaturas de un grupo.',
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
            'name': 'group_id',
            'in': 'path',
            'required': True,
            'type': 'integer',
            'description': 'ID del grupo al q queremos ir'
        }
    ],
    'responses': {
        200: {
            'description': 'Horario del grupo con sus materias y actividades',
            'schema': {
                'type': 'object',
                'properties': {
                    'id': {'type': 'integer', 'example': '1'},
                    'subjects': {
                        'type': 'array', # a partir de aqui
                        'items': {
                            'type': 'object',
                            'properties': {
                                'activity_id': {'type': 'integer', 'example': 10},
                                'name': {'type': 'string', 'example': 'Matemáticas Avanzadas'},
                                'description':{'type':'string', 'example':'No puedo seguir escribiendo codigo ni un solo segundo mas por favor make it end' },
                                'difficulty': {'type': 'integer', 'example': 3},
                                'curriculum': {'type': 'string', 'example': 'Esto no es vida, es el castigo que nos ha puesto, llamalo dios, llamalo energia, porque Eva se comio la manzana'},
                                'professor': {'type': 'string', 'example': 'SATANÁS LLEVAME CONTIGO'}
                            }
                        }
                    }
                }
            }
        },
        403: {'description': 'Acceso denegado. El usuario no pertenece al grupo.'},
        404: {'description': 'Grupo o asignatura no encontrada.'}
    }
})
@jwt_required()
def get_group_subjects(group_id):
    group = db.session.get(Group, group_id)
    if not group:
        return jsonify({"message": "Group not found"}), 404

    user_id = get_jwt_identity()
    participation = Participation.query.filter_by(user_id=user_id, group_id=group_id).first()
    if not participation:
        return jsonify({"message": "Group access required"}), 403

    group = db.session.get(Group, group_id)
    if not group:
        return jsonify({"message": "Group not found"}), 404


    subjects = db.session.query(Activity,Subject).join(Subject, Activity.activity_id==Subject.activity_id).filter(Subject.group_id==group_id).all()

    if not subjects:
        return jsonify({"message": "No subjects found for this group"}), 404

    subject_list = [{
        "activity_id": activity.activity_id,
        "name": activity.name,
        "description": activity.description,
        "difficulty": activity.difficulty,
        "priority": activity.priority,
        "curriculum": subject.curriculum,
        "professor": subject.professor
    } for activity, subject in subjects]


    return jsonify({
        "group_id": group_id,
        "subjects": subject_list
    }), 200


