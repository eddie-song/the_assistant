from flask import Flask, request
import tempfile
from pydub import AudioSegment
from pydub.utils import which
from vosk import Model, KaldiRecognizer
import wave
import json
import os

app = Flask(__name__)

os.environ["FFMPEG_BINARY"] = r"C:\ProgramData\chocolatey\bin\ffmpeg.exe"
os.environ["FFPROBE_BINARY"] = r"C:\ProgramData\chocolatey\bin\ffprobe.exe"

# Load the Vosk model once
model = Model("model")

@app.route("/transcribe", methods=["POST"])
def transcribe():
    try:
        audio_file = request.files["audio"]

        # Save uploaded file to temp WAV
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            audio_file.save(tmp.name)
            print("Uploaded file saved to:", tmp.name)

        # Convert to PCM WAV (pydub)
        pcm_path = tmp.name.replace(".wav", "_pcm.wav")
        AudioSegment.converter = r"C:\ProgramData\chocolatey\bin\ffmpeg.exe"
        sound = AudioSegment.from_file(tmp.name)
        sound = sound.set_channels(1)
        sound.export(pcm_path, format="wav", codec="pcm_s16le")
        print("PCM-converted file at:", pcm_path)

        wf = wave.open(pcm_path, "rb")
        print("Channels:", wf.getnchannels())
        print("Sample Rate:", wf.getframerate())
        print("Sample Width:", wf.getsampwidth())

        # Verify PCM file exists
        if not os.path.exists(pcm_path):
            raise FileNotFoundError(f"PCM file not found: {pcm_path}")

        # Open and transcribe
        wf = wave.open(pcm_path, "rb")
        rec = KaldiRecognizer(model, wf.getframerate())

        result = ""
        while True:
            data = wf.readframes(4000)
            if len(data) == 0:
                break
            if rec.AcceptWaveform(data):
                res = json.loads(rec.Result())
                result += res.get("text", "") + " "
        res = json.loads(rec.FinalResult())
        result += res.get("text", "")

        print("Transcription result:", result.strip())
        return result.strip()

    except Exception as e:
        print("🔥 Error:", e)
        return f"Error during transcription: {str(e)}", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
