#rutas de tareas y tests
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
"""DEPENDEN DE LA BD"""
#from app.models import db, Task

tasks_bp = Blueprint('tasks', __name__)

@tasks_bp.route('/tasks', methods=['GET'])
@jwt_required()
def get_tasks():
    user_id = get_jwt_identity()
    """tasks = Task.query.filter_by(user_id=user_id).all()
    return jsonify([{
        "id": t.id,
        "title": t.title,
        "due_date": str(t.due_date),
        "completed": t.completed
    } for t in tasks]), 200"""

@tasks_bp.route('/tasks', methods=['POST'])
@jwt_required()
def add_task():
    data = request.json
    user_id = get_jwt_identity()
    """new_task = Task(
        user_id=user_id,
        title=data['title'],
        due_date=data['due_date'],
        completed=False
    )
    db.session.add(new_task)
    db.session.commit()"""
    return jsonify({"message": "Tarea añadida"}), 201
