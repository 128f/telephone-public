from bson.objectid import ObjectId
from pymongo.mongo_client import MongoClient
from pymongo.read_preferences import ReadPreference

from dotenv import load_dotenv
load_dotenv()
import os;

conn_str = os.environ["CONNECTION_STRING"];
client = MongoClient(conn_str, serverSelectionTimeoutMS=5000, replicaSet="rs0", read_preference=ReadPreference.PRIMARY)

db = client.messages;
collection = db[os.environ['CURRENT_COLLECTION']];
test_user = os.environ['TEST_USER'];

# adds items to the database

def addPing(recipient):
    test_item = {
        "recipient": recipient,
        "message_type": "ping",
        "time": incessant(),
    };
    collection.insert_one(test_item);

def addPositive(recipient):
    test_item = {
        "_id": ObjectId("625cf06a653e6c909a306b0a"),
        "recipient": recipient,
        "message_type": "positive_message",
        "time": weekdaysPST(),
    };
    # collection.delete_one({ "_id": ObjectId("625cf06a653e6c909a306b0a") });
    collection.insert_one(test_item);

def weekdaysPST():
    return {
        "days": {
            "monday": True,
            "tuesday": True,
            "wednesday": True,
            "thursday": True,
            "friday": True,
            "saturday": False,
            "sunday": False,
        },
        "interval": {
            "start": 8,
            "end": 19
        },
        "mod": 2,
        "timezone": "US/Pacific"
    }

def incessant():
    return {
        "days": {
            "monday": True,
            "tuesday": True,
            "wednesday": True,
            "thursday": True,
            "friday": True,
            "saturday": True,
            "sunday": True,
        },
        "interval": {
            "start": 0,
            "end": 24
        },
        "mod": 0,
        "timezone": "US/Pacific"
    }

if __name__ == "__main__":
    addPositive()
    # addPing()
