#!/usr/bin/env python3
# This is a template for for generating the course webpage.

from string import Template
from datetime import datetime, timedelta
import pyperclip

COURSE = ""
with open("./webpage.html", "r") as f:
    COURSE = Template(f.read())

WEEK = ""
with open("./webpage_week.html", "r") as f:
    WEEK = Template(f.read())

DAY = ""
with open("./webpage_day.html", "r") as f:
    DAY = Template(f.read())

def get_mondays(start, end):
    # Convert start and end dates to datetime objects if they're not already
    if isinstance(start, str):
        start = datetime.strptime(start, "%Y-%m-%d")
    if isinstance(end, str):
        end = datetime.strptime(end, "%Y-%m-%d")
    
    # List to store Mondays
    mondays = []
    
    # Find the first Monday on or after the start date
    current_date = start
    while current_date.weekday() != 0:  # 0 represents Monday
        current_date += timedelta(days=1)

    # Add all Mondays between start and end dates
    while current_date <= end:
        mondays.append(current_date)
        current_date += timedelta(weeks=1)  # Move to the next Monday

    return mondays

def format_week(week_num, monday, *offsets):
    
    # Assert that monday is a Monday (0 represents Monday)
    assert monday.weekday() == 0, "The monday date must be a Monday."

    friday = monday + timedelta(days=4)

    if monday.month == friday.month:
        dates = f"{monday.strftime('%B %-d')} to {friday.strftime('%-d')}"
    else:
        dates = f"{monday.strftime('%B %-d')} to {friday.strftime('%B %-e')}"

    days = "\n".join(
            DAY.substitute(date = (monday + timedelta(days=i-1)).strftime("%a, %b %e."))
            for i in offsets
            )

    return WEEK.substitute(week_num = week_num, dates = dates, days = days)


def course_webpage(start, end):
    weeks = "\n\n<hr>\n\n".join(
        format_week(week_num, monday, 1,3,4,5)
        for week_num, monday in enumerate(get_mondays("2025-01-06", "2025-04-04"), 1)
        )

    return COURSE.substitute(weeks = weeks)

s = course_webpage("2025-01-06", "2025-04-04")
print(s)
pyperclip.copy(s)
