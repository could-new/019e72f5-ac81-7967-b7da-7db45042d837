import 'package:flutter/material.dart';

void main() {
  runApp(const TicketBotApp());
}

class TicketBotApp extends StatelessWidget {
  const TicketBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticket Bot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const TicketDashboardScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final ticket = settings.arguments as Ticket;
          return MaterialPageRoute(
            builder: (context) => TicketChatScreen(ticket: ticket),
          );
        }
        return null;
      },
    );
  }
}

// --- Models ---

class Message {
  final String id;
  final String text;
  final bool isBot;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.isBot,
    required this.timestamp,
  });
}

class Ticket {
  final String id;
  final String title;
  final String status;
  final DateTime createdAt;
  final List<Message> messages;

  Ticket({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.messages,
  });

  String get lastMessage => messages.isNotEmpty ? messages.last.text : 'No messages yet.';
  DateTime get lastActivity => messages.isNotEmpty ? messages.last.timestamp : createdAt;
}

// --- Dummy Data ---

List<Ticket> dummyTickets = [
  Ticket(
    id: 'T-1001',
    title: 'Cannot access my account',
    status: 'Open',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    messages: [
      Message(id: 'm1', text: 'Hi, I cannot login to my account since yesterday.', isBot: false, timestamp: DateTime.now().subtract(const Duration(hours: 24))),
      Message(id: 'm2', text: 'Hello! I am the support bot. Can you please provide your registered email address?', isBot: true, timestamp: DateTime.now().subtract(const Duration(hours: 23, minutes: 55))),
    ],
  ),
  Ticket(
    id: 'T-1002',
    title: 'Billing issue on last invoice',
    status: 'Resolved',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    messages: [
      Message(id: 'm3', text: 'I was overcharged by $10.', isBot: false, timestamp: DateTime.now().subtract(const Duration(days: 3))),
      Message(id: 'm4', text: 'I have reviewed your invoice. We have issued a refund of $10 to your original payment method. Is there anything else?', isBot: true, timestamp: DateTime.now().subtract(const Duration(days: 2))),
    ],
  ),
];

// --- Screens ---

class TicketDashboardScreen extends StatefulWidget {
  const TicketDashboardScreen({super.key});

  @override
  State<TicketDashboardScreen> createState() => _TicketDashboardScreenState();
}

class _TicketDashboardScreenState extends State<TicketDashboardScreen> {
  void _createNewTicket() {
    setState(() {
      final newTicket = Ticket(
        id: 'T-${1000 + dummyTickets.length + 1}',
        title: 'New Support Request',
        status: 'Open',
        createdAt: DateTime.now(),
        messages: [
          Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'Hello, how can we help you today?',
            isBot: true,
            timestamp: DateTime.now(),
          )
        ],
      );
      dummyTickets.insert(0, newTicket);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: dummyTickets.isEmpty
            ? const Center(child: Text('No tickets found.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: dummyTickets.length,
                itemBuilder: (context, index) {
                  final ticket = dummyTickets[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(ticket.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ticket.status == 'Open' ? Colors.green.shade100 : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  ticket.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ticket.status == 'Open' ? Colors.green.shade800 : Colors.grey.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${ticket.lastActivity.month}/${ticket.lastActivity.day} ${ticket.lastActivity.hour}:${ticket.lastActivity.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/chat', arguments: ticket).then((_) {
                          setState(() {}); // Refresh list when coming back
                        });
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTicket,
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
    );
  }
}

class TicketChatScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketChatScreen({super.key, required this.ticket});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      widget.ticket.messages.add(
        Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isBot: false,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
    });

    _scrollToBottom();

    // Simulate bot response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          widget.ticket.messages.add(
            Message(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: 'I understand. An agent will review this shortly.',
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.ticket.title, style: const TextStyle(fontSize: 16)),
            Text(widget.ticket.id, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: widget.ticket.messages.length,
                itemBuilder: (context, index) {
                  final message = widget.ticket.messages[index];
                  final isBot = message.isBot;
                  return Align(
                    alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: isBot ? Colors.grey.shade200 : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomLeft: isBot ? const Radius.circular(0) : const Radius.circular(16),
                          bottomRight: isBot ? const Radius.circular(16) : const Radius.circular(0),
                        ),
                      ),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message.text),
                          const SizedBox(height: 4),
                          Text(
                            '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.ticket.status == 'Open')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey.shade200,
                child: const Center(
                  child: Text('This ticket is resolved and closed for new messages.', style: TextStyle(color: Colors.black54)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
