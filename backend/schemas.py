from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime

# --- PULL (FINANCE) ---

class FinanceCategoryBase(BaseModel):
    name: str
    type: str # active_income, passive_income, expense

class FinanceCategoryCreate(FinanceCategoryBase):
    pass

class FinanceCategory(FinanceCategoryBase):
    id: int
    owner_id: int
    class Config:
        from_attributes = True

class FinanceBase(BaseModel):
    amount: int
    type: str # "active_income", "passive_income", "expense"
    expense_frequency: Optional[str] = None # "weekly", "monthly", "yearly", "one_time"
    category_id: int
    description: Optional[str] = None

class FinanceCreate(FinanceBase):
    pass

class Finance(FinanceBase):
    id: int
    date: datetime
    owner_id: int
    category: Optional[FinanceCategory] = None

    class Config:
        from_attributes = True

class MonthlyStat(BaseModel):
    month: str # "YYYY-MM"
    total_income: float
    total_expense: float

class DailyStat(BaseModel):
    date: str # "YYYY-MM-DD"
    total_income: float
    total_expense: float

# --- WORK (ISH) ---
class WorkBase(BaseModel):
    type: str # "active", "passive"
    is_completed: bool = False

class WorkCreate(WorkBase):
    pass

class Work(WorkBase):
    id: int
    date: datetime
    owner_id: int

    class Config:
        from_attributes = True

class WorkStatus(BaseModel):
    active: bool
    passive: bool
    is_saved: bool = False # Overall saved status check

# --- ANALYTICS ---
class DisciplineScore(BaseModel):
    date: str
    score: float

class CorrelationResponse(BaseModel):
    insights: Dict[str, str]

class FinanceHealth(BaseModel):
    burn_rate_daily: float
    passive_income_coverage: float
    warnings: List[str]

class WeeklySummary(BaseModel):
    summary: str

class WorkStats(BaseModel):
    streak_days: int
    completion_rate_weekly: float
    total_completed: int
    motivation_message: str

class HealthStats(BaseModel):
    avg_sleep_hours: float
    sport_days_weekly: int
    habit_consistency: float # 0-100
    motivation_message: str

class MindStats(BaseModel):
    tasks_weekly: int
    top_focus_area: Optional[str]
    motivation_message: str

class HistoryPoint(BaseModel):
    date: str
    value: float

class DetailedStats(BaseModel):
    history: List[HistoryPoint] # 30 days usually
    growth_pct: float # vs previous 30 days
    average_value: float
    total_value: float # sum for counts, or avg? Depends.
    comparison_text: str # "O'tgan oyga nisbatan 10% ga ko'p"

# --- HEALTH (SOG'LIK) ---

# Exercise Types
class ExerciseTypeBase(BaseModel):
    name: str
    description: Optional[str] = None
    sets: int = 0
    reps: int = 0
    is_active: bool = True

class ExerciseTypeCreate(ExerciseTypeBase):
    pass

class ExerciseType(ExerciseTypeBase):
    id: int
    owner_id: int
    
    class Config:
        from_attributes = True

# Sport Logs
class SportLogBase(BaseModel):
    exercise_type_id: int
    # sets/reps removed
    is_completed: bool = False

class SportLogCreate(SportLogBase):
    pass

class SportLog(SportLogBase):
    id: int
    date: datetime
    owner_id: int
    exercise_type: Optional[ExerciseType] = None

    class Config:
        from_attributes = True

class SleepLogBase(BaseModel):
    start_time: datetime
    end_time: Optional[datetime] = None

class SleepLogCreate(SleepLogBase):
    pass

class SleepLog(SleepLogBase):
    id: int
    owner_id: int

    class Config:
        from_attributes = True

class DailyHabitBase(BaseModel):
    meal_count: int = 0
    morning_hygiene_done: bool = False

class DailyHabitCreate(DailyHabitBase):
    pass

class DailyHabit(DailyHabitBase):
    id: int
    date: datetime
    owner_id: int

    class Config:
        from_attributes = True

# --- MIND (AQL) ---

# Mind Task Types
class MindTaskTypeBase(BaseModel):
    title: str
    description: Optional[str] = None
    is_active: bool = True

class MindTaskTypeCreate(MindTaskTypeBase):
    pass

class MindTaskType(MindTaskTypeBase):
    id: int
    owner_id: int

    class Config:
        from_attributes = True

# Mind Logs
class MindLogBase(BaseModel):
    task_type_id: int
    is_completed: bool = False

class MindLogCreate(MindLogBase):
    pass

class MindLog(MindLogBase):
    id: int
    date: datetime
    owner_id: int
    task_type: Optional[MindTaskType] = None

    class Config:
        from_attributes = True

# --- USER ---
class UserBase(BaseModel):
    username: str
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    balance: int
    
    class Config:
        from_attributes = True

# --- DAILY REPORT AGGREGATION ---
class DailyReport(BaseModel):
    date: datetime
    works: List[Work] = []
    sleep_log: Optional[SleepLog] = None
    daily_habit: Optional[DailyHabit] = None
    sport_logs: List[SportLog] = []
    mind_logs: List[MindLog] = []
