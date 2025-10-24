enum Sender { user, assistant }

class Message {
  final String text;
  final Sender sender;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.sender,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'sender': sender == Sender.user ? 'user' : 'assistant',
        'timestamp': timestamp.toIso8601String(),
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    final text = (json['text'] ?? '') as String;
    final senderString = (json['sender'] ?? 'assistant') as String;

    final sender = senderString.toLowerCase() == 'user' ? Sender.user : Sender.assistant;

    DateTime parsedTimestamp;
    try {
      final ts = json['timestamp'];
      if (ts == null) {
        parsedTimestamp = DateTime.now();
      } else if (ts is String) {
        parsedTimestamp = DateTime.parse(ts);
      } else if (ts is int) {
        // por si guardaste epoch ms
        parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(ts);
      } else {
        parsedTimestamp = DateTime.now();
      }
    } catch (_) {
      parsedTimestamp = DateTime.now();
    }

    return Message(
      text: text,
      sender: sender,
      timestamp: parsedTimestamp,
    );
  }

  @override
  String toString() => 'Message(sender: $sender, text: $text, time: $timestamp)';
}
