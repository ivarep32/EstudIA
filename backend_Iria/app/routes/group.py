#archivo rutas de gestion de horarios
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
"""DEPENDE DE LA BD"""
from models import db, GroupAdmin, Participation, Schedule, Activity, Subject, UserActivity, TimeSlot, Event, GroupEvent, Group

group_bp = Blueprint('group', __name__)


@group_bp.route('/schedule/<int:group_id>', methods=['POST'])
@jwt_required()
def add_group_schedule(group_id):
    user_id = get_jwt_identity()

    if not GroupAdmin.query.filter_by(user_id=user_id, group_id=group_id).first():
        return jsonify({"message": "Admin access required"}), 403

    data = request.get_json()

    if not data or 'name' not in data:
        return jsonify({"message": "Invalid JSON format"}), 400

    new_schedule = Schedule(
        name=data['name'],
        group_id=group_id
    )
    db.session.add(new_schedule)
    db.session.commit()
    
    return jsonify({"message": "Horario añadido"}), 201

@group_bp.route('/schedules/<int:group_id>', methods=['GET'])
@jwt_required()
def get_group_schedules(group_id):
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
        "name": schedule.name,
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