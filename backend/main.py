from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional
import models, database, schemas, crud
from datetime import date, datetime

models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="DayPlan API")

# Allow CORS for all origins (Development only)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Also allow all for simplicity in dev
    allow_origin_regex="https?://localhost.*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Temporary Hardcoded User ID for MVP
MOCK_USER_ID = 1

@app.on_event("startup")
def startup_event():
    # Create mock user if not exists
    db = database.SessionLocal()
    try:
        user = crud.get_user(db, MOCK_USER_ID)
        if not user:
            print("Creating Mock User...")
            mock_user = schemas.UserCreate(
                username="mockuser", 
                full_name="Test User", 
                password="password"
            )
            crud.create_user(db, mock_user)
            print("Mock User Created with ID 1")
        
        # Seed Default Categories if empty
        categories = crud.get_finance_categories(db, MOCK_USER_ID)
        if not categories:
            print("Seeding default categories...")
            defaults = [
                schemas.FinanceCategoryCreate(name="Oziq-ovqat", type="expense"),
                schemas.FinanceCategoryCreate(name="Transport", type="expense"),
                schemas.FinanceCategoryCreate(name="Kommunal", type="expense"),
                schemas.FinanceCategoryCreate(name="Maosh", type="active_income"),
                schemas.FinanceCategoryCreate(name="Freelance", type="active_income"),
                schemas.FinanceCategoryCreate(name="Investitsiya", type="passive_income"),
            ]
            for cat in defaults:
                crud.create_finance_category(db, cat, MOCK_USER_ID)
            print("Default categories seeded.")
    except Exception as e:
        print(f"Startup error: {e}")
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"message": "Welcome to DayPlan API! 3 parts: Pul, Sog'lik, Aql"}

