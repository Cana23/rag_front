import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/chat_page.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MenuBotApp());
}

class MenuBotApp extends StatelessWidget {
  const MenuBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ChatProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MenuBot Chat',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const ChatPage(),
      ),
    );
  }
}
