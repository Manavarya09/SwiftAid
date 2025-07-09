import tkinter as tk
from db_handler import DatabaseHandler
from ui import InputForm, Dashboard
from charts import ChartRenderer
import csv
from tkinter import filedialog, messagebox

class ExpenseTrackerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Expense Tracker")
        self.root.geometry("1000x700")
        self.root.minsize(800, 600)
        self.db = DatabaseHandler()
        self._load_categories()
        self._build_ui()
        self._refresh_dashboard()

    def _load_categories(self):
        self.categories = [cat[1] for cat in self.db.get_categories()]
        if not self.categories:
            self.db.add_category("General")
            self.categories = [cat[1] for cat in self.db.get_categories()]

    def _build_ui(self):
        self.input_form = InputForm(self.root, self.categories, self._add_transaction, self._add_category)
        self.input_form.pack(fill="x", padx=10, pady=5)
        self.dashboard = Dashboard(self.root, self.categories, self._apply_filter, self._export_csv)
        self.dashboard.pack(fill="both", expand=True, padx=10, pady=5)

    def _add_transaction(self, data):
        cat_id = self._get_category_id(data['category'])
        self.db.add_transaction(data['amount'], data['type'], cat_id, data['description'], data['date'])
        self._refresh_dashboard()

    def _add_category(self, name):
        self.db.add_category(name)
        self._load_categories()
        self.input_form.update_categories(self.categories)
        self.dashboard.update_categories(self.categories)

    def _get_category_id(self, name):
        for cat in self.db.get_categories():
            if cat[1] == name:
                return cat[0]
        return None

    def _apply_filter(self, category, from_date, to_date):
        cat_id = None
        if category and category != "All":
            cat_id = self._get_category_id(category)
        transactions = self.db.get_transactions(category_id=cat_id, start_date=from_date or None, end_date=to_date or None)
        self.dashboard.update_table(transactions)
        self._update_summary_and_charts(transactions, cat_id, from_date, to_date)

    def _refresh_dashboard(self):
        self._apply_filter("All", None, None)

    def _update_summary_and_charts(self, transactions, cat_id, from_date, to_date):
        summary = self.db.get_summary(category_id=cat_id, start_date=from_date or None, end_date=to_date or None)
        income = summary.get("Income", 0)
        expense = summary.get("Expense", 0)
        balance = income - expense
        self.dashboard.update_summary(income, expense, balance)
        self.dashboard.clear_charts()
        # Pie chart data
        pie_data = self._get_pie_data(cat_id, from_date, to_date)
        if pie_data:
            ChartRenderer.render_pie_chart(self.dashboard.chart_frame, pie_data)
        # Bar chart data
        bar_data = self._get_bar_data(cat_id, from_date, to_date)
        if bar_data:
            ChartRenderer.render_bar_chart(self.dashboard.chart_frame, bar_data)

    def _get_pie_data(self, cat_id, from_date, to_date):
        # Get spending by category (only expenses)
        cursor = self.db.conn.cursor()
        query = """
            SELECT c.name, SUM(t.amount) FROM transactions t
            LEFT JOIN categories c ON t.category_id = c.id
            WHERE t.type = 'Expense'"""
        params = []
        if cat_id:
            query += " AND t.category_id = ?"
            params.append(cat_id)
        if from_date:
            query += " AND date(t.date) >= date(?)"
            params.append(from_date)
        if to_date:
            query += " AND date(t.date) <= date(?)"
            params.append(to_date)
        query += " GROUP BY c.name"
        cursor.execute(query, params)
        return cursor.fetchall()

    def _get_bar_data(self, cat_id, from_date, to_date):
        # Get income and expense totals by date
        cursor = self.db.conn.cursor()
        query = """
            SELECT t.date,
                SUM(CASE WHEN t.type = 'Income' THEN t.amount ELSE 0 END) as income,
                SUM(CASE WHEN t.type = 'Expense' THEN t.amount ELSE 0 END) as expense
            FROM transactions t
        """
        params = []
        where = []
        if cat_id:
            where.append("t.category_id = ?")
            params.append(cat_id)
        if from_date:
            where.append("date(t.date) >= date(?)")
            params.append(from_date)
        if to_date:
            where.append("date(t.date) <= date(?)")
            params.append(to_date)
        if where:
            query += " WHERE " + " AND ".join(where)
        query += " GROUP BY t.date ORDER BY t.date"
        cursor.execute(query, params)
        return cursor.fetchall()

    def _export_csv(self):
        file_path = filedialog.asksaveasfilename(defaultextension=".csv", filetypes=[("CSV files", "*.csv")])
        if not file_path:
            return
        transactions = self.db.get_transactions()
        try:
            with open(file_path, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(["Date", "Type", "Category", "Description", "Amount"])
                for t in transactions:
                    writer.writerow(t[1:])
            messagebox.showinfo("Export Successful", f"Data exported to {file_path}")
        except Exception as e:
            messagebox.showerror("Export Failed", str(e))

    def run(self):
        self.root.mainloop()
        self.db.close()

if __name__ == "__main__":
    root = tk.Tk()
    app = ExpenseTrackerApp(root)
    app.run() 