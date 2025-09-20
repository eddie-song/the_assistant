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

## Security

This project uses environment variables to store sensitive credentials. Never commit your `.env` file or actual `firebase.json` with real credentials to version control.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
