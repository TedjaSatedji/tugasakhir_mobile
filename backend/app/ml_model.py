import os
import csv
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
import joblib

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "ml_category_model.joblib")
CSV_PATH = os.path.join(BASE_DIR, "dataset.csv")

def train_and_save_model():
    texts = []
    labels = []
    
    # Load dataset from CSV
    if os.path.exists(CSV_PATH):
        with open(CSV_PATH, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                texts.append(row['description'])
                labels.append(int(row['category']))
    else:
        # Fallback just in case
        texts = ["nasi goreng", "baju", "gojek"]
        labels = [0, 1, 3]
    
    # Create a pipeline that extracts features from text then trains the classifier
    pipeline = Pipeline([
        ('tfidf', TfidfVectorizer(ngram_range=(1, 2))),
        ('clf', MultinomialNB())
    ])
    
    pipeline.fit(texts, labels)
    joblib.dump(pipeline, MODEL_PATH)
    return pipeline

def load_or_train_model():
    if os.path.exists(MODEL_PATH):
        try:
            return joblib.load(MODEL_PATH)
        except Exception:
            return train_and_save_model()
    else:
        return train_and_save_model()

def predict_category(description: str) -> int:
    model = load_or_train_model()
    # Return the integer category
    prediction = model.predict([description.lower()])
    return int(prediction[0])
