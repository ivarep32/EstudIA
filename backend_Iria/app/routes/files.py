from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from flasgger import swag_from
"""DEPENDEN DE LA BD"""
from app.models import db, File, Subject, Participation

files_bp = Blueprint('activities', __name__)

@files_bp.route('/files/<int:subject_id>', methods=['GET'])
def get_files(subject_id):
    user_id = get_jwt_identity()
    
    # Comprobar que o usuario participe nalgún dos grupos que ten a asignatura.
    if not Subject.query.filter_by(activity_id=subject_id).join(Participation, Subject.group_id == Participation.group_id).\
        filter_by(user_id=user_id).first():
        return jsonify({"message": "Can not download a file from a subject the user is not taking"}), 401

    files = File.query.filter_by(subject_id=subject_id).all()
    file_list = [{"id": file.file_id, "filename": file.filename} for file in files]

    return jsonify(file_list)