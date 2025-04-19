# FireChats
A real-time chat app with WebSocket support using FastAPI and Firebase for authentication and data storage. Supports group and individual chats with file sharing.

## Table of Contents
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Firestore Structure](#-firestore-structure)
- [Screenshots](#-screenshots)
- [Installation](#-installation)
- [Future Improvements](#-future-improvements)
- [Contributing](#-contributing)
- [License](#-license)

 ## 🚀 Features

- 🔐 Firebase Authentication for secure login/signup.
- 💬 One-on-one and group chat support.
- ⚡ Real-time messaging using WebSockets (FastAPI).
- 🧾 Messages stored in structured collections in Firestore.
- 🧑‍🤝‍🧑 Group creation, adding/removing members, and exiting groups.
- 📁 File sharing (PDF, images, etc.).
- ✅ Seen/unseen message status.

## 🛠️ Tech Stack

- **Frontend:** Flutter
- **Backend:** FastAPI (WebSockets)
- **Authentication:** Firebase Auth
- **Database:** Firebase Firestore
- **Storage:** Firebase Storage

## 🧾 Firestore Structure

Firestore Root
│
├── users (Collection)
│   └── <uid> (Document)
│       ├── name: string
│       ├── email: string
│       ├── profileImage: string
│       └── isOnline: boolean
│
├── chats (Collection)
│   └── <chatId> (Document)
│       ├── participants: [uid1, uid2]
│       ├── lastMessage: string
│       ├── timestamp: Timestamp
│
│   └── messages (Subcollection)
│       └── <messageId> (Document)
│           ├── message: string
│           ├── senderId: string
│           ├── receiverIds: [string] (supports group extension)
│           ├── timestamp: Timestamp
│           └── seen: boolean
│
├── groups (Collection)
│   └── <groupId> (Document)
│       ├── name: string
│       ├── adminId: string
│       ├── members: [uid1, uid2, ...]
│       ├── createdAt: Timestamp
│
│   └── messages (Subcollection)
│       └── <messageId> (Document)
│           ├── message: string
│           ├── senderId: string
│           ├── timestamp: Timestamp
│           └── seenBy: [uid1, uid2]




