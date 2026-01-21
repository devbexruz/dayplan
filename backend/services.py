from datetime import date, timedelta, datetime
from typing import List, Dict, Any, Optional
import pandas as pd
import numpy as np
from repositories import DailyDataRepository
import models

class DisciplineCalculator:
    def __init__(self, repo: DailyDataRepository):
        self.repo = repo
        
    def calculate_daily_score(self, target_date: date) -> float:
        """
        Calculates Discipline Index (0-100) for a specific date.
        Weights:
        - Sleep: 20% (Target 8h)
        - Work: 30% (Completion Rate)
        - Mind: 25% (Completion Rate)
        - Sport: 15% (Done or not)
        - Habits: 10% (Hygiene + Meals)
        """
        # Fetch data for single day
        sleeps = self.repo.get_sleep_logs(target_date, target_date)
        works = self.repo.get_works(target_date, target_date)
        minds = self.repo.get_mind_logs(target_date, target_date)
        sports = self.repo.get_sport_logs(target_date, target_date)
        habits = self.repo.get_daily_habits(target_date, target_date)
        
        # 1. Sleep Score (20%)
        sleep_score = 0
        if sleeps:
            total_seconds = 0
            for s in sleeps:
                if s.end_time and s.start_time:
                    total_seconds += (s.end_time - s.start_time).total_seconds()
            hours = total_seconds / 3600
            # Curve: 8 hours is 100. <8 penalizes. >9 penalizes slightly? 
            # Simple linear for MVP: min(hours / 8, 1) * 100
            sleep_score = min(hours / 8.0, 1.0) * 100
        
        # 2. Work Score (30%)
        work_score = 0
        if works:
            completed = sum(1 for w in works if w.is_completed)
            work_score = (completed / len(works)) * 100
        else:
            # If no work planned, neutral or 0? 
            # Assume 0 implies "No discipline to plan work". Or maybe N/A?
            # Let's say 0 for now to encourage planning.
            work_score = 0
            
        # 3. Mind Score (25%)
        mind_score = 0
        if minds:
            completed_mind = sum(1 for m in minds if m.is_completed)
            mind_score = (completed_mind / len(minds)) * 100
            
        # 4. Sport Score (15%)
        sport_score = 0
        if sports:
            # Any sport done is good
            sport_done = any(s.is_completed for s in sports)
            sport_score = 100 if sport_done else 0
            
        # 5. Habit Score (10%)
        habit_score = 0
        if habits:
            h = habits[0] # Assume 1 per day
            hygiene_points = 50 if h.morning_hygiene_done else 0
            # Meals: Target 3 = 50 pts. 
            meal_points = min(h.meal_count / 3.0, 1.0) * 50
            habit_score = hygiene_points + meal_points
            
        final_score = (
            (sleep_score * 0.20) +
            (work_score * 0.30) +
            (mind_score * 0.25) +
            (sport_score * 0.15) +
            (habit_score * 0.10)
        )
        return round(final_score, 1)

