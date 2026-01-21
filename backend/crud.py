from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
import models, schemas
from datetime import datetime, timedelta, date

# --- FINANCE ---
def get_finance_categories(db: Session, owner_id: int):
    return db.query(models.FinanceCategory).filter(models.FinanceCategory.owner_id == owner_id).all()

def create_finance_category(db: Session, category: schemas.FinanceCategoryCreate, owner_id: int):
    db_category = models.FinanceCategory(**category.model_dump(), owner_id=owner_id)
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category

def get_finances(db: Session, owner_id: int, skip: int = 0, limit: int = 100):
    return db.query(models.Finance).options(joinedload(models.Finance.category)).filter(models.Finance.owner_id == owner_id).offset(skip).limit(limit).all()

def create_finance(db: Session, finance: schemas.FinanceCreate, owner_id: int):
    # ... (existing content)
    db_finance = models.Finance(**finance.model_dump(), owner_id=owner_id)
    db.add(db_finance)
    db.commit()
    db.refresh(db_finance)
    
    # Update User Balance
    user = db.query(models.User).filter(models.User.id == owner_id).first()
    if user:
        if finance.type == "expense":
            user.balance -= finance.amount
        elif finance.type in ["active_income", "passive_income"]:
            user.balance += finance.amount
        db.commit()
        
    return db_finance

def update_finance(db: Session, finance_id: int, finance_update: schemas.FinanceCreate):
    db_finance = db.query(models.Finance).filter(models.Finance.id == finance_id).first()
    if db_finance:
        # Revert old balance logic if needed (complex), for now just update fields
        # Ideally, we should rollback old amount and apply new amount to user balance
        old_amount = db_finance.amount
        old_type = db_finance.type

        for key, value in finance_update.model_dump().items():
            setattr(db_finance, key, value)
        
        # Simple balance correction logic
        user = db.query(models.User).filter(models.User.id == db_finance.owner_id).first()
        if user:
            # Revert old
            if old_type == "expense": user.balance += old_amount
            else: user.balance -= old_amount
            
            # Apply new
            if finance_update.type == "expense": user.balance -= finance_update.amount
            else: user.balance += finance_update.amount
            
        db.commit()
        db.refresh(db_finance)
    return db_finance

def get_balance(db: Session, owner_id: int):
    user = db.query(models.User).filter(models.User.id == owner_id).first()
    if user:
        return user.balance
    return 0

def get_monthly_stats(db: Session, owner_id: int):
    # Fetch all finances for the user
    # Note: For production with large datasets, do aggregation in SQL using func.strftime
    finances = db.query(models.Finance).filter(models.Finance.owner_id == owner_id).all()
    
    stats = {} # "YYYY-MM" -> {"income": 0, "expense": 0}
    
    for f in finances:
        month_key = f.date.strftime("%Y-%m")
        if month_key not in stats:
            stats[month_key] = {"income": 0, "expense": 0}
            
        if f.type == "expense":
            stats[month_key]["expense"] += f.amount
        elif f.type in ["active_income", "passive_income"]:
            stats[month_key]["income"] += f.amount
            
    # Convert to list
    result = []
    # Sort keys to be chronological
    for key in sorted(stats.keys()):
        result.append(schemas.MonthlyStat(
            month=key,
            total_income=stats[key]["income"],
            total_expense=stats[key]["expense"]
        ))
        
    return result

def get_daily_stats(db: Session, owner_id: int):
    today = datetime.now().date()
    # Simple Python filtering for MVP (assuming small dataset)
    finances = db.query(models.Finance).filter(models.Finance.owner_id == owner_id).all()
    
    income = 0.0
    expense = 0.0
    
    for f in finances:
        if f.date.date() == today:
            if f.type == "expense":
                expense += f.amount
            elif f.type in ["active_income", "passive_income"]:
                income += f.amount
                
    return schemas.DailyStat(
        date=str(today),
        total_income=income,
        total_expense=expense
    )

# --- WORK ---
def get_today_work_status(db: Session, owner_id: int) -> schemas.WorkStatus:
    today = datetime.now().date()
    # Filter by date string matching
    works = db.query(models.Work).filter(
        models.Work.owner_id == owner_id,
        func.date(models.Work.date) == str(today)
    ).all()
    
    active = any(w.type == "active" for w in works)
    passive = any(w.type == "passive" for w in works)
    is_saved = len(works) > 0
    
    return schemas.WorkStatus(active=active, passive=passive, is_saved=is_saved)

