#!/bin/bash

# Exit on any error
set -e

echo "Setting up LLM Chat Interface on Raspberry Pi..."

# Create project directory
echo "Creating project directory..."
mkdir -p llm-chat-interface
cd llm-chat-interface

# Create necessary directories
echo "Creating application structure..."
mkdir -p static/css static/js templates uploads

# Create virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install flask==3.0.0 litellm==1.16.8 python-dotenv==1.0.0

# Download application files
echo "Creating application files..."

# Create app.py
cat > app.py << 'EOL'
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
EOL

# Create index.html (content remains the same)
cat > templates/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Raspberry Pi LLM Chat</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            padding: 20px;
            max-width: 1200px;
            margin: 0 auto;
            background-color: #f5f5f5;
        }

        .chat-container {
            background-color: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 20px;
            margin-bottom: 20px;
        }

        .chat-messages {
            height: 60vh;
            overflow-y: auto;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            margin-bottom: 20px;
        }

        .message {
            margin-bottom: 15px;
            padding: 10px;
            border-radius: 5px;
        }

        .user-message {
            background-color: #e3f2fd;
            margin-left: 20%;
        }

        .bot-message {
            background-color: #f5f5f5;
            margin-right: 20%;
        }

        .input-container {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }

        textarea {
            flex-grow: 1;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            resize: none;
            height: 60px;
        }

        button {
            padding: 10px 20px;
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }

        button:hover {
            background-color: #0056b3;
        }

        .file-upload {
            margin-bottom: 20px;
        }

        .file-upload input[type="file"] {
            display: none;
        }

        .file-upload label {
            padding: 10px 20px;
            background-color: #28a745;
            color: white;
            border-radius: 5px;
            cursor: pointer;
            display: inline-block;
        }

        .file-upload label:hover {
            background-color: #218838;
        }

        #uploadStatus {
            margin-top: 10px;
            color: #666;
        }

        @media (max-width: 768px) {
            body {
                padding: 10px;
            }
            
            .user-message, .bot-message {
                margin-left: 0;
                margin-right: 0;
            }
        }
    </style>
</head>
<body>
    <div class="chat-container">
        <div class="chat-messages" id="chatMessages"></div>
        
        <div class="file-upload">
            <label for="fileInput">
                📎 Attach File
                <input type="file" id="fileInput" onchange="handleFileUpload()">
            </label>
            <div id="uploadStatus"></div>
        </div>

        <div class="input-container">
            <textarea id="userInput" placeholder="Type your message here..." onkeydown="if(event.keyCode === 13 && !event.shiftKey) { event.preventDefault(); sendMessage(); }"></textarea>
            <button onclick="sendMessage()">Send</button>
        </div>
    </div>

    <script>
        function appendMessage(content, isUser) {
            const messagesDiv = document.getElementById('chatMessages');
            const messageDiv = document.createElement('div');
            messageDiv.className = `message ${isUser ? 'user-message' : 'bot-message'}`;
            messageDiv.textContent = content;
            messagesDiv.appendChild(messageDiv);
            messagesDiv.scrollTop = messagesDiv.scrollHeight;
        }

        async function sendMessage() {
            const input = document.getElementById('userInput');
            const message = input.value.trim();
            
            if (!message) return;
            
            appendMessage(message, true);
            input.value = '';

            try {
                const response = await fetch('/chat', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ message })
                });

                const data = await response.json();
                
                if (data.status === 'success') {
                    appendMessage(data.response, false);
                } else {
                    appendMessage('Error: ' + data.message, false);
                }
            } catch (error) {
                appendMessage('Error: Could not connect to server', false);
            }
        }

        async function handleFileUpload() {
            const fileInput = document.getElementById('fileInput');
            const uploadStatus = document.getElementById('uploadStatus');
            const file = fileInput.files[0];

            if (!file) return;

            const formData = new FormData();
            formData.append('file', file);

            uploadStatus.textContent = 'Uploading...';

            try {
                const response = await fetch('/upload', {
                    method: 'POST',
                    body: formData
                });

                const data = await response.json();
                
                if (data.status === 'success') {
                    uploadStatus.textContent = `File uploaded: ${data.filename}`;
                    appendMessage(`File uploaded: ${data.filename}`, true);
                } else {
                    uploadStatus.textContent = 'Upload failed: ' + data.message;
                }
            } catch (error) {
                uploadStatus.textContent = 'Upload failed: Could not connect to server';
            }

            fileInput.value = '';
        }
    </script>
</body>
</html>
EOL

# Create .env template with LiteLLM configuration
echo "Creating .env template..."
cat > .env.template << 'EOL'
# LiteLLM Server Configuration
LITELLM_API_BASE=http://localhost:8000  # URL of your LiteLLM server
LITELLM_MODEL=gpt-3.5-turbo            # Default model to use
LITELLM_API_KEY=your_api_key_here      # API key if required by your LiteLLM server

# Optional: Additional API keys for different providers
# OPENAI_API_KEY=your_openai_key_here
# ANTHROPIC_API_KEY=your_anthropic_key_here
# COHERE_API_KEY=your_cohere_key_here
EOL

# Set correct permissions
echo "Setting permissions..."
chmod 755 app.py
chmod -R 755 static templates
chmod 777 uploads  # Allow write access for file uploads

echo "
Installation complete! To start the application:

1. Copy .env.template to .env and configure your LiteLLM settings:
   cp .env.template .env
   nano .env

   Important: Update LITELLM_API_BASE to point to your LiteLLM server
   (e.g., http://your-litellm-server:8000)

2. Activate the virtual environment:
   source venv/bin/activate

3. Start the application:
   python app.py

4. Access the interface at:
   http://$(hostname -I | awk '{print $1}'):5000

Note: Ensure your LiteLLM server is running and accessible before starting the application.
"