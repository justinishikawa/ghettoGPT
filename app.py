from flask import Flask, render_template, request, jsonify
from litellm import completion
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size
app.config['UPLOAD_FOLDER'] = 'uploads'

# LiteLLM configuration
LITELLM_API_BASE = os.getenv('LITELLM_API_BASE', 'http://localhost:8000')  # Default to localhost
LITELLM_MODEL = os.getenv('LITELLM_MODEL', 'gpt-3.5-turbo')  # Default model
LITELLM_API_KEY = os.getenv('LITELLM_API_KEY', '')  # API key if required

# Ensure upload directory exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        message = data.get('message', '')
        
        # Completion request using configured litellm server
        response = completion(
            model=LITELLM_MODEL,
            messages=[{"role": "user", "content": message}],
            api_base=LITELLM_API_BASE,
            api_key=LITELLM_API_KEY
        )
        
        return jsonify({
            'status': 'success',
            'response': response.choices[0].message.content
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'status': 'error', 'message': 'No file part'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'status': 'error', 'message': 'No selected file'}), 400
    
    if file:
        filename = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)
        file.save(filename)
        return jsonify({
            'status': 'success',
            'message': 'File uploaded successfully',
            'filename': file.filename
        })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)