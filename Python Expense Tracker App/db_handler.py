import sqlite3
from datetime import datetime

class DatabaseHandler:
    def __init__(self, db_name="expense_tracker.db"):
        self.conn = sqlite3.connect(db_name)
        self.create_tables()

    def create_tables(self):
        cursor = self.conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL
            )
        ''')
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                amount REAL NOT NULL,
                type TEXT CHECK(type IN ('Income', 'Expense')) NOT NULL,
                category_id INTEGER,
                description TEXT,
                date TEXT NOT NULL,
                FOREIGN KEY (category_id) REFERENCES categories(id)
            )
        ''')
        self.conn.commit()

    # Category CRUD
    def add_category(self, name):
        cursor = self.conn.cursor()
        try:
            cursor.execute("INSERT INTO categories (name) VALUES (?)", (name,))
            self.conn.commit()
        except sqlite3.IntegrityError:
            pass  # Category already exists

    def get_categories(self):
        cursor = self.conn.cursor()
        cursor.execute("SELECT id, name FROM categories ORDER BY name")
        return cursor.fetchall()

    # Transaction CRUD
    def add_transaction(self, amount, t_type, category_id, description, date):
        cursor = self.conn.cursor()
        cursor.execute('''
            INSERT INTO transactions (amount, type, category_id, description, date)
            VALUES (?, ?, ?, ?, ?)
        ''', (amount, t_type, category_id, description, date))
        self.conn.commit()

    def get_transactions(self, category_id=None, start_date=None, end_date=None):
        cursor = self.conn.cursor()
        query = "SELECT t.id, t.date, t.type, c.name, t.description, t.amount FROM transactions t LEFT JOIN categories c ON t.category_id = c.id WHERE 1=1"
        params = []
        if category_id:
            query += " AND t.category_id = ?"
            params.append(category_id)
        if start_date:
            query += " AND date(t.date) >= date(?)"
            params.append(start_date)
        if end_date:
            query += " AND date(t.date) <= date(?)"
            params.append(end_date)
        query += " ORDER BY t.date DESC"
        cursor.execute(query, params)
        return cursor.fetchall()

    def update_transaction(self, trans_id, amount, t_type, category_id, description, date):
        cursor = self.conn.cursor()
        cursor.execute('''
            UPDATE transactions SET amount=?, type=?, category_id=?, description=?, date=? WHERE id=?
        ''', (amount, t_type, category_id, description, date, trans_id))
        self.conn.commit()

    def delete_transaction(self, trans_id):
        cursor = self.conn.cursor()
        cursor.execute("DELETE FROM transactions WHERE id=?", (trans_id,))
        self.conn.commit()

    def get_summary(self, category_id=None, start_date=None, end_date=None):
        cursor = self.conn.cursor()
        query = "SELECT type, SUM(amount) FROM transactions WHERE 1=1"
        params = []
        if category_id:
            query += " AND category_id = ?"
            params.append(category_id)
        if start_date:
            query += " AND date(date) >= date(?)"
            params.append(start_date)
        if end_date:
            query += " AND date(date) <= date(?)"
            params.append(end_date)
        query += " GROUP BY type"
        cursor.execute(query, params)
        result = {"Income": 0, "Expense": 0}
        for row in cursor.fetchall():
            result[row[0]] = row[1] if row[1] else 0
        return result

    def close(self):
        self.conn.close() 