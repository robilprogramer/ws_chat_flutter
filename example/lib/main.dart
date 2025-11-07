// ============================================
// example/lib/main.dart (Example App)
// ============================================
// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:ws_chat_flutter/ws_chat_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WS Chat Flutter Example',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WS Chat Flutter Demo'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 100,
                color: Colors.indigo,
              ),
              const SizedBox(height: 32),
              const Text(
                'WS Chat Flutter',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI-Powered Customer Service Chat',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),

              // Customer Chat Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatScreen(
                          serverUrl: 'http://localhost:3001',
                          customerId: 'customer_123',
                          customerName: 'Robil Mobile',
                          primaryColor: Color(0xFF4F46E5),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person, size: 24),
                  label: const Text(
                    'Open Customer Chat',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // CS Dashboard Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CSDashboardScreen(
                          serverUrl: 'http://localhost:3001',
                          csUserId: 'cs_001',
                          csName: 'Agent Sarah',
                          primaryColor: Color(0xFF10B981),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent, size: 24),
                  label: const Text(
                    'Open CS Dashboard',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(height: 8),
                    Text(
                      'Make sure your Socket.IO server is running on localhost:3001',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// USAGE EXAMPLE 1: Customer Chat in Your App
// ============================================

// In your existing Flutter app:
/*
import 'package:ws_chat_flutter/ws_chat_flutter.dart';

// Navigate to chat screen
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          serverUrl: 'https://your-server.com',
          customerId: 'user_${currentUser.id}',
          customerName: currentUser.name,
          title: 'Chat Support',
          primaryColor: Colors.indigo,
          showBackButton: true,
        ),
      ),
    );
  },
  child: Text('Contact Support'),
)
*/

// ============================================
// USAGE EXAMPLE 2: CS Dashboard
// ============================================

// For CS agents:
/*
import 'package:ws_chat_flutter/ws_chat_flutter.dart';

// Navigate to CS dashboard
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CSDashboardScreen(
          serverUrl: 'https://your-server.com',
          csUserId: 'cs_${currentAgent.id}',
          csName: currentAgent.name,
          primaryColor: Colors.green,
        ),
      ),
    );
  },
  child: Text('Open Dashboard'),
)
*/

// ============================================
// USAGE EXAMPLE 3: Embedded in TabBar
// ============================================

/*
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My App'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.chat), text: 'Support'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            HomeTab(),
            ChatScreen(
              serverUrl: 'https://your-server.com',
              customerId: 'customer_123',
              customerName: 'John Doe',
              showBackButton: false, // No back button in tab
            ),
            SettingsTab(),
          ],
        ),
      ),
    );
  }
}
*/

// ============================================
// USAGE EXAMPLE 4: Custom Theme
// ============================================

/*
// Use your brand colors
ChatScreen(
  serverUrl: 'https://your-server.com',
  customerId: 'customer_123',
  customerName: 'John Doe',
  primaryColor: Color(0xFFFF6B6B), // Custom red
  title: 'Customer Service',
)

// CS Dashboard with custom color
CSDashboardScreen(
  serverUrl: 'https://your-server.com',
  csUserId: 'cs_001',
  csName: 'Agent Sarah',
  primaryColor: Color(0xFF9B59B6), // Custom purple
)
*/
