from flask import Flask, request, jsonify
import os
import json
from dotenv import load_dotenv
from openai import OpenAI

# Load environment variables
load_dotenv()

# Initialize OpenAI client
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Create Flask app
app = Flask(__name__)

# Use your full prompt exactly
BASE_PROMPT = """
You are a calendar assistant. Extract the structured intent from the user's natural language command.

Respond with a valid JSON object containing:
- action (string): one of "create_event", "delete_event", "get_schedule", "clear_schedule", "create_reminder", or "unknown"
- title (string, optional): name of the event or reminder
- date (string, optional): format YYYY-MM-DD
- time (string, optional): format HH:MM in 24-hour time
- recurrence (string, optional): e.g. "daily", "every Monday"
- response (string): a short friendly message to show the user, confirming what you understood

For the title, please come up with an appropriate title with proper capitalization.
If the user doesn't specify a title, please label the title as "Untitled Event".

Always include a `response`. If you do not understand the command, return:
{
  "action": "unknown",
  "response": "Sorry, I didn’t quite catch that. Could you try rephrasing?"
}

Examples:

Command: "Create a dentist appointment on April 30 at 3pm"
{
  "action": "create_event",
  "title": "dentist appointment",
  "date": "2025-04-30",
  "time": "15:00",
  "response": "Sure! I've scheduled your dentist appointment on April 30 at 3:00 PM."
}

Command: "Delete my team meeting on May 2"
{
  "action": "delete_event",
  "title": "team meeting",
  "date": "2025-05-02",
  "response": "Okay, I’ve deleted your team meeting on May 2."
}

Command: "What's on my calendar for tomorrow?"
{
  "action": "get_schedule",
  "date": "2025-04-22",
  "response": "Let me show you what’s on your schedule for April 22."
}

Command: "Remind me to take medicine every night at 9pm"
{
  "action": "create_reminder",
  "title": "take medicine",
  "time": "21:00",
  "recurrence": "daily",
  "response": "Got it! I'll remind you to 'take medicine' every night at 9:00 PM."
}

Command: "Clear my calendar for April 28"
{
  "action": "clear_schedule",
  "date": "2025-04-28",
  "response": "Okay, I’ll clear your calendar for April 28."
}
"""

@app.route("/parse", methods=["POST"])
def parse_command():
    user_input = request.json.get("command")
    print(user_input)
    if not user_input:
        return jsonify({"error": "No command provided"}), 400

    full_prompt = f"{BASE_PROMPT}\n\nCommand: \"{user_input}\""

    try:
        completion = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a calendar assistant."},
                {"role": "user", "content": full_prompt}
            ],
            temperature=0.2
        )

        result_text = completion.choices[0].message.content.strip()
        print(result_text)

        try:
            result = json.loads(result_text)
        except Exception:
            return jsonify({
                "error": "Failed to parse GPT response as JSON",
                "raw_response": result_text
            }), 500

        return jsonify(result)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)
