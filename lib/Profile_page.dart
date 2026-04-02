import 'package:expanse_tracker/login/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final session = Supabase.instance.client.auth.signOut();
                 Navigator.push(context, MaterialPageRoute(builder: (_)=>LoginPage()));
                },
                icon: Icon(Icons.logout),
                
              ),
              Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                  fontSize: 20,
                ),
              ),
             
            ],
          ),
        ],
      ),
    );
  }
}
