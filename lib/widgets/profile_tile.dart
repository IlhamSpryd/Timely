import 'package:flutter/material.dart';

class ProfileTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String avatarPath;
  final VoidCallback? onEdit;

  const ProfileTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.avatarPath,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: AssetImage(avatarPath),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
    );
  }
}
