import torch
import torch.nn as nn
from transformers import BertTokenizer
import joblib
import firebase_admin
from firebase_admin import credentials, firestore
import time
import json
import numpy as np
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import google.generativeai as genai
import random
import re
import wikipedia
import logging

# Setup logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

cred = credentials.Certificate("niha.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

GOOGLE_API_KEY = 'AIzaSyC9LNmJ8-QcWVfeYJm-ECGgXtqobvJli_U'
genai.configure(api_key=GOOGLE_API_KEY)
gemini_model = genai.GenerativeModel('gemini-pro')

SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587
EMAIL_ADDRESS = 'hariharan5295@gmail.com'
EMAIL_PASSWORD = 'vdlb esck xhlr ldbo'
conversation_buffer = {}

class ResidualBlock(nn.Module):
    def __init__(self, hidden_dim):
        super(ResidualBlock, self).__init__()
        self.layer1 = nn.Linear(hidden_dim, hidden_dim)
        self.bn1 = nn.BatchNorm1d(hidden_dim)
        self.relu = nn.ReLU()
        self.layer2 = nn.Linear(hidden_dim, hidden_dim)
        self.bn2 = nn.BatchNorm1d(hidden_dim)
        self.dropout = nn.Dropout(0.5)
        
    def forward(self, x):
        identity = x
        out = self.layer1(x)
        out = self.bn1(out)
        out = self.relu(out)
        out = self.layer2(out)
        out = self.bn2(out)
        out = self.dropout(out)
        out += identity
        out = self.relu(out)
        return out

class DeepLLMModel(nn.Module):
    def __init__(self, vocab_size, embed_dim, hidden_dim, output_dim, num_layers=500):
        super(DeepLLMModel, self).__init__()
        self.embedding = nn.Embedding(vocab_size, embed_dim, padding_idx=0)
        self.input_layer = nn.Linear(embed_dim, hidden_dim)
        self.deep_layers = nn.Sequential(
            *[ResidualBlock(hidden_dim) for _ in range(num_layers)]
        )
        self.output_layer = nn.Linear(hidden_dim, output_dim)
        
    def forward(self, x):
        x = self.embedding(x).mean(dim=1)  # Average the embeddings
        x = self.input_layer(x)
        x = self.deep_layers(x)
        out = self.output_layer(x)
        return out

def load_model(model_class, vocab_size, embed_dim, hidden_dim, output_dim, num_layers, load_path):
    model = model_class(vocab_size, embed_dim, hidden_dim, output_dim, num_layers)
    model.load_state_dict(torch.load(load_path))
    model.eval()  # Set the model to evaluation mode
    return model

def generate_response(model, command, tokenizer, label_encoder, max_length=50):
    try:
        command_encoded = tokenizer.encode(command, add_special_tokens=True, padding='max_length', truncation=True, max_length=max_length)
        command_tensor = torch.tensor([command_encoded])
        
        with torch.no_grad():
            output = model(command_tensor)
            predicted_response_idx = output.argmax(dim=1).item()
            predicted_response = label_encoder.inverse_transform([predicted_response_idx])[0]
        return predicted_response
    except Exception as e:
        logging.error(f"Error generating response: {e}")
        return None

def send_email(to_email, subject, body):
    msg = MIMEMultipart()
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = to_email
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))
    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        text = msg.as_string()
        server.sendmail(EMAIL_ADDRESS, to_email, text)
        server.quit()
    except Exception as e:
        logging.error(f'Failed to send email: {e}')

def fetch_and_process_commands():
    while True:
        try:
            logging.info("Fetching commands from Firestore...")
            commands_ref = db.collection('command_C001')
            commands = commands_ref.stream()

            for command in commands:
                c = command.to_dict()
                logging.debug(f"Received command: {c}")
                  
                if 'command' not in c or 'userId' not in c:
                    logging.warning("Received a malformed command")
                    continue
                
                query = c['command']
                tokenizer_dir = './tokenizer'
                tokenizer = BertTokenizer.from_pretrained(tokenizer_dir)
                
                # Load the label encoder
                label_encoder = joblib.load('label_encoder.pkl')
                
                # Define model parameters
                vocab_size = len(tokenizer)
                embed_dim = 128
                hidden_dim = 256
                output_dim = len(label_encoder.classes_)
                
                # Load the model
                model = load_model(DeepLLMModel, vocab_size, embed_dim, hidden_dim, output_dim, num_layers=1, load_path='deep_llm_model.pth')
                
                # Generate a response
                response = generate_response(model, query, tokenizer, label_encoder)
                logging.debug(f"Generated response: {response}")
                
                if not response:
                    logging.error("Model generated a null response")
                    continue
                
                user_response = handle_command(response, query, c['userId'])
                logging.debug(f"User response: {user_response}")
                
                db.collection('responses').add({
                    'response': user_response,
                    'userId': c['userId'],
                    'timestamp': firestore.SERVER_TIMESTAMP,
                })
                command.reference.delete()
            time.sleep(2)

        except Exception as e:
            logging.error(f"Error fetching or processing commands: {e}")