def update_today_work_status(db: Session, owner_id: int, status: schemas.WorkStatus):
    today = datetime.now()
    today_str = str(today.date())
    
    # Get existing
    works = db.query(models.Work).filter(
        models.Work.owner_id == owner_id,
        func.date(models.Work.date) == today_str
    ).all()
    
    existing_active = next((w for w in works if w.type == "active"), None)
    existing_passive = next((w for w in works if w.type == "passive"), None)
    
    # Handle Active
    if status.active and not existing_active:
        db.add(models.Work(type="active", date=today, owner_id=owner_id, is_completed=True))
    elif not status.active and existing_active:
        db.delete(existing_active)
        
    # Handle Passive
    if status.passive and not existing_passive:
        db.add(models.Work(type="passive", date=today, owner_id=owner_id, is_completed=True))
    elif not status.passive and existing_passive:
        db.delete(existing_passive)
        
    db.commit()
    return get_today_work_status(db, owner_id)

# --- HEALTH ---
def get_exercise_types(db: Session, owner_id: int):
    return db.query(models.ExerciseType).filter(models.ExerciseType.owner_id == owner_id).all()

def create_exercise_type(db: Session, exercise: schemas.ExerciseTypeCreate, owner_id: int):
    db_exercise = models.ExerciseType(**exercise.model_dump(), owner_id=owner_id)
    db.add(db_exercise)
    db.commit()
    db.refresh(db_exercise)
    return db_exercise

def get_sport_logs(db: Session, owner_id: int, date: date = None):
    today_str = str(date) if date else None
    
    # Base query
    query = db.query(models.SportLog).options(joinedload(models.SportLog.exercise_type)).filter(models.SportLog.owner_id == owner_id)
    
    if date:
        today = date
        # Filter query by date as well
        query = query.filter(func.date(models.SportLog.date) == today_str)
        
        # Get all ExerciseType for Today
        exercise_types = db.query(models.ExerciseType).filter(models.ExerciseType.owner_id == owner_id).all()
        
        # create sport log for each exercise type if not exists
        for exercise_type in exercise_types:
            # Check using func.date to match day regardless of time
            exists = db.query(models.SportLog).filter(
                models.SportLog.owner_id == owner_id, 
                models.SportLog.exercise_type_id == exercise_type.id, 
                func.date(models.SportLog.date) == today_str
            ).first()
            
            if not exists:
                db.add(models.SportLog(exercise_type_id=exercise_type.id, date=today, owner_id=owner_id))
        db.commit()
    
    return query.all()

def create_sport_log(db: Session, log: schemas.SportLogCreate, owner_id: int):
    db_log = models.SportLog(**log.model_dump(), owner_id=owner_id)
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log

def update_exercise_type(db: Session, type_id: int, type_update: schemas.ExerciseTypeCreate):
    db_type = db.query(models.ExerciseType).filter(models.ExerciseType.id == type_id).first()
    if db_type:
        for key, value in type_update.model_dump().items():
            setattr(db_type, key, value)
        db.commit()
        db.refresh(db_type)
    return db_type

def update_sport_log(db: Session, log_id: int, log_update: schemas.SportLogCreate):
    db_log = db.query(models.SportLog).filter(models.SportLog.id == log_id).first()
    if db_log:
        for key, value in log_update.model_dump().items():
            setattr(db_log, key, value)
        db.commit()
        db.refresh(db_log)
    return db_log

def update_sport_log_status(db: Session, log_id: int, is_completed: bool):
    log = db.query(models.SportLog).filter(models.SportLog.id == log_id).first()
    if log:
        log.is_completed = is_completed
        db.commit()
        db.refresh(log)
    return log

def get_sport_logs_history(db: Session, owner_id: int, limit: int = 100):
    return db.query(models.SportLog).options(joinedload(models.SportLog.exercise_type))\
             .filter(models.SportLog.owner_id == owner_id)\
             .order_by(models.SportLog.date.desc())\
             .limit(limit).all()

def get_last_sleep_log(db: Session, owner_id: int):
    return db.query(models.SleepLog).filter(
        models.SleepLog.owner_id == owner_id
    ).order_by(models.SleepLog.id.desc()).first()

def check_and_fix_sleep_status(db: Session, owner_id: int):
    last_log = get_last_sleep_log(db, owner_id)
    if last_log and last_log.start_time and not last_log.end_time:
        # Currently sleeping
        now = datetime.now()
        duration = now - last_log.start_time
        if duration.total_seconds() > 11 * 3600:
            # Exceeded 11 hours -> Auto wake up
            last_log.end_time = last_log.start_time + timedelta(hours=11)
            db.commit()
            db.refresh(last_log)
    return last_log

