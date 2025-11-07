# 💬 WS Chat Flutter

[![pub package](https://img.shields.io/pub/v/ws_chat_flutter.svg)](https://pub.dev/packages/ws_chat_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive real-time chat widget package for Flutter with AI assistance and seamless customer service handover, built with Socket.IO.

## ✨ Features

### 🎯 Customer Chat Screen
- 🤖 **AI-Powered Responses** - Instant automated replies using AI
- 👤 **Human CS Handover** - Seamless transfer to human agents
- 📱 **Responsive Design** - Works on phones, tablets, and web
- 💬 **Real-time Messaging** - Instant message delivery
- ✅ **Read Receipts** - Know when messages are read
- 📜 **Chat History** - Persistent conversation history
- 🎨 **Customizable Theme** - Adjust colors to match your brand
- 🌐 **Auto-Reconnect** - Handles connection drops gracefully

### 👨‍💼 CS Dashboard Screen
- 📊 **Multi-Chat Management** - Handle multiple conversations
- 🔄 **Real-time Updates** - Instant message and status updates
- 🤖 **AI Summary** - View AI conversation summaries
- 🔔 **Notifications** - In-app notifications for new messages
- ✅ **Message Read Tracking** - See when customers read messages
- 🎯 **Smart Sorting** - Auto-sorted by latest activity
- 📱 **Responsive Layout** - Desktop and mobile optimized

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  ws_chat_flutter: ^1.0.1
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

### 1. Customer Chat Screen

```dart
import 'package:flutter/material.dart';
import 'package:ws_chat_flutter/ws_chat_flutter.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    serverUrl: 'https://your-server.com',
                    customerId: 'customer_123',
                    customerName: 'John Doe',
                    primaryColor: Color(0xFF4F46E5),
                  ),
                ),
              );
            },
            child: Text('Open Chat'),
          ),
        ),
      ),
    );
  }
}
```

### 2. CS Dashboard Screen

```dart
import 'package:flutter/material.dart';
import 'package:ws_chat_flutter/ws_chat_flutter.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CSDashboardScreen(
      serverUrl: 'https://your-server.com',
      csUserId: 'cs_001',
      csName: 'Agent Sarah',
      primaryColor: Color(0xFF10B981),
    ),
  ),
);
```

## 📱 Usage Examples

### Example 1: In-App Support Button

```dart
import 'package:flutter/material.dart';
import 'package:ws_chat_flutter/ws_chat_flutter.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
        actions: [
          IconButton(
            icon: Icon(Icons.support_agent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    serverUrl: 'https://your-server.com',
                    customerId: 'user_123',
                    customerName: 'John Doe',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome to My App'),
      ),
    );
  }
}
```

### Example 2: Bottom Navigation Integration

```dart
import 'package:flutter/material.dart';
import 'package:ws_chat_flutter/ws_chat_flutter.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    ChatScreen(
      serverUrl: 'https://your-server.com',
      customerId: 'customer_123',
      customerName: 'John Doe',
      showBackButton: false,
    ),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

## 🎨 Customization

### Custom Colors

```dart
ChatScreen(
  serverUrl: 'https://your-server.com',
  customerId: 'customer_123',
  customerName: 'John Doe',
  primaryColor: Color(0xFFFF6B6B), // Custom brand color
)
```

### Custom Title

```dart
ChatScreen(
  serverUrl: 'https://your-server.com',
  customerId: 'customer_123',
  customerName: 'John Doe',
  title: 'Talk to Us', // Custom title
)
```

### Hide Back Button

```dart
ChatScreen(
  serverUrl: 'https://your-server.com',
  customerId: 'customer_123',
  customerName: 'John Doe',
  showBackButton: false, // Useful for embedded screens
)
```

## 🔧 Backend Requirements

This package requires a Socket.IO server. Here's the event contract:

### Customer Events (Client → Server)
```javascript
// Initialize chat
socket.emit('start_chat', {
  customerId: 'customer_123',
  customerName: 'John Doe',
  initialMessage: 'Hello'
});

// Send message
socket.emit('customer_message', {
  customerId: 'customer_123',
  message: 'Hello',
  chatRoomId: 'room_123'
});

// Get history
socket.emit('get_customer_chat_history', {
  customerId: 'customer_123',
  chatRoomId: 'room_123'
});

// Mark as read
socket.emit('mark_message_read', {
  messageId: 'msg_123',
  customerId: 'customer_123'
});
```

### CS Events (Client → Server)
```javascript
// CS Login
socket.emit('cs_login', {
  userId: 'cs_001',
  name: 'Agent Sarah'
});

// Get rooms
socket.emit('cs_get_all_rooms', {
  csUserId: 'cs_001'
});

// Select room
socket.emit('cs_select_room', {
  chatRoomId: 'room_123',
  csUserId: 'cs_001'
});

// Send message
socket.emit('cs_send_message', {
  chatRoomId: 'room_123',
  message: 'Hello',
  csUserId: 'cs_001'
});
```

### Server Events (Server → Client)
```javascript
// Chat started
socket.on('chat_started', (data) => {
  // data: { chatRoomId, status, csName, message }
});

// New message
socket.on('receive_message', (data) => {
  // data: { id, text, sender, timestamp, senderName }
});

// AI typing
socket.on('ai_typing', () => {});

// CS assigned
socket.on('cs_assigned', (data) => {
  // data: { csName }
});
```

## 📱 Platform Support

| Platform | Supported |
|----------|-----------|
| Android  | ✅ Yes    |
| iOS      | ✅ Yes    |
| Web      | ✅ Yes    |
| macOS    | ✅ Yes    |
| Windows  | ✅ Yes    |
| Linux    | ✅ Yes    |

## 📄 API Reference

### ChatScreen

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `serverUrl` | `String` | ✅ | - | WebSocket server URL |
| `customerId` | `String` | ✅ | - | Unique customer identifier |
| `customerName` | `String` | ✅ | - | Customer display name |
| `title` | `String?` | ❌ | null | Custom screen title |
| `primaryColor` | `Color?` | ❌ | `0xFF4F46E5` | Primary theme color |
| `showBackButton` | `bool` | ❌ | `true` | Show/hide back button |

### CSDashboardScreen

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `serverUrl` | `String` | ✅ | - | WebSocket server URL |
| `csUserId` | `String` | ✅ | - | Unique CS agent identifier |
| `csName` | `String` | ✅ | - | CS agent display name |
| `primaryColor` | `Color?` | ❌ | `0xFF10B981` | Primary theme color |

## 🔒 Security Best Practices

```dart
// ✅ DO: Use HTTPS in production
const serverUrl = 'https://api.example.com';

// ✅ DO: Use environment variables
const serverUrl = String.fromEnvironment('SERVER_URL');

// ❌ DON'T: Hardcode credentials
// ❌ DON'T: Use HTTP in production
```

## 🐛 Troubleshooting

### Connection Issues

**Problem:** Chat won't connect

**Solution:**
- Verify server URL is correct and accessible
- Ensure Socket.IO server is running
- Check CORS settings on server
- Enable debug mode to see connection logs

### Messages Not Appearing

**Problem:** Messages don't show up

**Solution:**
- Verify `customerId`/`csUserId` are unique
- Check event names match your server implementation
- Ensure server emits proper response events

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [socket_io_client](https://pub.dev/packages/socket_io_client)
- Inspired by modern chat interfaces
- Thanks to the Flutter community

## 📞 Support

- 🐛 [Report bugs](https://github.com/robilprogramer/ws_chat_flutter/issues)
- 💬 [Discussions](https://github.com/robilprogramer/ws_chat_flutter/discussions)
- 📧 Email: support@example.com

## 🗺️ Roadmap

- [ ] File upload support
- [ ] Voice message support
- [ ] Video call integration
- [ ] Chat analytics
- [ ] Multi-language support
- [ ] Emoji picker
- [ ] Message reactions
- [ ] Push notifications

---

**Made with ❤️ using Flutter**