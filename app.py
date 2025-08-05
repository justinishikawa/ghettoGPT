from flask import Flask, render_template, request, jsonify
from litellm import completion
from openai import OpenAI
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

# OpenRouter configuration
OPENROUTER_API_KEY = os.getenv('OPENROUTER_API_KEY', '')  # API key for OpenRouter
OPENROUTER_MODEL = os.getenv('OPENROUTER_MODEL', 'openrouter/auto')  # Default model

# Ensure upload directory exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# Initialize OpenAI client for OpenRouter
openrouter_client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=OPENROUTER_API_KEY,
)

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        message = data.get('message', '')
        provider = data.get('provider', 'litellm')  # Default to LiteLLM
        
        if provider == 'openrouter':
            # Completion request using OpenRouter via OpenAI SDK
            response = openrouter_client.chat.completions.create(
                model=OPENROUTER_MODEL,
                messages=[{"role": "user", "content": message}],
            )
            content = response.choices[0].message.content
        else:
            # Completion request using configured LiteLLM server
            response = completion(
                model=LITELLM_MODEL,
                messages=[{"role": "user", "content": message}],
                api_base=LITELLM_API_BASE,
                api_key=LITELLM_API_KEY
            )
            content = response.choices[0].message.content
        
        return jsonify({
            'status': 'success',
            'response': content
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