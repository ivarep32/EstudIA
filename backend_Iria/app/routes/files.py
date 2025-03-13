from flask import Blueprint, request, jsonify, send_file
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
import os
from flasgger import swag_from
"""DEPENDEN DE LA BD"""
from app.models import db, File, Participation

files_bp = Blueprint('files', __name__)

UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)  # Ensure upload folder exists

@files_bp.route('/files/<int:group_id>', methods=['GET'])
@swag_from({
    'tags': ['Files'],
    'summary': 'Ver los archivos del grupo',
    'description': 'Devuelve la lista de archivos del grupo',
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
        'in': 'path',
        'required': True,
        'type': 'integer',
        'description': 'Identificador del grupo',

    }
    ],
    'responses': {
        200:{
            'description': 'Lista de archivos del grupo',
            'schema': {
                'type': 'array',
                'items':{
                    'type': 'object',
                    'properties': {
                        'id':{'type':'integer','example':1},
                        'filename':{'type':'string','example':'file.txt'},

                    }
                }
            }
        },
        401: {'description': 'el usuario no pertenece al grupo'}
    }
})
@jwt_required()
def get_files(group_id):    
    user_id = get_jwt_identity()
    
    # Comprobar que o usuario participe no grupo.
    if not Participation.query.filter_by(group_id=group_id, user_id=user_id).first():
        return jsonify({"message": "Can not get the file from a group the user is not in"}), 401

    files = File.query.filter_by(group_id=group_id).all()
    file_list = [{"id": file.file_id, "filename": file.filename} for file in files]

    return jsonify(file_list), 200


@files_bp.route('/upload/<int:group_id>', methods=['POST'])
@swag_from({
    'tags': ['Files'],
    'summary': 'Upload a file',
    'description': 'Uploads a file and stores it in a group-specific folder.',
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
        {'name': 'file', 'in': 'formData', 'type': 'file', 'required': True, 'description': 'File to upload'}
    ],
    'responses': {
        200: {'description': 'File uploaded successfully'},
        400: {'description': 'No file provided'},
        401: {'description': 'The user has no access to the group'}
    }
})
@jwt_required()
def upload_file(group_id):
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400

    group_folder = os.path.join(UPLOAD_FOLDER, f"/{group_id}")
    if not os.path.exists(group_folder):
        os.makedirs(group_folder)  # Ensure upload folder exists
    
    user_id = get_jwt_identity()
    
    # Comprobar que o usuario participe no grupo.
    if not Participation.query.filter_by(group_id=group_id, user_id=user_id).first():
        return jsonify({"error": "Can not upload a file to a group the user is not in"}), 401
    
    file = request.files['file']
    if file:
        filename = secure_filename(file.filename)
        file_path = os.path.join(group_folder, filename)
        file.save(file_path)

        new_file = File(filename=file.filename, file_path=file_path, group_id=group_id)
        db.session.add(new_file)
        db.session.commit()
        
        return jsonify({"message": "File uploaded successfully!", "file_id": new_file.file_id}), 200

@files_bp.route('/file/<int:file_id>', methods=['GET'])
@swag_from({
    'tags': ['Files'],
    'summary': 'Download a file',
    'description': 'Downloads a file and stores it in a group-specific folder.',
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
            'name': 'file_id',
            'in': 'path',
            'type': 'integer',
            'required': True,
            'description': 'ID of the file to download'
         }
    ],
    'responses': {
        200:{
            'description': 'El archivo se descarga correctamente',
            'schema': {
                'type': 'file'
            }
        },
        401: {'description': 'El usuario no pertenece al grupo'},
        404: {'description': 'Archivo no encontrado'}
    }

})
@jwt_required()
def download_file(file_id):
    user_id = get_jwt_identity()
    
    # Comprobar que o usuario participe no grupo.
    has_access = db.session.query(Participation).join(File, File.group_id == Participation.group_id)\
        .filter(File.file_id == file_id, Participation.user_id == user_id).first()
    
    if not has_access:
        return jsonify({"message": "Can not upload a file to a group the user is not in"}), 401
    
    file = File.query.get(file_id)
    
    if file:
        return send_file(file.file_path, as_attachment=True, download_name=file.filename), 200
    
    return jsonify({"error": "File not found"}), 404



@files_bp.route('/file/<int:file_id>', methods=['DELETE'])
@swag_from({
    'tags': ['Files'],
    'summary': 'Remove a file',
    'description': 'Removes an specific file.',
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
        {'name': 'file_id', 'in': 'path', 'type': 'integer', 'required': True, 'description': 'ID of the file'}
    ],
    'responses': {
        200: {'description': 'File removed successfully'},
        401: {'description': 'The user has no access to the group'},
        404: {'description': 'File not found'}
    }
})
@jwt_required()
def remove_file(file_id):
    user_id = get_jwt_identity()
    
    has_access = db.session.query(Participation).join(File, File.group_id == Participation.group_id)\
        .filter(File.file_id == file_id, Participation.user_id == user_id).first()
    
    if not has_access:
        return jsonify({"message": "Can not upload a file to a group the user is not in"}), 401

    file_entry = File.query.get(file_id)
    if not file_entry:
        return jsonify({"error": "File not found"}), 404
    
    file_path = file_entry.file_path  # Get the file path

    # Check if file exists in the filesystem
    if os.path.exists(file_path):
        os.remove(file_path)
    
    # Remove the file entry from the database
    db.session.delete(file_entry)
    db.session.commit()

    return jsonify({"message": "File deleted successfully"}), 200