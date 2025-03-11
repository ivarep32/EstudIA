#archivo de ejecucion principal
from app import create_app
from app.routes.auth import auth_bp
from app.routes.schedules import schedule_bp

app = create_app()
app.register_blueprint(auth_bp, url_prefix="/auth")
app.register_blueprint(schedule_bp, url_prefix="/api")

if __name__ == "__main__":
    app.run(debug=True)
