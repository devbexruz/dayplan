from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from datetime import date, datetime, timedelta
from typing import List, Optional
import models

class DailyDataRepository:
    def __init__(self, db: Session, owner_id: int):
        self.db = db
        self.owner_id = owner_id

    def get_sleep_logs(self, start_date: date, end_date: date) -> List[models.SleepLog]:
        return self.db.query(models.SleepLog).filter(
            models.SleepLog.owner_id == self.owner_id,
            models.SleepLog.start_time >= start_date,
            models.SleepLog.start_time <= end_date + timedelta(days=1) # Include end date fully
        ).all()

    def get_works(self, start_date: date, end_date: date) -> List[models.Work]:
        return self.db.query(models.Work).filter(
            models.Work.owner_id == self.owner_id,
            models.Work.date >= start_date,
            models.Work.date <= end_date + timedelta(days=1)
        ).all()
        
    def get_mind_logs(self, start_date: date, end_date: date) -> List[models.MindLog]:
        return self.db.query(models.MindLog).filter(
            models.MindLog.owner_id == self.owner_id,
            models.MindLog.date >= start_date,
            models.MindLog.date <= end_date + timedelta(days=1)
        ).all()
        
    def get_sport_logs(self, start_date: date, end_date: date) -> List[models.SportLog]:
        return self.db.query(models.SportLog).filter(
            models.SportLog.owner_id == self.owner_id,
            models.SportLog.date >= start_date,
            models.SportLog.date <= end_date + timedelta(days=1)
        ).all()
        
    def get_daily_habits(self, start_date: date, end_date: date) -> List[models.DailyHabit]:
        return self.db.query(models.DailyHabit).filter(
            models.DailyHabit.owner_id == self.owner_id,
            models.DailyHabit.date >= start_date,
            models.DailyHabit.date <= end_date + timedelta(days=1)
        ).all()

    def get_finances(self, start_date: date, end_date: date) -> List[models.Finance]:
        return self.db.query(models.Finance).filter(
            models.Finance.owner_id == self.owner_id,
            models.Finance.date >= start_date,
            models.Finance.date <= end_date + timedelta(days=1)
        ).all()
