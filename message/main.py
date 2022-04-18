import requests;
import random;
from dotenv import load_dotenv
load_dotenv()
import os;

# from bson.objectid import ObjectId
from pymongo.mongo_client import MongoClient
from pymongo.read_preferences import ReadPreference

conn_str = os.environ["CONNECTION_STRING"];
client = MongoClient(conn_str, serverSelectionTimeoutMS=5000, replicaSet="rs0", read_preference=ReadPreference.PRIMARY);

from datetime import datetime
import pytz

from_number=os.environ["FROM_NUMBER"]

positive_messages = [
        "You are important",
        "Hope you're having a really great day",
        "You've got this!",
        "Remember, you're strong",
        "You deserve success",
        "Remember to love yourself",
        "It's ok to have fun",
        "You're safe",
        "Believe in yourself",
        "Trust yourself to know what's best",
]

def send(to_number, body):
    account_sid = os.environ['ACCOUNT_SID']
    auth_token = os.environ['ACCOUNT_TOKEN']
    TWILIO_SMS_URL = "https://api.twilio.com/2010-04-01/Accounts/%s/Messages.json"%account_sid
    payload = {
        "To": to_number,
        "From": from_number,
        "Body": body,
    }
    requests.post(TWILIO_SMS_URL, data=payload, auth=(account_sid, auth_token))

db = client.messages;
collection = db[os.environ['CURRENT_COLLECTION']];

def constructMessage(message_type):
    if(message_type == "ping"):
        return "ping";
    if(message_type == "positive_message"):
        return random.choice(positive_messages);

def sendAllMessages():
    now = datetime.now();
    now = pytz.timezone("UTC").localize(now).astimezone(pytz.timezone("US/Pacific"))
    weekday = now.weekday();
    hour = now.hour;
    for match in collection.find({
        "$and": [
            # avoiding timezone conversion fun
            { "time.timezone": { "$eq": "US/Pacific"}},
            { "$or": [
                {"time.days.monday": { "$eq": weekday == 0 }},
                {"time.days.tuesday": { "$eq": weekday == 1}},
                {"time.days.wednesday": { "$eq": weekday == 2}},
                {"time.days.thursday": { "$eq": weekday == 3}},
                {"time.days.friday": { "$eq": weekday == 4}},
                {"time.days.saturday": { "$eq": weekday == 5}},
                {"time.days.sunday": { "$eq": weekday == 6}},
            ]},
            { "time.interval.start": {
                "$lt": hour
            }},
            { "time.interval.end": {
                "$gt": hour
            }}
        ]
    }):
        if(not hour % match['time']['mod']):
            continue;
        send(match['recipient'], constructMessage(match['message_type']))

def sendMessage_handler(event, context):
    sendAllMessages()
    return 200

if __name__ == "__main__":
    sendMessage_handler(0, 0)
