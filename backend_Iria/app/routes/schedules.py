#rutas de gestion de horarios
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
"""DEPENDE DE LA BD"""
#from app.models import db, Schedule

schedule_bp = Blueprint('schedule', __name__)

@schedule_bp.route('/schedule', methods=['GET'])
@jwt_required()
def get_schedule():
    user_id = get_jwt_identity()
    """schedule = Schedule.query.filter_by(user_id=user_id).all()
    return jsonify([{
        "id": s.id,
        "subject": s.subject,
        "start_time": str(s.start_time),
        "end_time": str(s.end_time),
        "day_of_week": s.day_of_week
    } for s in schedule]), 200"""

@schedule_bp.route('/schedule', methods=['POST'])
@jwt_required()
def add_schedule():
    data = request.json
    user_id = get_jwt_identity()
    """new_schedule = Schedule(
        user_id=user_id,
        subject=data['subject'],
        start_time=data['start_time'],
        end_time=data['end_time'],
        day_of_week=data['day_of_week']
    )
    db.session.add(new_schedule)
    db.session.commit()"""
    return jsonify({"message": "Horario añadido"}), 201
