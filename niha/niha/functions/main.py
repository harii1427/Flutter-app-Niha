import firebase_admin
from firebase_admin import credentials, firestore
import time
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import google.generativeai as genai

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
        return (f'Failed to send email: {e}')

def fetch_and_process_commands():
    while True:
        try:
            commands_ref = db.collection('command_C001')
            commands = commands_ref.stream()

            for command in commands:
                c = command.to_dict()
                print(f'Received command: {c}')
                query = c['command']
                
                response = handle_command(query, c['userId'])
                
                db.collection('responses').add({
                    'response': response,
                    'userId': c['userId'],
                    'timestamp': firestore.SERVER_TIMESTAMP,
                })
                command.reference.delete()
            time.sleep(2)  

        except Exception as e:
            print(f"Error fetching or processing commands: {e}")

def handle_command(query, user_id):
    query = query.lower()
    if query == "food":
        return list_food_items()
    elif query.startswith("order"):
        food_name = query.replace("order", "").strip()
        return order_food(food_name, user_id)
    else:
        return get_response_from_gemini(query)

def list_food_items():
    try:
        food_items = set()
        hotel_details_ref = db.collection('Hotel_details')
        docs = hotel_details_ref.stream()
        for doc in docs:
            food_items.add(doc.to_dict().get('Food'))
        return "Available food items: " + ", ".join(food_items)
    except Exception as e:
        print(f"Error listing food items: {e}")
        return "Error fetching food items"

def order_food(food_name, user_id):
    try:
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()
        if not user_doc.exists:
            return "User details not found"

        user_data = user_doc.to_dict()
        user_email = user_data.get('email')
        user_address = user_data.get('address')
        hotel_details_ref = db.collection('Hotel_details')
        hotel_query = hotel_details_ref.where('Food', '==', food_name).limit(1)
        hotel_docs = hotel_query.stream()
        hotel_doc = next(hotel_docs, None)
        if hotel_doc is None:
            return f"No hotels found serving {food_name}"

        hotel_data = hotel_doc.to_dict()
        hotel_name = hotel_data.get('Hotel_name')
        hotel_email= hotel_data.get("E-mail")
        order_message = f"Order request for {food_name} from {user_email}. Delivery address: {user_address}"
        send_email(hotel_email, f'Order Request for {food_name}', order_message)
        return f"Order placed for {food_name} at {hotel_name}"
    except Exception as e:
        return f"Error placing order: {e}"

def get_response_from_gemini(query):
    try:
        chat = gemini_model.start_chat(history=[])
        response = chat.send_message(query, stream=False)
        if response and hasattr(response, 'text'):
            return response.text 
        return "No response"
    except Exception as e:
        return "Error getting response "


if __name__ == "__main__":
    fetch_and_process_commands()
