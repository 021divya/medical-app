import pandas as pd
import joblib
from sklearn.metrics import accuracy_score, classification_report
from sentence_transformers import SentenceTransformer

# =========================
# 1. Load model + encoder
# =========================
model = joblib.load("model/specialist_classifier.pkl")
label_encoder = joblib.load("model/label_encoder.pkl")

# =========================
# 2. Load embedder (same as training)
# =========================
embedder = SentenceTransformer("all-MiniLM-L6-v2")

# =========================
# 3. Load FULL dataset (NO FILTERING)
# =========================
df = pd.read_csv("data/final_symptom_speciality_dataset.csv")

# Clean basic issues
df = df[["text", "Speciality"]].dropna()

print("\n📊 Full dataset shape:", df.shape)
print("\nClass distribution:\n", df["Speciality"].value_counts())

# =========================
# 4. Prepare data
# =========================
X = df["text"].tolist()
y = df["Speciality"]

# Encode labels
y_encoded = label_encoder.transform(y)

# =========================
# 5. Convert text → embeddings
# =========================
print("\n🔄 Encoding text into embeddings...")
X_embeddings = embedder.encode(X, batch_size=64, show_progress_bar=True)

# =========================
# 6. Predict
# =========================
y_pred = model.predict(X_embeddings)

# =========================
# 7. Accuracy
# =========================
accuracy = accuracy_score(y_encoded, y_pred)
print("\n✅ Accuracy:", round(accuracy * 100, 2), "%")

# =========================
# 8. Detailed report
# =========================
print("\n📊 Classification Report:\n")
print(classification_report(y_encoded, y_pred, zero_division=0))

# =========================
# 9. Optional: top-2 accuracy (VERY USEFUL)
# =========================
import numpy as np

proba = model.predict_proba(X_embeddings)

top2_correct = 0
for i in range(len(y_encoded)):
    top2 = np.argsort(proba[i])[-2:]
    if y_encoded[i] in top2:
        top2_correct += 1

top2_accuracy = top2_correct / len(y_encoded)
print("\n🔥 Top-2 Accuracy:", round(top2_accuracy * 100, 2), "%")