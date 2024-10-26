import firebase_admin
from firebase_admin import credentials, firestore
import speech_recognition as sr
import pyttsx3
import time
from difflib import SequenceMatcher
import pywhatkit

# Path to your service account key
cred = credentials.Certificate("niha.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

# Initialize speech recognizer and text-to-speech engine
recognizer = sr.Recognizer()
tts_engine = pyttsx3.init()

def speak_text(text):
    tts_engine.say(text)
    tts_engine.runAndWait()

def listen_and_recognize():
    with sr.Microphone() as source:
        print("Listening...")
        audio = recognizer.listen(source)
        try:
            text = recognizer.recognize_google(audio)
            print(f"Recognized: {text}")
            return text
        except sr.UnknownValueError:
            print("Could not understand the audio")
            return None
        except sr.RequestError as e:
            print(f"Could not request results; {e}")
            return None

def fetch_commands_from_firestore():
    commands_list = []
    try:
        doc = db.collection('commands').document('commandsList').get()
        if doc.exists:
            commands_list = doc.to_dict().get('commands', [])
    except Exception as e:
        print(f"Error fetching commands: {e}")
    return commands_list

def correct_word(input_word, word_list):
    normalized_input = input_word.lower().strip()
    matches = [
        {'word': word, 'similarity': SequenceMatcher(None, normalized_input, word.lower().strip()).ratio()}
        for word in word_list
    ]
    matches.sort(key=lambda x: x['similarity'], reverse=True)
    if matches and matches[0]['similarity'] > 0.6:
        return matches[0]['word']
    return input_word  # Return the original word if no close match found

def correct_command(input_command, command_list):
    input_words = input_command.split(' ')
    corrected_words = [correct_word(word, command_list) for word in input_words]
    return ' '.join(corrected_words)

def send_command_to_firestore(command):
    commands_list = fetch_commands_from_firestore()
    corrected_command = correct_command(command, commands_list)
    if corrected_command:
        user_id = "default_user_id"  # Replace with actual user ID
        db.collection('command_C001').add({
            'command': corrected_command,
            'userId': user_id,
            'timestamp': firestore.SERVER_TIMESTAMP,
        })

def fetch_responses():
    user_id = "default_user_id"  # Replace with actual user ID
    responses_ref = db.collection('responses').where('userId', '==', user_id)
    docs = responses_ref.stream()
    for doc in docs:
        response = doc.to_dict().get('response')
        print(f"Response: {response}")
        speak_text(response)
        doc.reference.delete()

def fetch_and_delete_songs():
    songs_ref = db.collection('song')
    docs = songs_ref.stream()
    for doc in docs:
        song = doc.to_dict().get('song')
        print(f"Playing song: {song}")
        play = song.replace('play', '')
        doc.reference.delete()
        pywhatkit.playonyt(play)
        
def on_snapshot(doc_snapshot, changes, read_time):
    print("Snapshot received")
    for doc in doc_snapshot:
        doc_id, status = doc.id, doc.to_dict().get('state')
        if status is not None:
            print(f"{doc_id.replace('_', ' ').capitalize()}: {status}")

collection_ref = db.collection('command_C001').document('Appliances').collection('home_automation')
collection_ref.on_snapshot(on_snapshot)

if __name__ == "__main__":
    while True:
        command = listen_and_recognize()
        if command:
            send_command_to_firestore(command)
            time.sleep(5)  # Wait for a few seconds to get the response
            fetch_responses()
            fetch_and_delete_songs()
