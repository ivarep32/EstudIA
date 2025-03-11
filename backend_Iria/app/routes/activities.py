#archivo rutas de tareas y tests
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
"""DEPENDEN DE LA BD"""
from app.models import db, Activity

activities_bp = Blueprint('activities', __name__)

@activities_bp.route('/activities', methods=['GET'])
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
