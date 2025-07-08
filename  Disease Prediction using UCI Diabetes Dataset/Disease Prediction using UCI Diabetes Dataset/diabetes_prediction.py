"""
Diabetes Prediction using UCI Diabetes Dataset
------------------------------------------------
This script loads, explores, cleans, and models the UCI Diabetes dataset.
It performs EDA, scales features, trains multiple models, evaluates them,
and tunes hyperparameters using GridSearchCV.

Author: <Your Name>
Date: <Today's Date>
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report

# Set plot style
sns.set(style="whitegrid")

# Constants
DATA_PATH = "diabetes.csv"  # Update if your dataset is in a different location
PLOTS_DIR = "plots"


def load_data(path):
    """
    Load the dataset from a CSV file.
    Args:
        path (str): Path to the CSV file.
    Returns:
        pd.DataFrame: Loaded dataset.
    """
    return pd.read_csv(path)


def explore_data(df):
    """
    Print basic information and statistics about the dataset.
    Args:
        df (pd.DataFrame): The dataset.
    """
    print("\nFirst 5 rows:")
    print(df.head())
    print("\nDataset Info:")
    print(df.info())
    print("\nSummary Statistics:")
    print(df.describe())
    print("\nMissing values per column:")
    print(df.isnull().sum())


def clean_data(df):
    """
    Clean the dataset by handling missing or zero values in certain columns.
    Args:
        df (pd.DataFrame): The dataset.
    Returns:
        pd.DataFrame: Cleaned dataset.
    """
    # In the UCI Diabetes dataset, zeros in some columns are invalid and should be treated as missing
    cols_with_zero_invalid = [
        'Glucose', 'BloodPressure', 'SkinThickness', 'Insulin', 'BMI'
    ]
    for col in cols_with_zero_invalid:
        df[col] = df[col].replace(0, np.nan)
        median = df[col].median()
        df[col].fillna(median, inplace=True)
    return df


def perform_eda(df):
    """
    Perform exploratory data analysis and save plots to disk.
    Args:
        df (pd.DataFrame): The dataset.
    """
    if not os.path.exists(PLOTS_DIR):
        os.makedirs(PLOTS_DIR)

    # Histogram for each feature
    df.hist(bins=20, figsize=(15, 10))
    plt.suptitle('Feature Distributions')
    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.savefig(os.path.join(PLOTS_DIR, 'feature_distributions.png'))
    plt.close()

    # Correlation heatmap
    plt.figure(figsize=(10, 8))
    sns.heatmap(df.corr(), annot=True, cmap='coolwarm')
    plt.title('Correlation Heatmap')
    plt.tight_layout()
    plt.savefig(os.path.join(PLOTS_DIR, 'correlation_heatmap.png'))
    plt.close()

    # Outcome countplot
    plt.figure(figsize=(6, 4))
    sns.countplot(x='Outcome', data=df)
    plt.title('Outcome Distribution')
    plt.tight_layout()
    plt.savefig(os.path.join(PLOTS_DIR, 'outcome_distribution.png'))
    plt.close()

    # Pairplot (sampled for speed)
    sns.pairplot(df.sample(min(200, len(df))), hue='Outcome')
    plt.suptitle('Pairplot of Features', y=1.02)
    plt.savefig(os.path.join(PLOTS_DIR, 'pairplot.png'))
    plt.close()


def scale_features(X_train, X_test):
    """
    Scale features using StandardScaler.
    Args:
        X_train (pd.DataFrame): Training features.
        X_test (pd.DataFrame): Test features.
    Returns:
        tuple: Scaled training and test features.
    """
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    return X_train_scaled, X_test_scaled


def train_and_evaluate_models(X_train, X_test, y_train, y_test):
    """
    Train and evaluate multiple models.
    Args:
        X_train, X_test, y_train, y_test: Train/test splits.
    """
    models = {
        'Logistic Regression': LogisticRegression(max_iter=1000, random_state=42),
        'Random Forest': RandomForestClassifier(random_state=42),
        'SVM': SVC(random_state=42)
    }
    results = {}
    for name, model in models.items():
        print(f"\nTraining {name}...")
        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)
        acc = accuracy_score(y_test, y_pred)
        cm = confusion_matrix(y_test, y_pred)
        cr = classification_report(y_test, y_pred)
        results[name] = {'accuracy': acc, 'confusion_matrix': cm, 'classification_report': cr}
        print(f"Accuracy: {acc:.4f}")
        print("Confusion Matrix:\n", cm)
        print("Classification Report:\n", cr)
        # Save confusion matrix plot
        plt.figure(figsize=(5, 4))
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
        plt.title(f'{name} - Confusion Matrix')
        plt.xlabel('Predicted')
        plt.ylabel('Actual')
        plt.tight_layout()
        plt.savefig(os.path.join(PLOTS_DIR, f'{name.lower().replace(" ", "_")}_confusion_matrix.png'))
        plt.close()
    return results


def tune_logistic_regression(X_train, y_train):
    """
    Tune Logistic Regression using GridSearchCV.
    Args:
        X_train (np.ndarray): Scaled training features.
        y_train (pd.Series): Training labels.
    Returns:
        Best estimator from GridSearchCV.
    """
    param_grid = {
        'C': [0.01, 0.1, 1, 10, 100],
        'penalty': ['l1', 'l2'],
        'solver': ['liblinear']
    }
    grid = GridSearchCV(LogisticRegression(max_iter=1000, random_state=42), param_grid, cv=5, scoring='accuracy')
    grid.fit(X_train, y_train)
    print("\nBest parameters for Logistic Regression:", grid.best_params_)
    print("Best cross-validated accuracy:", grid.best_score_)
    return grid.best_estimator_


def main():
    # 1. Load data
    df = load_data(DATA_PATH)

    # 2. Explore data
    explore_data(df)

    # 3. Clean data
    df = clean_data(df)

    # 4. EDA
    perform_eda(df)

    # 5. Split data
    X = df.drop('Outcome', axis=1)
    y = df['Outcome']
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

    # 6. Scale features
    X_train_scaled, X_test_scaled = scale_features(X_train, X_test)

    # 7. Train and evaluate models
    results = train_and_evaluate_models(X_train_scaled, X_test_scaled, y_train, y_test)

    # 8. Hyperparameter tuning for Logistic Regression
    best_lr = tune_logistic_regression(X_train_scaled, y_train)
    y_pred = best_lr.predict(X_test_scaled)
    acc = accuracy_score(y_test, y_pred)
    cm = confusion_matrix(y_test, y_pred)
    cr = classification_report(y_test, y_pred)
    print("\nTuned Logistic Regression Results:")
    print(f"Accuracy: {acc:.4f}")
    print("Confusion Matrix:\n", cm)
    print("Classification Report:\n", cr)
    # Save confusion matrix plot
    plt.figure(figsize=(5, 4))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
    plt.title('Tuned Logistic Regression - Confusion Matrix')
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    plt.tight_layout()
    plt.savefig(os.path.join(PLOTS_DIR, 'tuned_logistic_regression_confusion_matrix.png'))
    plt.close()


if __name__ == "__main__":
    main() 