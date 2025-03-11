# rutas de notificaciones
from flask import Blueprint, jsonify

notifications_bp = Blueprint('notifications', __name__)

@notifications_bp.route('/notifications', methods=['GET'])
def get_notifications():
    return jsonify([
        {"message": "Recordatorio: Tienes una entrega mañana"},
        {"message": "Nueva clase añadida a tu horario"}
    ])
