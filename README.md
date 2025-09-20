# The Assistant - Calendar App

A Flutter-based calendar application with voice command integration and Firebase backend.

## Features

- Calendar view with event management
- Voice command processing
- Firebase authentication and data storage
- OpenAI integration for natural language processing
- Speech-to-text functionality

## Setup Instructions

### 1. Environment Configuration

1. Copy the example environment file:
   ```bash
   cp env.example .env
   ```

2. Copy the Firebase configuration template:
   ```bash
   cp firebase.json.example firebase.json
   ```

3. Update `.env` with your actual credentials:
   - Get your Firebase API key from Firebase Console
   - Get your OpenAI API key from OpenAI Platform
   - Replace all placeholder values in `.env`

4. Update `firebase.json` with your Firebase project details:
   - Replace `your-project-id` with your Firebase project ID
   - Replace `your-app-id` with your Firebase app ID

### 2. Dependencies

Install Flutter dependencies:
```bash
flutter pub get
```

### 3. Python Backend

The Python backend requires additional setup:

```bash
cd lib/python_backend
pip install -r requirements.txt
```

### 4. Running the Application

1. Start the Python backend:
   ```bash
   cd lib/python_backend
   python app.py
   ```

2. Start the speech recognition server:
   ```bash
   cd lib/python_backend
   python vosk_server.py
   ```

3. Run the Flutter app:
   ```bash
   flutter run
   ```
