import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from google.cloud import firestore
import json
import os

# 🔥 Set Google Application Credentials (Replace with your Firestore JSON key path)
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = r"D:\Rakshu\websocket_chat_application\python_server\websocketPrivatekey.json"

app = FastAPI()
db = firestore.Client()  # Firestore database client
connected_users = {}  # Store connected users: {user_id: websocket}


@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await websocket.accept()
    connected_users[user_id] = websocket  # Store user's WebSocket connection

    print(f"✅ User {user_id} connected!")

    try:
        while True:
            data = await websocket.receive_text()
            print(f"📩 Received from {user_id}: {data}")
            message = json.loads(data)

            chat_id = message["chatId"]
            sender_id = message["senderId"]
            receiver_id = message["receiverId"]  # Could be a user ID or "GROUP"
            text = message["message"]
            timestamp = message.get("timestamp", None)

            # ✅ Convert timestamp to Firestore's Timestamp format
            if timestamp is None:
                timestamp = firestore.SERVER_TIMESTAMP
            else:
                timestamp = firestore.Timestamp.from_milliseconds_since_epoch(timestamp)

            # ✅ Construct message data
            message_data = {
                "chatId": chat_id,
                "senderId": sender_id,
                "receiverId": receiver_id,
                "message": text,
                "timestamp": timestamp,
                "seen": False
            }

            # ✅ Store message in Firestore
            db.collection("chats").document(chat_id).collection("messages").add(message_data)
            print(f"📥 Message stored in Firestore: {message_data}")

            # ✅ Send message back to sender
            await websocket.send_text(json.dumps({
                **message_data,
                "timestamp": int(firestore.SERVER_TIMESTAMP.timestamp() * 1000)
                if timestamp == firestore.SERVER_TIMESTAMP else int(timestamp.timestamp() * 1000)
            }))

            # ✅ GROUP CHAT SUPPORT
            if receiver_id == "GROUP":
                # 🔁 Fetch group members from Firestore
                group_doc = db.collection("groups").document(chat_id).get()
                if group_doc.exists:
                    members = group_doc.to_dict().get("members", [])
                    for member_id in members:
                        if member_id != sender_id and member_id in connected_users:
                            await connected_users[member_id].send_text(json.dumps({
                                **message_data,
                                "timestamp": int(firestore.SERVER_TIMESTAMP.timestamp() * 1000)
                                if timestamp == firestore.SERVER_TIMESTAMP else int(timestamp.timestamp() * 1000)
                            }))
                            print(f"📤 Message sent to group member {member_id}")
                else:
                    print(f"⚠️ Group {chat_id} does not exist.")
            else:
                # ✅ 1-to-1 message
                if receiver_id in connected_users:
                    await connected_users[receiver_id].send_text(json.dumps({
                        **message_data,
                        "timestamp": int(firestore.SERVER_TIMESTAMP.timestamp() * 1000)
                        if timestamp == firestore.SERVER_TIMESTAMP else int(timestamp.timestamp() * 1000)
                    }))
                    print(f"📤 Message sent to receiver {receiver_id}")

    except WebSocketDisconnect:
        print(f"❌ User {user_id} disconnected!")
        if user_id in connected_users:
            del connected_users[user_id]  # Remove disconnected user


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=12345)