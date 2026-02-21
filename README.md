# FireChats

A scalable real-time chat application built using **Flutter**, **FastAPI (WebSocket)**, and **Firebase Firestore**.

This project demonstrates real-time messaging architecture, distributed system design concepts, and backend WebSocket communication.

---

## 🚀 Features

- 🔹 One-to-One Chat
- 🔹 Group Chat
- 🔹 Real-Time Messaging via WebSocket
- 🔹 Message Persistence using Firestore
- 🔹 Typing Indicator
- 🔹 Seen/Read Receipts
- 🔹 Automatic Reconnection Handling
- 🔹 Duplicate Message Prevention
- 🔹 Message Ordering by Server Timestamp

---

## 🏗️ Architecture Overview

```
Flutter Client
       │
       ▼
FastAPI WebSocket Server
       │
       ▼
Firebase Firestore
```

### Message Flow

1. User sends message from Flutter client
2. Message is sent to FastAPI WebSocket server
3. Server saves message to Firestore
4. Server broadcasts message to recipient(s)
5. Recipient UI updates instantly

The system separates **real-time transport** (WebSocket) from **data persistence** (Firestore).

---

## 🛠️ Tech Stack

### Frontend
- Flutter
- Dart
- WebSocket Client

### Backend
- FastAPI
- Python
- WebSocket (async handling)

### Database
- Firebase Firestore

---

## 📂 Database Structure (Firestore)

### Collections

#### `users`
```
users/{userId}
```

#### `chats`
```
chats/{chatId}
    └── messages/{messageId}
```

#### `groups`
```
groups/{groupId}
    └── groupMessages/{messageId}
```

### Message Document Structure

```json
{
  "messageId": "uuid",
  "senderId": "user123",
  "content": "Hello!",
  "timestamp": "serverTimestamp",
  "seenBy": ["user456"]
}
```

---

## 🔌 WebSocket Design (FastAPI)

- Maintains active connection map: `userId → WebSocket`
- Handles:
  - Connection lifecycle (connect/disconnect)
  - Broadcasting messages
  - Reconnection handling
- Asynchronous implementation using `async/await`

---

## 📈 Scalability Considerations

Currently runs as a single WebSocket instance.

For large-scale systems (e.g., millions of users), future improvements include:

- Load balancer
- Horizontal scaling of WebSocket servers
- Redis Pub/Sub for cross-instance messaging
- Chat data sharding
- Server-authoritative architecture

---

## 🧠 System Design Concepts Used

- Real-Time Communication
- Event-Driven Architecture
- Idempotency
- At-least-once Delivery Handling
- Eventual Consistency
- Distributed Connection Management

---

## 🔧 Installation & Setup

### Backend (FastAPI)

```bash
uvicorn main:app --reload
```

### Frontend (Flutter)

```bash
flutter pub get
flutter run
```

---

## 📌 Future Improvements

- Push notifications (FCM)
- End-to-End Encryption
- Message reactions
- Media uploads
- Message search with indexing
- Docker deployment

---

## 🎯 Learning Outcomes

This project helped in understanding:

- WebSocket connection management
- Distributed system challenges
- Real-time data synchronization
- Scalable chat architecture
- Backend + Database integration

---

## 👨‍💻 Author

Sai Rakshithaa S  
GitHub: https://github.com/SaiRakshithaa

---