class AnalyticsService:
    def __init__(self, repo: DailyDataRepository):
        self.repo = repo
        
    def get_correlations(self, days: int = 30) -> Dict[str, str]:
        """
        analyzes cross-table correlations.
        Example: Sleep duration vs Work Completion.
        """
        end_date = datetime.now().date()
        start_date = end_date - timedelta(days=days)
        
        # Fetch data
        sleeps = self.repo.get_sleep_logs(start_date, end_date)
        works = self.repo.get_works(start_date, end_date)
        finances = self.repo.get_finances(start_date, end_date)
        
        # Prepare DataFrames
        data = []
        # Iterate days
        delta = (end_date - start_date).days
        for i in range(delta + 1):
            day = start_date + timedelta(days=i)
            # Sleep (Previous night? Or same day wake up? Let's use wake date)
            # SleepLog.start_time usually previous day, end_time is wake day.
            # We associate sleep ending on 'day' with 'day's performance.
            day_sleep = sum([(s.end_time - s.start_time).total_seconds()/3600 
                             for s in sleeps 
                             if s.end_time and s.end_time.date() == day])
            
            # Work
            day_works = [w for w in works if w.date.date() == day]
            work_perf = (sum(1 for w in day_works if w.is_completed) / len(day_works)) * 100 if day_works else 0
            
            # Finance Expense
            day_finances = [f for f in finances if f.date.date() == day and f.type == 'expense']
            expense = sum(f.amount for f in day_finances)
            
            data.append({
                "date": day,
                "sleep_hours": day_sleep,
                "work_perf": work_perf,
                "expense": expense
            })
            
        df = pd.DataFrame(data)
        if len(df) < 5:
            return {"insight": "Ma'lumotlar yetarli emas (kamida 5 kun kerak)."}
            
        insights = {}
        
        # 1. Sleep vs Work
        corr_sleep_work = df['sleep_hours'].corr(df['work_perf'])
        if corr_sleep_work > 0.5:
            insights['sleep_work'] = "Siz ko'proq uxlagan kunlaringiz ish unumdorligingiz sezilarli oshadi!"
        elif corr_sleep_work < -0.3:
            insights['sleep_work'] = "Qiziq, kamroq uyqu bilan ham ishlarni bajara olyapsiz (lekin uzoq muddatda zararli)."
        else:
            insights['sleep_work'] = "Uyqu va ish unumdorligi o'rtasida kuchli bog'liqlik topilmadi."

        # 2. Work vs Expense (Stress spending?)
        corr_work_expense = df['work_perf'].corr(df['expense'])
        if corr_work_expense < -0.4:
            insights['work_expense'] = "Ishlar qolib ketganda ko'proq pul sarflashga moyilsiz (Stress Spending)."
            
        return insights

    def get_work_stats(self) -> Dict[str, Any]:
        end = datetime.now().date()
        start = end - timedelta(days=30)
        works = self.repo.get_works(start, end)
        
        # Streak Calculation
        # Assuming streak = consecutive days with at least one completed task?
        streak = 0
        current_check = end
        while True:
            day_works = [w for w in works if w.date.date() == current_check]
            completed = any(w.is_completed for w in day_works) if day_works else False
            # Or if WorkStatus (from today's specific table) was "active" or "passive"?
            # Since Work model has is_completed, I'll use that.
            if completed:
                streak += 1
                current_check -= timedelta(days=1)
            else:
                if current_check == end: # If today not done yet, don't break streak unless yesterday missed
                     # Actually streak usually includes today if done, or continues from yesterday.
                     # If today is 0, check yesterday.
                     pass 
                
                # Check if yesterday missed
                if current_check < end:
                    break
                
                # If checking today and it's empty, move to yesterday
                current_check -= timedelta(days=1)
                # If yesterday also empty, streak ends
                # Ideally: Streak is continuous chain.
        
        # Simpler Streak: Count consecutive days from yesterday back that have data
        streak = 0
        check_date = end - timedelta(days=1) # Start checking from yesterday
        # Check today first
        today_works = [w for w in works if w.date.date() == end and w.is_completed]
        if today_works:
            streak += 1
            
        while True:
            day_works = [w for w in works if w.date.date() == check_date and w.is_completed]
            if day_works:
                streak += 1
                check_date -= timedelta(days=1)
            else:
                break
                
        # Weekly completion
        week_start = end - timedelta(days=6)
        week_works = [w for w in works if w.date.date() >= week_start]
        total = len(week_works)
        completed_week = sum(1 for w in week_works if w.is_completed)
        rate = (completed_week / total * 100) if total > 0 else 0
        
        # Motivation
        msg = "Yaxshi boshlanish!"
        if streak > 3: msg = "Sizni to'xtatib bo'lmaydi!"
        if streak > 7: msg = "Haqiqiy mashina!"
        if rate < 30 and total > 0: msg = "Kichik qadamlar bilan boshlang."
        
        return {
            "streak_days": streak,
            "completion_rate_weekly": round(rate, 1),
            "total_completed": sum(1 for w in works if w.is_completed),
            "motivation_message": msg
        }

    def get_health_stats(self) -> Dict[str, Any]:
        end = datetime.now().date()
        start = end - timedelta(days=6) # Last 7 days
        sleeps = self.repo.get_sleep_logs(start, end)
        sports = self.repo.get_sport_logs(start, end)
        habits = self.repo.get_daily_habits(start, end)
        
        # Sleep Avg
        total_hours = 0
        count = 0
        for s in sleeps:
            if s.end_time and s.start_time:
                total_hours += (s.end_time - s.start_time).total_seconds() / 3600
                count += 1
        avg_sleep = round(total_hours / count, 1) if count > 0 else 0
        
        # Sport Days
        sport_days = len(set(s.date.date() for s in sports if s.is_completed))
        
        # Habit Consistency
        habit_pts = 0
        for h in habits:
            if h.morning_hygiene_done: habit_pts += 1
            if h.meal_count >= 3: habit_pts += 1
        habit_consistency = (habit_pts / (7 * 2)) * 100 # Approx max points
        
        msg = "Sog'lik - eng katta boylik."
        if sport_days >= 3: msg = "Chempion ruhiyati shakllanmoqda!"
        if avg_sleep < 6 and count > 0: msg = "Uyquga e'tibor bering, bugun ertaroq yoting."
        
        return {
            "avg_sleep_hours": avg_sleep,
            "sport_days_weekly": sport_days,
            "habit_consistency": round(habit_consistency, 1),
            "motivation_message": msg
        }

    def get_mind_stats(self) -> Dict[str, Any]:
        end = datetime.now().date()
        start = end - timedelta(days=6)
        minds = self.repo.get_mind_logs(start, end)
        
        tasks_weekly = sum(1 for m in minds if m.is_completed)
        
        # Top Focus Area (Task Type)
        type_counts = {}
        for m in minds:
            if m.is_completed:
                t_id = m.task_type_id
                type_counts[t_id] = type_counts.get(t_id, 0) + 1
        
        # Need to fetch task type name? Repository returns models, but task_type might differ.
        # Assuming MindLog model has relationship 'task_type' loaded or we just return ID/Name if available.
        # Models: MindLog -> task_type (relationship).
        
        top_focus = "General"
        if type_counts:
            # simple max
            pass 
            
        msg = "Bilim olishdan to'xtamang."
        if tasks_weekly > 5: msg = "Miyangiz pichoqdek o'tkir!"
        
        return {
            "tasks_weekly": tasks_weekly,
            "top_focus_area": top_focus,
            "motivation_message": msg
        }

    def get_detailed_stats(self, module_type: str, period: str = 'monthly') -> Dict[str, Any]:
        """
        Gets time-series data and growth comparison.
        module_type: 'work', 'health_sleep', 'mind_tasks'
        period: 'monthly' (returns 30 daily points)
        """
        end = datetime.now().date()
        days_count = 30
        prev_days_count = 30
        
        start = end - timedelta(days=(days_count + prev_days_count))
        
        # Fetch all raw data for range
        works = self.repo.get_works(start, end)
        sleeps = self.repo.get_sleep_logs(start, end)
        minds = self.repo.get_mind_logs(start, end)
        finances = self.repo.get_finances(start, end)
        sports = self.repo.get_sport_logs(start, end)
        
        history = []
        
        current_values = []
        prev_values = []
        
        total_range = days_count + prev_days_count
        
        for i in range(total_range):
             day = start + timedelta(days=i)
             val = 0.0
             
             if module_type == 'work':
                 d_works = [w for w in works if w.date.date() == day]
                 if d_works:
                     completed = sum(1 for w in d_works if w.is_completed)
                     val = (completed / len(d_works)) * 100
                 else:
                     val = 0.0
                     
             elif module_type == 'health_sleep':
                 d_sleeps = [s for s in sleeps if s.end_time and s.end_time.date() == day]
                 hours = sum((s.end_time - s.start_time).total_seconds()/3600 for s in d_sleeps)
                 val = hours
                 
             elif module_type == 'mind_tasks':
                 d_minds = [m for m in minds if m.date.date() == day and m.is_completed is True]
                 val = float(len(d_minds))
            
             elif module_type == 'health_sport':
                 d_sports = [s for s in sports if s.date.date() == day and s.is_completed is True]
                 val = float(len(d_sports))

             elif module_type == 'finance_expense':
                 d_fin = [f for f in finances if f.date.date() == day and f.type == 'expense']
                 val = sum(f.amount for f in d_fin)
                 
             # Store
             if i < prev_days_count:
                 prev_values.append(val)
             else:
                 current_values.append(val)
                 history.append({"date": str(day), "value": round(val, 2)})
                 
        # Calc Stats
        curr_avg = sum(current_values) / len(current_values) if current_values else 0
        prev_avg = sum(prev_values) / len(prev_values) if prev_values else 0
        
        growth = 0.0
        if prev_avg > 0:
            growth = ((curr_avg - prev_avg) / prev_avg) * 100
            
        total = sum(current_values)
        
        comp_text = "O'zgarish yo'q"
        if growth > 5:
            comp_text = f"O'tgan oyga nisbatan {round(growth, 1)}% o'sish!"
        elif growth < -5:
            comp_text = f"O'tgan oyga nisbatan {abs(round(growth, 1))}% pasayish."
            
        return {
            "history": history,
            "growth_pct": round(growth, 1),
            "average_value": round(curr_avg, 1),
            "total_value": round(total, 0),
            "comparison_text": comp_text
        }

