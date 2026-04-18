import 'package:expanse_tracker/home_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zfkjvlypuezwhsilpkkq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpma2p2bHlwdWV6d2hzaWxwa2txIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NzM2OTEsImV4cCI6MjA5MDE0OTY5MX0.WBhUYJ6zHuT-Jp3eWjD2vweiaMf0jg2LTSz0s2RkdHY',
  );
  runApp(const Myapp());
}

class Myapp extends StatefulWidget {
  const Myapp({super.key});

  @override
  State<Myapp> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Myapp> {
  @override
  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expanse Tracker',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomePage(),
    );
  }
}