def handle_command(response, query, user_id):
    response = response.lower()
    query = query.lower()
    
    appliances = fetch_appliances()
    for appliance, status in appliances.items():
        if response == f"{appliance} on":
            update_appliance_status(appliance, "on")
            logging.info(f"Turning on {appliance}")
            return f"{appliance.capitalize()} is turned on"
        elif response == f"{appliance} off":
            update_appliance_status(appliance, "off")
            logging.info(f"Turning off {appliance}")
            return f"{appliance.capitalize()} is turned off"

    if response == "list_food_items":
        return list_food_items()
    elif response == "search":
        return wikipedia_search(query, user_id)
    elif query.startswith("order"):
        match = re.match(r"order (\d+) (.+)", query)
        if match:
            quantity = int(match.group(1))
            food_name = match.group(2).strip()
        else:
            quantity = 1
            food_name = query.replace("order", "").strip()
        return initiate_order_process(food_name, user_id, quantity)
    elif query.startswith("select hotel"):
        hotel_index = int(query.split()[-1])
        return select_hotel(user_id, hotel_index)
    elif response == "select any hotel":
        return random_hotel_choice(user_id)
    elif response == "confirm":
        return confirm_order(user_id)
    elif response == "play":
        add_song_to_firestore(query, user_id)
        return "Playing your requested song."
    else:
        if response == "order":
            return "Please give a request for order food in this format order <quantity> <food>"
        elif response in ["fan on", "light on", "ac on", "fan off", "light off", "ac off"]:
            return "Please add appliances in the application"
        elif response == "select hotel":
            return "Please give a command to select hotel in this format select hotel <hotel number>"
        else:
            return "Sorry, I can't assist with this question."

def fetch_appliances():
    try:
        appliances = {}
        appliances_ref = db.collection('command_C001').document('Appliances').collection('home_automation')
        docs = list(appliances_ref.stream())
        logging.debug(f"Documents found: {len(docs)}")
        for doc in docs:
            doc_dict = doc.to_dict()
            logging.debug(f"Document ID: {doc.id}, Data: {doc_dict}")
            appliance_name = doc.id.replace('_status', '')
            appliances[appliance_name] = doc_dict.get('state')
        logging.debug(f"Fetched appliances: {appliances}")
        return appliances
    except Exception as e:
        logging.error(f"Error fetching appliances: {e}")
        return {}

def update_appliance_status(appliance, status):
    try:
        doc_id = f"{appliance}_status"
        db.collection('command_C001').document('Appliances').collection('home_automation').document(doc_id).set({
            'state': status,
        })
        logging.info(f"Updated {appliance} status to {status}")
    except Exception as e:
        logging.error(f"Error updating {appliance} status: {e}")

def list_food_items():
    try:
        food_items = set()
        hotel_details_ref = db.collection('Hotel_details')
        docs = hotel_details_ref.stream()
        for doc in docs:
            food_items.add(doc.to_dict().get('Food'))
        return "Available food items: " + ", ".join(food_items)
    except Exception as e:
        logging.error(f"Error listing food items: {e}")
        return "Error fetching food items."

def wikipedia_search(query, user_id):
    try:
        search_results = wikipedia.summary(query, sentences=3)
        return f"{search_results}"
    except Exception as e:
        logging.error(f"Error in Wikipedia search: {e}")
        return f"Error fetching Wikipedia search results for {query}."

def initiate_order_process(food_name, user_id, quantity):
    try:
        hotel_details_ref = db.collection('Hotel_details')
        hotel_query = hotel_details_ref.where('Food', '==', food_name)
        hotels = list(hotel_query.stream())
        if not hotels:
            return f"No hotels found serving {food_name}"

        hotel_options = []
        for hotel_doc in hotels:
            hotel_data = hotel_doc.to_dict()
            hotel_name = hotel_data.get('Hotel_name')
            price = hotel_data.get('Price')
            hotel_options.append((hotel_name, price))

        conversation_buffer[user_id] = {
            'food_name': food_name,
            'quantity': quantity,
            'hotel_options': hotel_options,
            'selected_hotel': None
        }

        hotel_list = "\n".join([f"{i+1}. {hotel[0]} for {hotel[1]} Rupees" for i, hotel in enumerate(hotel_options)])
        return f"{food_name} is available at the following hotels:\n{hotel_list}\nPlease select a hotel by saying 'select hotel <number>' or 'select any hotel' to select randomly."
    except Exception as e:
        return f"Error fetching food details: {e}"

def select_hotel(user_id, hotel_index):
    user_doc_ref = db.collection('command_C001').document(f'{user_id}')
    user_doc = user_doc_ref.get()
    if user_doc.exists:
        user_data = user_doc.to_dict()
        user_data['selected_hotel'] = hotel_index
        user_doc_ref.set(user_data)
        return f"Hotel {hotel_index} selected."
    else:
        return "User not found."

def random_hotel_choice(user_id):
    hotels = db.collection('Hotel_details').stream()
    hotel_list = [hotel.to_dict() for hotel in hotels]
    if hotel_list:
        selected_hotel = random.choice(hotel_list)
        select_hotel(user_id, selected_hotel['hotel_number'])
        return f"Randomly selected hotel {selected_hotel['hotel_number']}."
    else:
        return "No hotels available."

def confirm_order(user_id):
    user_doc_ref = db.collection('command_C001').document(f'{user_id}')
    user_doc = user_doc_ref.get()
    if user_doc.exists:
        user_data = user_doc.to_dict()
        if 'current_order' in user_data:
            order = user_data.pop('current_order')
            user_doc_ref.set(user_data)
            send_email(user_data['email'], "Order Confirmation", f"Your order has been confirmed: {order}")
            return f"Order confirmed: {order}"
        else:
            return "No current order to confirm."
    else:
        return "User not found."

def add_song_to_firestore(query, user_id):
    song_request = query.replace("play", "").strip()
    db.collection('command_C001').document(user_id).collection('song_requests').add({
        'song': song_request,
        'timestamp': firestore.SERVER_TIMESTAMP,
    })
    logging.info(f"Added song request for {user_id}: {song_request}")

if __name__ == "__main__":
    fetch_and_process_commands()
