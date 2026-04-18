import 'package:expanse_tracker/editProfile.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePageUI extends StatefulWidget {
  const ProfilePageUI({super.key});

  @override
  State<ProfilePageUI> createState() => _ProfilePageUIState();
}

class _ProfilePageUIState extends State<ProfilePageUI> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    /// 🔥 Listen for auth/user changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }



  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final avatar = user?.userMetadata?['avatar_url'];
    final name = user?.userMetadata?['name'] ?? "No Name";
    final email = user?.email ?? "No Email";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            /// 🔵 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 40, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  /// Avatar with edit icon
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundImage: (avatar != null &&
                                avatar.toString().isNotEmpty)
                            ? NetworkImage(
                                "$avatar?t=${DateTime.now().millisecondsSinceEpoch}",
                              )
                            : const NetworkImage(
                                "https://i.pravatar.cc/300",
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.edit, size: 16),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// Name
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  /// Email
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 📋 MENU
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: [
                  _MenuTile(
                    icon: Icons.person,
                    title: "Edit Profile",
                    onTap: (context) async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );

                      if (updated == true) {
                        await Supabase.instance.client.auth.refreshSession();
                        setState(() {});
                      }
                    },
                  ),

                  _MenuTile(
                    icon: Icons.history,
                    title: "Transaction History",
                    onTap: (context) {
                      // TODO: Navigate
                    },
                  ),

                  _MenuTile(
                    icon: Icons.settings,
                    title: "Settings",
                    onTap: (context) {},
                  ),

                  _MenuTile(
                    icon: Icons.lock,
                    title: "Privacy",
                    onTap: (context) {},
                  ),

                  _MenuTile(
                    icon: Icons.help,
                    title: "Help & Support",
                    onTap: (context) {},
                  ),
                ],
              ),
            ),

            /// 🔴 LOGOUT BUTTON
            // Padding(
            //   padding: const EdgeInsets.all(16),
            //   child: ElevatedButton(
            //     onPressed: isLoading ? null : () => logout(context),
            //     style: ElevatedButton.styleFrom(
            //       minimumSize: const Size(double.infinity, 50),
            //       backgroundColor: Colors.red,
            //     ),
            //     child: isLoading
            //         ? const CircularProgressIndicator(color: Colors.white)
            //         : const Text("Logout"),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Reusable Menu Tile
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Function(BuildContext)? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap != null ? () => onTap!(context) : null,
      ),
    );
  }
}