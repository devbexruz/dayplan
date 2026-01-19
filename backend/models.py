from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, Time, Enum
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime
import enum

# Enums
class FinanceType(str, enum.Enum):
    active_income = "active_income"
    passive_income = "passive_income"
    expense = "expense"

class ExpenseFrequency(str, enum.Enum):
    weekly = "weekly"
    monthly = "monthly"
    yearly = "yearly"
    one_time = "one_time"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    full_name = Column(String)
    balance = Column(Integer, default=0)
    
    # Relationships
    finances = relationship("Finance", back_populates="owner")
    finance_categories = relationship("FinanceCategory", back_populates="owner")
    
    works = relationship("Work", back_populates="owner")
    
    # Health relationships
    sleep_logs = relationship("SleepLog", back_populates="owner")
    daily_habits = relationship("DailyHabit", back_populates="owner")
    sport_logs = relationship("SportLog", back_populates="owner")
    exercise_types = relationship("ExerciseType", back_populates="owner")

    # Mind relationships
    mind_logs = relationship("MindLog", back_populates="owner")
    mind_task_types = relationship("MindTaskType", back_populates="owner")

# --- FINANCE ---

class FinanceCategory(Base):
    __tablename__ = "finance_categories"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) 
    type = Column(String) # active_income, passive_income, expense
    
    owner_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="finance_categories")


class Finance(Base):
    __tablename__ = "finances"

    id = Column(Integer, primary_key=True, index=True)
    amount = Column(Integer)
    
    # New logic: Type is detailed
    type = Column(String) # active_income, passive_income, expense
    
    # Expense Frequency (Only relevant if type == expense)
    expense_frequency = Column(String, nullable=True) # weekly, monthly, yearly, one_time
    
    # Dynamic Category Link
    category_id = Column(Integer, ForeignKey("finance_categories.id"))
    category = relationship("FinanceCategory")
    
    description = Column(String, nullable=True)
    date = Column(DateTime, default=datetime.now)
    owner_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("User", back_populates="finances")


# 2. Ish (Work)
class Work(Base):
    __tablename__ = "works"

    id = Column(Integer, primary_key=True, index=True)
    type = Column(String) # "passive", "active"
    is_completed = Column(Boolean, default=False)
    date = Column(DateTime, default=datetime.now)
    owner_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("User", back_populates="works")


# 3. Sog'lik (Health)

class ExerciseType(Base):
    __tablename__ = "exercise_types"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    description = Column(String, nullable=True)
    sets = Column(Integer, default=0)
    reps = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    
    owner_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="exercise_types")


class SleepLog(Base):
    __tablename__ = "sleep_logs"

    id = Column(Integer, primary_key=True, index=True)
    
    start_time = Column(DateTime, nullable=False) # Must have a start
    end_time = Column(DateTime, nullable=True)   # Null implies currently sleeping
    
    owner_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="sleep_logs")

class DailyHabit(Base):
    __tablename__ = "daily_habits"

    id = Column(Integer, primary_key=True, index=True)
    date = Column(DateTime, default=datetime.now)
    
    meal_count = Column(Integer, default=0)
    morning_hygiene_done = Column(Boolean, default=False)
    
    owner_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="daily_habits")

class SportLog(Base):
    __tablename__ = "sport_logs"

    id = Column(Integer, primary_key=True, index=True)
    exercise_type_id = Column(Integer, ForeignKey("exercise_types.id"))
    exercise_type = relationship("ExerciseType")
    
    is_completed = Column(Boolean, default=False)
    date = Column(DateTime, default=datetime.now)
    
    owner_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="sport_logs")


# 4. Aql (Mind)

class MindTaskType(Base):
    __tablename__ = "mind_task_types"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    description = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    
    owner_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="mind_task_types")

class MindLog(Base):
    __tablename__ = "mind_logs"

    id = Column(Integer, primary_key=True, index=True)
    task_type_id = Column(Integer, ForeignKey("mind_task_types.id"))
    task_type = relationship("MindTaskType")
    
    is_completed = Column(Boolean, default=False)
    date = Column(DateTime, default=datetime.now)
    
    owner_id = Column(Integer, ForeignKey("users.id"))
    owner = relationship("User", back_populates="mind_logs")
