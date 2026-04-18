import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final picker = ImagePicker();

  bool isLoading = false;
  File? selectedImage;
  String? avatarUrl;

  @override
  void initState() {
    super.initState();

    final user = Supabase.instance.client.auth.currentUser;
    nameController.text = user?.userMetadata?['name'] ?? "";
    avatarUrl = user?.userMetadata?['avatar_url'] ?? "";
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> showImageSourceSelector() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImage() async {
    if (selectedImage == null) return avatarUrl;

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

   final fileName =
    'image/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await Supabase.instance.client.storage
        .from('pictures') // ✅ FIXED
        .upload(
          fileName,
          selectedImage!,
          fileOptions: const FileOptions(upsert: true),
        );

    return Supabase.instance.client.storage
        .from('pictures') // ✅ FIXED
        .getPublicUrl(fileName);
  }

  Future<void> updateProfile() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Name cannot be empty")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final imageUrl = await uploadImage();

      final data = {'name': nameController.text.trim()};

      if (imageUrl != null) {
        data['avatar_url'] = imageUrl;
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: data),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated")));

      Navigator.pop(context, true);
    } catch (e) {
      print("ERROR => $e"); // 👈 very important
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: showImageSourceSelector,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage!)
                    : (avatarUrl != null && avatarUrl!.isNotEmpty
                          ? NetworkImage("$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}",)
                          : null),
                child:
                    (selectedImage == null &&
                        (avatarUrl == null || avatarUrl!.isEmpty))
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isLoading ? null : updateProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
