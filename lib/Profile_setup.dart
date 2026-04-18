import 'dart:io';
import 'package:expanse_tracker/home_content.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController nameController = TextEditingController();
  File? selectedImage;

  final ImagePicker picker = ImagePicker();

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ Save locally
    await prefs.setString('user_name', nameController.text);
    await prefs.setString('user_image', selectedImage?.path ?? '');


    final user = Supabase.instance.client.auth.currentUser;

if (user != null) {
  try {
    String? imageUrl;

    if (selectedImage != null) {
      final filePath = 'image/${user.id}.jpg';

      // ✅ Upload
      await Supabase.instance.client.storage
          .from('images')
          .upload(
            filePath,
            selectedImage!,
            fileOptions: const FileOptions(upsert: true),
          );

      // ✅ Get URL
      imageUrl = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(filePath);

      print("IMAGE URL: $imageUrl"); // 👈 DEBUG
    }

    // ✅ Insert into table
    await Supabase.instance.client.from('user_detail').insert({
      'uuidd': user.id,
      'name': nameController.text,
      'image_url': imageUrl, // 👈 THIS IS IMPORTANT
    });

  } catch (e) {
    print("Supabase error: $e");
  }
}

    // ✅ Navigate
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) =>  HomeContent()),
      (route)=>false
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// 🔵 Profile Image
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage!)
                    : null,
                child: selectedImage == null
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            /// 📝 Name Field
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Enter your name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// 🚀 Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
