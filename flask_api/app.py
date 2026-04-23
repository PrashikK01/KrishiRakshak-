from flask import Flask, request, jsonify
from flask_cors import CORS
import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import io
import json

app = Flask(__name__)
CORS(app)

# Disease treatments dictionary
treatments = {
    "Tomato_Early_blight": "Apply copper-based fungicide. Remove infected leaves. Water at base only.",
    "Tomato_Late_blight": "Use Mancozeb fungicide immediately. Remove and destroy infected plants.",
    "Tomato_healthy": "Your tomato plant is healthy! Keep watering regularly.",
    "Potato_Early_blight": "Apply fungicide every 7 days. Avoid overhead irrigation.",
    "Potato_Late_blight": "Use Ridomil fungicide. Destroy infected plants immediately.",
    "Potato_healthy": "Your potato plant is healthy! Maintain proper drainage.",
    "Corn_(maize)_Common_rust": "Apply fungicide at early stage. Use rust resistant seeds next season.",
    "Corn_(maize)_healthy": "Your corn plant is healthy! Ensure proper sunlight.",
    "Orange_Haunglongbing_(Citrus_greening)": "No cure available. Remove infected tree immediately to protect others.",
}

def get_treatment(disease_name):
    for key in treatments:
        if key.lower() in disease_name.lower():
            return treatments[key]
    return "Consult a local agronomist for treatment advice for this disease."

# Load model
device = torch.device('cpu')
model = None
class_names = []

def load_model():
    global model, class_names
    try:
        checkpoint = torch.load('best_model.pth', map_location=device)
        class_names = checkpoint['class_names']
        num_classes = checkpoint['num_classes']
        model = models.efficientnet_b0(pretrained=False)
        model.classifier[1] = nn.Linear(1280, num_classes)
        model.load_state_dict(checkpoint['model_state_dict'])
        model.eval()
        print(f"Model loaded! Classes: {num_classes}")
    except Exception as e:
        print(f"Error loading model: {e}")

# Image preprocessing
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406],
                         [0.229, 0.224, 0.225])
])

@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({'error': 'Model not loaded'}), 500
    
    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400
    
    file = request.files['image']
    image_bytes = file.read()
    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    tensor = transform(image).unsqueeze(0).to(device)
    
    with torch.no_grad():
        outputs = model(tensor)
        probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
        confidence, predicted = torch.max(probabilities, 0)
    
    disease = class_names[predicted.item()]
    confidence_pct = round(confidence.item() * 100, 2)
    treatment = get_treatment(disease)
    
    return jsonify({
        'disease': disease.replace('_', ' '),
        'confidence': confidence_pct,
        'treatment': treatment,
        'is_healthy': 'healthy' in disease.lower()
    })

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'running', 'model_loaded': model is not None})

if __name__ == '__main__':
    load_model()
    app.run(host='0.0.0.0', port=5000, debug=False)