class FinanceAdvisor:
    def __init__(self, repo: DailyDataRepository):
        self.repo = repo
        
    def generate_report(self) -> Dict[str, Any]:
        end = datetime.now().date()
        start = end - timedelta(days=30)
        logs = self.repo.get_finances(start, end)
        
        income = sum(f.amount for f in logs if f.type in ['active_income', 'passive_income'])
        passive = sum(f.amount for f in logs if f.type == 'passive_income')
        expense = sum(f.amount for f in logs if f.type == 'expense')
        
        burn_rate = expense / 30.0 if logs else 0
        passive_ratio = (passive / expense) * 100 if expense > 0 else 100
        
        warnings = []
        if expense > income and income > 0:
            warnings.append("Diqqat! Xarajatlaringiz daromaddan oshib ketdi.")
        
        return {
            "burn_rate_daily": round(burn_rate, 2),
            "passive_income_coverage": round(passive_ratio, 1),
            "warnings": warnings
        }

class WeeklyReviewer:
    def __init__(self, repo: DailyDataRepository):
        self.repo = repo
        self.calc = DisciplineCalculator(repo)
        
    def generate_summary(self) -> str:
        end = datetime.now().date()
        start = end - timedelta(days=7)
        
        # Average Discipline
        scores = []
        for i in range(7):
            day = start + timedelta(days=i)
            scores.append(self.calc.calculate_daily_score(day))
        
        avg_score = sum(scores) / len(scores) if scores else 0
        
        status = 'yaxshi' if avg_score > 70 else "o'rtacha"
        
        return f"Haftalik Xulosa:\nO'rtacha intizom: {round(avg_score, 1)}/100.\nSiz bu hafta {status} natija ko'rsatdingiz. (To'liq AI tahlil integratsiya qilinmoqda...)"
