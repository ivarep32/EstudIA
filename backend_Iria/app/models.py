from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt

db = SQLAlchemy()
bcrypt = Bcrypt()

# --- User Table ---
class User(db.Model):
    __tablename__ = "user"
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(100), unique=True, nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)

    def set_password(self, password):
        self.password = bcrypt.generate_password_hash(password).decode('utf-8')

    def check_password(self, password):
        return bcrypt.check_password_hash(self.password, password)
    
# --- Group Table ---
class Group(db.Model):
    __tablename__ = "group"
    id = db.Column(db.Integer, primary_key=True)
    supergroup_id = db.Column(db.Integer, db.ForeignKey("group.id"), nullable=True)  # Self-referencing foreign key

# --- Course Table ---
class Course(db.Model):
    __tablename__ = "course"
    id = db.Column(db.Integer, db.ForeignKey("group.id"), primary_key=True)  # Course is a specialized group

# --- Participation Table ---
class Participation(db.Model):
    __tablename__ = "participation"
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    group_id = db.Column(db.Integer, db.ForeignKey("group.id"), nullable=False)
    __table_args__ = (
        db.PrimaryKeyConstraint("user_id", "group_id"),
    )

# --- Group Admin Table ---
class GroupAdmin(db.Model):
    __tablename__ = "group_admin"
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    group_id = db.Column(db.Integer, db.ForeignKey("group.id"), nullable=False)
    __table_args__ = (
        db.PrimaryKeyConstraint("user_id", "group_id"),
    )

# --- Activity Table ---
class Activity(db.Model):
    __tablename__ = "activity"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.Text, nullable=False)
    description = db.Column(db.Text, nullable=True)
    difficulty = db.Column(db.Integer, nullable=False)
    priority = db.Column(db.Integer, nullable=False)

# --- Subject Table ---
class Subject(db.Model):
    __tablename__ = "subject"
    id = db.Column(db.Integer, db.ForeignKey("activity.id"), primary_key=True)  # Subject is an Activity
    course_id = db.Column(db.Integer, db.ForeignKey("course.id"), nullable=False)
    curriculum = db.Column(db.Text, nullable=False)
    professor = db.Column(db.String(100), nullable=False)

# --- User Activity Table ---
class UserActivity(db.Model):
    __tablename__ = "user_activity"
    id = db.Column(db.Integer, db.ForeignKey("activity.id"), primary_key=True)  # UserActivity is an Activity
    hours = db.Column(db.Integer, nullable=False) # How many hours
    period = db.Column(db.String(50), nullable=False) # Every how much (day, week, month)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    subject_id = db.Column(db.Integer, db.ForeignKey("subject.id"), nullable=False)

# --- Schedule Table ---
class Schedule(db.Model):
    __tablename__ = "schedule"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    group_id = db.Column(db.Integer, db.ForeignKey("group.id"), unique=True, nullable=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), unique=True, nullable=True)

    __table_args__ = (
        db.CheckConstraint("(group_id IS NULL) != (user_id IS NULL)", name="only_one_user_or_group"),
    )

# --- Timeslot Table ---
class TimeSlot(db.Model):
    __tablename__ = "time_slot"
    schedule_id = db.Column(db.Integer, db.ForeignKey("schedule.id"))
    day_of_week = db.Column(db.String(20), nullable=False)
    start_time = db.Column(db.Time, nullable=False)
    end_time = db.Column(db.Time, nullable=False)
    activity_id = db.Column(db.Integer, db.ForeignKey("activity.id"), nullable=False)
    __table_args__ = (
        db.PrimaryKeyConstraint("schedule_id", "day_of_week", "start_time"),
    )

# --- User Activity Log ---
class ActivityLog(db.Model):
    __tablename__ = "activity_log"
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    activity_id = db.Column(db.Integer, db.ForeignKey("user_activity.id"), nullable=False)
    start_time = db.Column(db.DateTime, nullable=False)
    end_time = db.Column(db.DateTime, nullable=False)
    __table_args__ = (
        db.PrimaryKeyConstraint("user_id", "start_time"), # Only one activity for a user at a start time
    )

# --- Event Table ---
class Event(db.Model):
    __tablename__ = "event"
    id = db.Column(db.Integer, primary_key=True)
    start_time = db.Column(db.DateTime, nullable=False)
    end_time = db.Column(db.DateTime, nullable=False)
    type = db.Column(db.String(50), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)

# --- Group Event Relationship ---
class GroupEvent(db.Model):
    __tablename__ = "group_event"
    group_id = db.Column(db.Integer, db.ForeignKey("group.id"), nullable=False)
    event_id = db.Column(db.Integer, db.ForeignKey("event.id"), nullable=False)
    __table_args__ = (
        db.PrimaryKeyConstraint("group_id", "event_id"),
    )

# --- User Event Relationship ---
class UserEvent(db.Model):
    __tablename__ = "user_event"
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    event_id = db.Column(db.Integer, db.ForeignKey("event.id"), nullable=False)
    completed = db.Column(db.Boolean, default=False)
    __table_args__ = (
        db.PrimaryKeyConstraint("user_id", "event_id"),
    )
