import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
try:
    from tkcalendar import DateEntry  # type: ignore
except ImportError:
    DateEntry = None
    print("tkcalendar is required for date picking. Please install it with 'pip install tkcalendar'.")
from datetime import datetime

class InputForm(tk.LabelFrame):
    def __init__(self, master, categories, on_submit, on_add_category, **kwargs):
        super().__init__(master, text="Add Transaction", padx=10, pady=10, **kwargs)
        self.on_submit = on_submit
        self.on_add_category = on_add_category
        self.categories = categories
        self._build_form()

    def _build_form(self):
        # Amount
        tk.Label(self, text="Amount:").grid(row=0, column=0, sticky="e")
        self.amount_var = tk.StringVar()
        tk.Entry(self, textvariable=self.amount_var).grid(row=0, column=1, sticky="w")

        # Type
        tk.Label(self, text="Type:").grid(row=1, column=0, sticky="e")
        self.type_var = tk.StringVar(value="Expense")
        tk.Radiobutton(self, text="Income", variable=self.type_var, value="Income").grid(row=1, column=1, sticky="w")
        tk.Radiobutton(self, text="Expense", variable=self.type_var, value="Expense").grid(row=1, column=2, sticky="w")

        # Category
        tk.Label(self, text="Category:").grid(row=2, column=0, sticky="e")
        self.category_var = tk.StringVar()
        self.category_cb = ttk.Combobox(self, textvariable=self.category_var, values=self.categories, state="readonly")
        self.category_cb.grid(row=2, column=1, sticky="w")
        tk.Button(self, text="+", command=self._add_category).grid(row=2, column=2, sticky="w")

        # Description
        tk.Label(self, text="Description:").grid(row=3, column=0, sticky="e")
        self.desc_var = tk.StringVar()
        tk.Entry(self, textvariable=self.desc_var).grid(row=3, column=1, columnspan=2, sticky="we")

        # Date
        tk.Label(self, text="Date:").grid(row=4, column=0, sticky="e")
        self.date_var = tk.StringVar(value=datetime.today().strftime('%Y-%m-%d'))
        if DateEntry:
            self.date_entry = DateEntry(self, textvariable=self.date_var, date_pattern='yyyy-mm-dd')
            self.date_entry.grid(row=4, column=1, sticky="w")
        else:
            tk.Entry(self, textvariable=self.date_var).grid(row=4, column=1, sticky="w")

        # Submit
        tk.Button(self, text="Add", command=self._submit).grid(row=5, column=0, columnspan=3, pady=5)

    def _add_category(self):
        new_cat = simpledialog.askstring("Add Category", "Category name:")
        if new_cat:
            self.on_add_category(new_cat)

    def _submit(self):
        try:
            amount = float(self.amount_var.get())
        except ValueError:
            messagebox.showerror("Invalid Input", "Amount must be a number.")
            return
        if not self.category_var.get():
            messagebox.showerror("Invalid Input", "Category is required.")
            return
        self.on_submit({
            'amount': amount,
            'type': self.type_var.get(),
            'category': self.category_var.get(),
            'description': self.desc_var.get(),
            'date': self.date_var.get()
        })
        self.amount_var.set("")
        self.desc_var.set("")
        self.date_var.set(datetime.today().strftime('%Y-%m-%d'))

    def update_categories(self, categories):
        self.categories = categories
        self.category_cb['values'] = categories

class Dashboard(tk.Frame):
    def __init__(self, master, categories, on_filter, on_export, **kwargs):
        super().__init__(master, **kwargs)
        self.categories = categories
        self.on_filter = on_filter
        self.on_export = on_export
        self._build_dashboard()

    def _build_dashboard(self):
        # Filters
        filter_frame = tk.LabelFrame(self, text="Filters")
        filter_frame.pack(fill="x", padx=5, pady=5)
        tk.Label(filter_frame, text="Category:").pack(side="left")
        self.filter_cat_var = tk.StringVar()
        self.filter_cat_cb = ttk.Combobox(filter_frame, textvariable=self.filter_cat_var, values=["All"] + self.categories, state="readonly", width=15)
        self.filter_cat_cb.current(0)
        self.filter_cat_cb.pack(side="left", padx=2)
        tk.Label(filter_frame, text="From:").pack(side="left")
        self.filter_from_var = tk.StringVar()
        if DateEntry:
            self.filter_from_entry = DateEntry(filter_frame, textvariable=self.filter_from_var, date_pattern='yyyy-mm-dd', width=12)
            self.filter_from_entry.pack(side="left", padx=2)
        else:
            tk.Entry(filter_frame, textvariable=self.filter_from_var, width=12).pack(side="left", padx=2)
        tk.Label(filter_frame, text="To:").pack(side="left")
        self.filter_to_var = tk.StringVar()
        if DateEntry:
            self.filter_to_entry = DateEntry(filter_frame, textvariable=self.filter_to_var, date_pattern='yyyy-mm-dd', width=12)
            self.filter_to_entry.pack(side="left", padx=2)
        else:
            tk.Entry(filter_frame, textvariable=self.filter_to_var, width=12).pack(side="left", padx=2)
        tk.Button(filter_frame, text="Apply", command=self._apply_filter).pack(side="left", padx=2)
        tk.Button(filter_frame, text="Export CSV", command=self.on_export).pack(side="right", padx=2)

        # Summary
        self.summary_var = tk.StringVar()
        summary_label = tk.Label(self, textvariable=self.summary_var, font=("Arial", 12, "bold"), fg="blue")
        summary_label.pack(fill="x", padx=5, pady=2)

        # Table
        table_frame = tk.Frame(self)
        table_frame.pack(fill="both", expand=True, padx=5, pady=5)
        columns = ("Date", "Type", "Category", "Description", "Amount")
        self.tree = ttk.Treeview(table_frame, columns=columns, show="headings")
        for col in columns:
            self.tree.heading(col, text=col)
            self.tree.column(col, anchor="center")
        vsb = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=vsb.set)
        self.tree.pack(side="left", fill="both", expand=True)
        vsb.pack(side="right", fill="y")

        # Chart area
        self.chart_frame = tk.LabelFrame(self, text="Charts")
        self.chart_frame.pack(fill="both", expand=True, padx=5, pady=5)

    def update_categories(self, categories):
        self.categories = categories
        self.filter_cat_cb['values'] = ["All"] + categories

    def update_table(self, transactions):
        for row in self.tree.get_children():
            self.tree.delete(row)
        for t in transactions:
            self.tree.insert('', 'end', values=t[1:])

    def update_summary(self, income, expense, balance):
        self.summary_var.set(f"Total Income: {income:.2f}   Total Expense: {expense:.2f}   Balance: {balance:.2f}")

    def clear_charts(self):
        for widget in self.chart_frame.winfo_children():
            widget.destroy()

    def _apply_filter(self):
        cat = self.filter_cat_var.get()
        from_date = self.filter_from_var.get()
        to_date = self.filter_to_var.get()
        self.on_filter(cat, from_date, to_date) 