# --- USERS ---
@app.post("/users/", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    return crud.create_user(db=db, user=user)

@app.get("/users/{user_id}", response_model=schemas.User)
def read_user(user_id: int, db: Session = Depends(get_db)):
    db_user = crud.get_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

# --- FINANCE ---
@app.get("/finance/categories/", response_model=List[schemas.FinanceCategory])
def read_finance_categories(db: Session = Depends(get_db)):
    # Using mock user
    return crud.get_finance_categories(db, owner_id=MOCK_USER_ID)

@app.post("/finance/categories/", response_model=schemas.FinanceCategory)
def create_finance_category(category: schemas.FinanceCategoryCreate, db: Session = Depends(get_db)):
    return crud.create_finance_category(db=db, category=category, owner_id=MOCK_USER_ID)

@app.get("/finance/", response_model=List[schemas.Finance])
def read_finances(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_finances(db, owner_id=MOCK_USER_ID, skip=skip, limit=limit)

@app.post("/finance/", response_model=schemas.Finance)
def create_finance(finance: schemas.FinanceCreate, db: Session = Depends(get_db)):
    return crud.create_finance(db=db, finance=finance, owner_id=MOCK_USER_ID)

@app.put("/finance/{finance_id}", response_model=schemas.Finance)
def update_finance(finance_id: int, finance: schemas.FinanceCreate, db: Session = Depends(get_db)):
    db_finance = crud.update_finance(db, finance_id, finance)
    if not db_finance:
        raise HTTPException(status_code=404, detail="Finance record not found")
    return db_finance

@app.get("/finance/balance")
def read_balance(db: Session = Depends(get_db)):
    balance = crud.get_balance(db, owner_id=MOCK_USER_ID)
    return {"balance": balance}

@app.get("/finance/stats/monthly", response_model=List[schemas.MonthlyStat])
def read_monthly_stats(db: Session = Depends(get_db)):
    return crud.get_monthly_stats(db, owner_id=MOCK_USER_ID)

@app.get("/finance/stats/daily", response_model=schemas.DailyStat)
def read_daily_stats(db: Session = Depends(get_db)):
    return crud.get_daily_stats(db, owner_id=MOCK_USER_ID)

# --- WORK ---
@app.get("/work/today", response_model=schemas.WorkStatus)
def read_work_today(db: Session = Depends(get_db)):
    return crud.get_today_work_status(db, owner_id=MOCK_USER_ID)

@app.put("/work/today", response_model=schemas.WorkStatus)
def update_work_today(status: schemas.WorkStatus, db: Session = Depends(get_db)):
    return crud.update_today_work_status(db, owner_id=MOCK_USER_ID, status=status)

# --- HEALTH ENDPOINTS ---
@app.get("/health/exercise-types/", response_model=List[schemas.ExerciseType])
def read_exercise_types(db: Session = Depends(get_db)):
    return crud.get_exercise_types(db, owner_id=MOCK_USER_ID)

@app.post("/health/exercise-types/", response_model=schemas.ExerciseType)
def create_exercise_type(exercise: schemas.ExerciseTypeCreate, db: Session = Depends(get_db)):
    return crud.create_exercise_type(db=db, exercise=exercise, owner_id=MOCK_USER_ID)

@app.put("/health/exercise-types/{type_id}", response_model=schemas.ExerciseType)
def update_exercise_type(type_id: int, exercise: schemas.ExerciseTypeCreate, db: Session = Depends(get_db)):
    db_type = crud.update_exercise_type(db, type_id, exercise)
    if not db_type:
        raise HTTPException(status_code=404, detail="Exercise type not found")
    return db_type

@app.get("/health/sport-logs/", response_model=List[schemas.SportLog])
def read_sport_logs(db: Session = Depends(get_db)):
    # Optional date filter could be added as query param
    today = datetime.now().date()
    return crud.get_sport_logs(db, owner_id=MOCK_USER_ID, date=today)

@app.post("/health/sport-logs/", response_model=schemas.SportLog)
def create_sport_log(log: schemas.SportLogCreate, db: Session = Depends(get_db)):
    return crud.create_sport_log(db=db, log=log, owner_id=MOCK_USER_ID)

@app.put("/health/sport-logs/{log_id}", response_model=schemas.SportLog)
def update_sport_log(log_id: int, log: schemas.SportLogCreate, db: Session = Depends(get_db)):
    db_log = crud.update_sport_log(db, log_id, log)
    if not db_log:
        raise HTTPException(status_code=404, detail="Sport log not found")
    return db_log

@app.put("/health/sport-logs/{log_id}/status")
def update_sport_log_status(log_id: int, is_completed: bool, db: Session = Depends(get_db)):
    log = crud.update_sport_log_status(db, log_id, is_completed)
    if not log:
        raise HTTPException(status_code=404, detail="Sport log not found")
    return {"status": "success", "is_completed": log.is_completed}

@app.get("/health/sleep/today", response_model=Optional[schemas.SleepLog])
def get_sleep_log_today(db: Session = Depends(get_db)):
    from datetime import datetime
    today = datetime.now()
    # This now returns the latest status log
    # This now returns the latest status log
    return crud.get_sleep_log(db, owner_id=MOCK_USER_ID, date=today)

@app.get("/health/sport-logs-history", response_model=List[schemas.SportLog])
def get_sport_logs_history(limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_sport_logs_history(db, owner_id=MOCK_USER_ID, limit=limit)

@app.get("/health/habits/today", response_model=schemas.DailyHabit)
def get_daily_habit_today(db: Session = Depends(get_db)):
    from datetime import datetime
    today = datetime.now()
    habit = crud.get_daily_habit(db, owner_id=MOCK_USER_ID, date=today)
    if not habit:
        raise HTTPException(status_code=404, detail="No daily habit record found")
    return habit

@app.post("/health/sleep/wake-up", response_model=Optional[schemas.SleepLog])
def wake_up(db: Session = Depends(get_db)):
    # Returns updated (closed) sleep log, or None if just started day without sleep
    return crud.wake_up_user(db, owner_id=MOCK_USER_ID)

@app.post("/health/sleep/sleep", response_model=schemas.SleepLog)
def sleep_user(db: Session = Depends(get_db)):
    log = crud.sleep_user(db, owner_id=MOCK_USER_ID)
    return log

@app.post("/health/habits/", response_model=schemas.DailyHabit)
def update_daily_habit(habit: schemas.DailyHabitCreate, db: Session = Depends(get_db)):
    # This acts as create_or_update
    return crud.update_daily_habit(db, habit, owner_id=MOCK_USER_ID)

@app.get("/health/daily-habits-history", response_model=List[schemas.DailyHabit])
def get_daily_habits_history(limit: int = 30, db: Session = Depends(get_db)):
    return crud.get_daily_habits(db, owner_id=MOCK_USER_ID, limit=limit)

@app.get("/health/sleep-logs-history", response_model=List[schemas.SleepLog])
def get_sleep_logs_history(limit: int = 30, db: Session = Depends(get_db)):
    return crud.get_sleep_logs_history(db, owner_id=MOCK_USER_ID, limit=limit)

# --- MIND ENDPOINTS ---
@app.get("/mind/task-types/", response_model=List[schemas.MindTaskType])
def read_mind_task_types(db: Session = Depends(get_db)):
    return crud.get_mind_task_types(db, owner_id=MOCK_USER_ID)

@app.post("/mind/task-types/", response_model=schemas.MindTaskType)
def create_mind_task_type(task: schemas.MindTaskTypeCreate, db: Session = Depends(get_db)):
    return crud.create_mind_task_type(db=db, task=task, owner_id=MOCK_USER_ID)

@app.put("/mind/task-types/{type_id}", response_model=schemas.MindTaskType)
def update_mind_task_type(type_id: int, task: schemas.MindTaskTypeCreate, db: Session = Depends(get_db)):
    db_task = crud.update_mind_task_type(db, type_id, task)
    if not db_task:
        raise HTTPException(status_code=404, detail="Mind task type not found")
    return db_task

@app.get("/mind/logs/", response_model=List[schemas.MindLog])
def read_mind_logs(db: Session = Depends(get_db)):
    return crud.get_mind_logs(db, owner_id=MOCK_USER_ID)

@app.post("/mind/logs/", response_model=schemas.MindLog)
def create_mind_log(log: schemas.MindLogCreate, db: Session = Depends(get_db)):
    return crud.create_mind_log(db=db, log=log, owner_id=MOCK_USER_ID)

@app.put("/mind/logs/{log_id}", response_model=schemas.MindLog)
def update_mind_log(log_id: int, log: schemas.MindLogCreate, db: Session = Depends(get_db)):
    db_log = crud.update_mind_log(db, log_id, log)
    if not db_log:
        raise HTTPException(status_code=404, detail="Mind log not found")
    return db_log

@app.put("/mind/logs/{log_id}/status")
def update_mind_log_status(log_id: int, is_completed: bool, db: Session = Depends(get_db)):
    log = crud.update_mind_log_status(db, log_id, is_completed)
    if not log:
        raise HTTPException(status_code=404, detail="Mind log not found")
    return {"status": "success", "is_completed": log.is_completed}

# --- ANALYTICS ---
from typing import Optional
from fastapi import Query
import services, repositories

def get_analytics_repo(db: Session = Depends(get_db)):
    return repositories.DailyDataRepository(db, MOCK_USER_ID)

@app.get("/analytics/discipline/today", response_model=schemas.DisciplineScore)
def get_daily_discipline(
    date_str: str = Query(None, description="YYYY-MM-DD"), # Optional
    repo: repositories.DailyDataRepository = Depends(get_analytics_repo)
):
    calc = services.DisciplineCalculator(repo)
    target_date = datetime.now().date()
    if date_str:
        try:
            target_date = datetime.strptime(date_str, "%Y-%m-%d").date()
        except:
            pass
            
    score = calc.calculate_daily_score(target_date)
    return schemas.DisciplineScore(date=str(target_date), score=score)

@app.get("/analytics/correlations", response_model=schemas.CorrelationResponse)
def get_correlations(repo: repositories.DailyDataRepository = Depends(get_analytics_repo)):
    service = services.AnalyticsService(repo)
    insights = service.get_correlations()
    return schemas.CorrelationResponse(insights=insights)

@app.get("/analytics/finance-health", response_model=schemas.FinanceHealth)
def get_finance_health(repo: repositories.DailyDataRepository = Depends(get_analytics_repo)):
    advisor = services.FinanceAdvisor(repo)
    report = advisor.generate_report()
    return schemas.FinanceHealth(**report)
    
@app.get("/analytics/weekly-summary", response_model=schemas.WeeklySummary)
def get_weekly_summary(repo: repositories.DailyDataRepository = Depends(get_analytics_repo)):
    reviewer = services.WeeklyReviewer(repo)
    summary = reviewer.generate_summary()
    return schemas.WeeklySummary(summary=summary)

# --- STATS ---
@app.get("/analytics/stats/work", response_model=schemas.WorkStats)
def get_work_stats(repo: repositories.DailyDataRepository = Depends(get_analytics_repo)):
    service = services.AnalyticsService(repo)
    return schemas.WorkStats(**service.get_work_stats())

@app.get("/analytics/stats/health", response_model=schemas.HealthStats)
def get_health_stats(repo: repositories.DailyDataRepository = Depends(get_analytics_repo)):
    service = services.AnalyticsService(repo)
    return schemas.HealthStats(**service.get_health_stats())

@app.get("/analytics/stats/mind", response_model=schemas.MindStats)
def get_mind_stats(repo: repositories.DailyDataRepository = Depends(get_analytics_repo)):
    service = services.AnalyticsService(repo)
    return schemas.MindStats(**service.get_mind_stats())

@app.get("/analytics/history/{module}", response_model=schemas.DetailedStats)
def get_detailed_history(module: str, repo: repositories.DailyDataRepository = Depends(get_analytics_repo)):
    service = services.AnalyticsService(repo)
    # Map friendly names to internal types if needed, but for now assuming frontend sends correct types
    # or handle validation
    return schemas.DetailedStats(**service.get_detailed_stats(module))


