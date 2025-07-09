try:
    import matplotlib.pyplot as plt  # type: ignore
    from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg  # type: ignore
except ImportError:
    plt = None
    FigureCanvasTkAgg = None
    print("Matplotlib is required for chart rendering. Please install it with 'pip install matplotlib'.")

class ChartRenderer:
    @staticmethod
    def render_pie_chart(frame, data, title="Spending by Category"):
        if plt is None or FigureCanvasTkAgg is None:
            return None
        # data: list of (category, amount)
        categories = [item[0] for item in data]
        amounts = [item[1] for item in data]
        fig, ax = plt.subplots(figsize=(4, 4))
        ax.pie(amounts, labels=categories, autopct='%1.1f%%', startangle=140)
        ax.set_title(title)
        canvas = FigureCanvasTkAgg(fig, master=frame)
        canvas.draw()
        canvas.get_tk_widget().pack(fill='both', expand=True)
        return canvas

    @staticmethod
    def render_bar_chart(frame, data, title="Income and Expense Over Time"):
        if plt is None or FigureCanvasTkAgg is None:
            return None
        # data: list of (date, income, expense)
        dates = [item[0] for item in data]
        incomes = [item[1] for item in data]
        expenses = [item[2] for item in data]
        fig, ax = plt.subplots(figsize=(6, 4))
        ax.bar(dates, incomes, label='Income', color='green')
        ax.bar(dates, expenses, label='Expense', color='red', bottom=incomes)
        ax.set_title(title)
        ax.set_xlabel('Date')
        ax.set_ylabel('Amount')
        ax.legend()
        plt.xticks(rotation=45)
        canvas = FigureCanvasTkAgg(fig, master=frame)
        canvas.draw()
        canvas.get_tk_widget().pack(fill='both', expand=True)
        return canvas 