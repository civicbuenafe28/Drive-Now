import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Bottom sheet: take photo / choose from gallery / remove.
Future<void> changeProfilePhoto(BuildContext context) async {
  final data = AppData.instance;
  final choice = await showAppSheet<String>(
    context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text('Profile photo', style: AppText.h2),
          ),
          SettingsTile(
            icon: Icons.photo_camera_rounded,
            title: 'Take a photo',
            onTap: () => Navigator.of(ctx).pop('camera'),
          ),
          SettingsTile(
            icon: Icons.photo_library_rounded,
            title: 'Choose from gallery',
            onTap: () => Navigator.of(ctx).pop('gallery'),
          ),
          if (data.profileImage != null)
            SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Remove photo',
              destructive: true,
              onTap: () => Navigator.of(ctx).pop('remove'),
            ),
        ],
      ),
    ),
  );
  if (choice == null) return;

  if (choice == 'remove') {
    await data.setProfileImage(null);
    if (context.mounted) showAppSnack(context, 'Profile photo removed');
    return;
  }

  try {
    final file = await ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 82,
      preferredCameraDevice: CameraDevice.front,
    );
    if (file == null) return;
    await data.setProfileImage(await file.readAsBytes());
    if (context.mounted) showAppSnack(context, 'Profile photo updated', type: SnackType.success);
  } catch (e) {
    if (context.mounted) {
      showAppSnack(context, 'Could not open ${choice == 'camera' ? 'the camera' : 'your photos'}', type: SnackType.error);
    }
  }
}

/// Avatar with a small camera badge; tapping opens [changeProfilePhoto].
class EditableAvatar extends StatelessWidget {
  const EditableAvatar({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) {
    final data = AppData.instance;
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) => GestureDetector(
        onTap: () => changeProfilePhoto(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Avatar(size: size, bytes: data.profileImage, initials: data.initials),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 3),
                ),
                child: Icon(Icons.photo_camera_rounded, color: Colors.white, size: size * 0.16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