def get_sleep_log(db: Session, owner_id: int, date: datetime):
    # Returns the latest sleep status object
    return check_and_fix_sleep_status(db, owner_id)

def get_daily_habit(db: Session, owner_id: int, date: datetime):
    # Daily habits are day-specific, keyed by date
    return db.query(models.DailyHabit).filter(
        models.DailyHabit.owner_id == owner_id, 
        func.date(models.DailyHabit.date) == str(date.date())
    ).first()

def wake_up_user(db: Session, owner_id: int):
    now = datetime.now()
    
    # 1. Close sleep session (Wake Up / Cancel Sleep)
    last_log = check_and_fix_sleep_status(db, owner_id)
    if last_log and not last_log.end_time:
        last_log.end_time = now
        db.commit()
        db.refresh(last_log)
    
    # 2. Start Day (Create Daily Habit)
    today_habit = get_daily_habit(db, owner_id, now)
    if not today_habit:
        today_habit = models.DailyHabit(date=now, owner_id=owner_id)
        db.add(today_habit)
        db.commit()
    
    return last_log if last_log else None

def sleep_user(db: Session, owner_id: int):
    now = datetime.now()
    
    # Check if already sleeping
    last_log = check_and_fix_sleep_status(db, owner_id)
    if last_log and not last_log.end_time:
        return last_log # Already sleeping
        
    # Start new sleep session
    new_log = models.SleepLog(
        start_time=now,
        owner_id=owner_id
    )
    db.add(new_log)
    db.commit()
    db.refresh(new_log)
    return new_log

def update_daily_habit(db: Session, habit: schemas.DailyHabitCreate, owner_id: int):
    today = datetime.now()
    db_habit = get_daily_habit(db, owner_id, today)
    if db_habit:
        for key, value in habit.model_dump(exclude_unset=True).items():
            setattr(db_habit, key, value)
        db.commit()
        db.refresh(db_habit)
        return db_habit
    else:
        # Create if not exists
        db_habit = models.DailyHabit(**habit.model_dump(), owner_id=owner_id)
        db.add(db_habit)
        db.commit()
        db.refresh(db_habit)
        return db_habit

def get_daily_habits(db: Session, owner_id: int, limit: int = 30):
    return db.query(models.DailyHabit).filter(models.DailyHabit.owner_id == owner_id).order_by(models.DailyHabit.date.desc()).limit(limit).all()

def get_sleep_logs_history(db: Session, owner_id: int, limit: int = 30):
    return db.query(models.SleepLog).filter(models.SleepLog.owner_id == owner_id).order_by(models.SleepLog.start_time.desc()).limit(limit).all()

# --- MIND ---
def get_mind_task_types(db: Session, owner_id: int):
    return db.query(models.MindTaskType).filter(models.MindTaskType.owner_id == owner_id).all()

def create_mind_task_type(db: Session, task: schemas.MindTaskTypeCreate, owner_id: int):
    db_task = models.MindTaskType(**task.model_dump(), owner_id=owner_id)
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    db.refresh(db_task)
    return db_task

def update_mind_task_type(db: Session, type_id: int, type_update: schemas.MindTaskTypeCreate):
    db_type = db.query(models.MindTaskType).filter(models.MindTaskType.id == type_id).first()
    if db_type:
        for key, value in type_update.model_dump().items():
            setattr(db_type, key, value)
        db.commit()
        db.refresh(db_type)
    return db_type

def get_mind_logs(db: Session, owner_id: int):
    return db.query(models.MindLog).options(joinedload(models.MindLog.task_type)).filter(models.MindLog.owner_id == owner_id).all()

def create_mind_log(db: Session, log: schemas.MindLogCreate, owner_id: int):
    db_log = models.MindLog(**log.model_dump(), owner_id=owner_id)
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log

def update_mind_log(db: Session, log_id: int, log_update: schemas.MindLogCreate):
    db_log = db.query(models.MindLog).filter(models.MindLog.id == log_id).first()
    if db_log:
        for key, value in log_update.model_dump().items():
            setattr(db_log, key, value)
        db.commit()
        db.refresh(db_log)
    return db_log

def update_mind_log_status(db: Session, log_id: int, is_completed: bool):
    log = db.query(models.MindLog).filter(models.MindLog.id == log_id).first()
    if log:
        log.is_completed = is_completed
        db.commit()
        db.refresh(log)
    return log

def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

def create_user(db: Session, user: schemas.UserCreate):
    fake_hashed_password = user.password + "notreallyhashed"
    db_user = models.User(username=user.username, full_name=user.full_name, balance=0) # Password logic omitted for simplicity
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_user(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.id == user_id).first()
