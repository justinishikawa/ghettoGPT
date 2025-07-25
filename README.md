# Raspberry Pi LLM Chat Interface

A lightweight web interface for interacting with LLMs through litellm, designed specifically for Raspberry Pi devices.

## Features

- Simple, responsive web interface
- File upload capability
- Integration with various LLM models through litellm
- Optimized for low-powered devices

## Requirements

- Raspberry Pi (any model)
- Python 3.7+
- pip package manager

## Installation

1. Clone this repository to your Raspberry Pi:
```bash
git clone <your-repo-url>
cd <repo-directory>
```

2. Create and activate a virtual environment (recommended):
```bash
python -m venv venv
source venv/bin/activate  # On Linux/Raspberry Pi OS
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

## Configuration

1. Create a `.env` file in the project root:
```bash
touch .env
```

2. Add your LLM API configuration to the `.env` file:
```
OPENAI_API_KEY=your_api_key_here
# Add other API keys as needed
```

## Usage

1. Start the server:
```bash
python app.py
```

2. Access the web interface:
- Open a web browser on any device in your local network
- Navigate to `http://<raspberry-pi-ip>:5000`
  (Replace `<raspberry-pi-ip>` with your Raspberry Pi's IP address)

## Performance Optimization Tips

1. Limit concurrent connections to prevent overload
2. Use lightweight models when possible
3. Clear the uploads folder periodically to manage storage
4. Monitor RAM usage and restart the service if needed

## Security Notes

- This server is intended for local network use only
- Do not expose the server to the public internet without proper security measures
- Keep your API keys secure and never commit them to version control

## Troubleshooting

1. If the server fails to start:
   - Check if port 5000 is available
   - Ensure all dependencies are installed
   - Verify Python version compatibility

2. If file uploads fail:
   - Check the permissions of the uploads directory
   - Verify the file size is within limits (default 16MB)

3. If LLM responses are slow:
   - Consider using a lighter model
   - Check your network connection
   - Monitor CPU usage and temperature

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License - feel free to use this project as you wish.