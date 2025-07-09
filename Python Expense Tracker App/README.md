# Expense Tracker

A Python desktop application to track your income and expenses, visualize spending, and manage categories. Built with Tkinter, SQLite, and Matplotlib.

## Features
- Add, view, update, and delete transactions
- Categorize transactions (add new categories)
- Filter by category and date range
- Dashboard with summary (income, expense, balance)
- Pie chart: Spending breakdown by category
- Bar chart: Income and expense over time
- Export data to CSV
- Responsive, resizable UI with scrollbars
- Persistent data storage (SQLite)

## Requirements
- Python 3.7+
- tkinter (usually included with Python)
- tkcalendar
- matplotlib

## Installation
1. Clone or download this repository.
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Running the App
```bash
python main.py
```

## Notes
- If you get an error about `tkcalendar` or `matplotlib`, install them with pip as shown above.
- All data is stored locally in `expense_tracker.db`.
- The app is resizable and works on Windows, macOS, and Linux.

## Screenshots
*Add your screenshots here!*

## License
MIT 