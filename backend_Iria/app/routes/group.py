#archivo rutas de gestion de horarios
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
"""DEPENDE DE LA BD"""
from models import db, GroupAdmin, Participation, Schedule, Activity, Subject, UserActivity, TimeSlot, Event, GroupEvent, Group

group_bp = Blueprint('group', __name__)


@group_bp.route('/<int:group_id>/schedule', methods=['POST'])
@jwt_required()
def add_group_schedule(group_id):
    user_id = get_jwt_identity()
    
    if not GroupAdmin.query.filter_by(user_id=user_id, group_id=group_id).first():
        return jsonify({"message": "Admin access required"}), 403
    
    data = request.json
    
    new_schedule = Schedule(
        name=data['name'],
        group_id=group_id,
    )
    db.session.add(new_schedule)
    db.session.commit()
    
    return jsonify({"message": "Horario añadido"}), 201

@group_bp.route('/<int:group_id>/schedules', methods=['GET'])
@jwt_required()
def get_group_schedules(group_id):
    user_id = get_jwt_identity()
    if not Participation.query.filter_by(user_id=user_id, group_id=group_id).first():
        return jsonify({"message": "Group access required"}), 403
    
    schedule = Schedule.query.filter_by(group_id=group_id).first()
    if not schedule:
        return jsonify({"message": "No schedule found for this group"}), 404

    q = Activity.query.join(TimeSlot.query.filter_by(TimeSlot.schedule_id == schedule.id))
    schedule_subjects = q.join(Subject).all()
    schedule_user_activities = q.join(UserActivity).all()
    schedule_data = {
        "id": schedule.id,
        "name": schedule.name,
        "subjects": [
            {
                "id": sa.id,
                "name": sa.name,
                "difficulty": sa.difficulty,
                "priority": sa.difficulty,

                "day_of_week": sa.timeslot.day_of_week,
                "start_time": sa.timeslot.start_time.isoformat(),
                "end_time": sa.timeslot.end_time.isoformat(),

                "curriculum": sa.curriculum,
                "professor": sa.professor

            } for sa in schedule_subjects
        ],
        "user_activities": [
            {
                "id": sa.id,
                "name": sa.name,
                "difficulty": sa.difficulty,
                "priority": sa.difficulty,

                "day_of_week": sa.timeslot.day_of_week,
                "start_time": sa.timeslot.start_time.isoformat(),
                "end_time": sa.timeslot.end_time.isoformat(),
            } for sa in schedule_user_activities
        ]
    }
    return jsonify(schedule_data), 200