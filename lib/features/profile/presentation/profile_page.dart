import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ivox/core/theme/theme_provider.dart';
import 'package:ivox/features/auth/presentation/login_page.dart';
import 'package:ivox/features/auth/services/api_auth_service.dart';
import 'package:ivox/features/auth/services/auth_service.dart';
import 'package:ivox/features/dictionnaire/presentation/dictionnaire_page.dart';
import 'package:ivox/shared/widgets/main_bottom_nav_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const ProfilePage({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _apiAuthService = ApiAuthService();
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isEditingName = false;
  bool _isSavingName = false;
  bool _isUploadingPhoto = false;
  bool _notificationsEnabled = true;
  bool _isTogglingNotifications = false;
  bool _isTogglingProfileVisibility = false;

  Future<void> _handleLogout() async {
    try {
      await _apiAuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Le nom d'utilisateur ne peut pas être vide"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await _authService.updateUsername(username);
      if (mounted) {
        setState(() => _isEditingName = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la mise à jour: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingName = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final source = await _selectImageSource();
    if (source == null) return;

    final granted = source == ImageSource.camera
        ? await _ensureCameraPermission()
        : await _ensureGalleryPermission();
    if (!granted) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await _authService.uploadProfileImage(
        bytes: bytes,
        fileName: picked.name,
      );
      await _authService.updatePhotoUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'upload: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<ImageSource?> _selectImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text("Galerie"),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text("Caméra"),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _ensureGalleryPermission() async {
    PermissionStatus status;

    if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else {
      status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    }

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Autorisation refusée. Activez l'accès à la galerie dans les paramètres.",
            ),
            action: SnackBarAction(label: "Ouvrir", onPressed: openAppSettings),
          ),
        );
      }
      return false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission galerie non accordée")),
      );
    }
    return false;
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Autorisation caméra refusée. Activez l'accès dans les paramètres.",
            ),
            action: SnackBarAction(label: "Ouvrir", onPressed: openAppSettings),
          ),
        );
      }
      return false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission caméra non accordée")),
      );
    }
    return false;
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_isTogglingNotifications) return;
    final previousValue = _notificationsEnabled;
    setState(() {
      _isTogglingNotifications = true;
      _notificationsEnabled = value;
    });
    if (value) {
      // Android: demander avec permission_handler
      final status = await Permission.notification.status;
      final requestStatus = status.isGranted
          ? status
          : await Permission.notification.request();

      if (!requestStatus.isGranted) {
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Activer les notifications'),
              content: const Text(
                'Veuillez aller dans les paramètres de votre appareil et autoriser les notifications pour IVOX.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    openAppSettings();
                  },
                  child: const Text('Ouvrir paramètres'),
                ),
              ],
            ),
          );
          if (result != true) {
            setState(() {
              _notificationsEnabled = previousValue;
              _isTogglingNotifications = false;
            });
          }
        } else {
          setState(() {
            _notificationsEnabled = previousValue;
            _isTogglingNotifications = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _notificationsEnabled = value;
        _isTogglingNotifications = false;
      });
    }
  }

  Future<void> _toggleProfileVisibility(bool value) async {
    if (_isTogglingProfileVisibility) return;
    setState(() => _isTogglingProfileVisibility = true);
    try {
      await _authService.updateProfilePrivacy(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Profil passe en public' : 'Profil passe en prive',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      print('DEBUG: Profile visibility toggle error: $errorMsg');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      setState(() => _isTogglingProfileVisibility = false);
      return;
    }
    if (mounted) {
      setState(() => _isTogglingProfileVisibility = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final user = _authService.getUser();
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        leading: Text(""),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _handleLogout, icon: Icon(Icons.logout)),
        ],
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
      ),
      body: user == null
          ? const Center(child: Text("Utilisateur non connecté"))
          : StreamBuilder(
              stream: _authService.userDocStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data();
                final username =
                    (data != null ? data['username'] as String? : null) ??
                    user.displayName ??
                    'Utilisateur';
                final email =
                    (data != null ? data['email'] as String? : null) ??
                    user.email ??
                    '';
                final photoUrl = data != null
                    ? data['photoUrl'] as String?
                    : null;
                final isPublicProfile =
                    (data != null ? data['isPublicProfile'] as bool? : null) ??
                    true;

                if (!_isEditingName && _usernameController.text != username) {
                  _usernameController.text = username;
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: GestureDetector(
                              onTap: _isUploadingPhoto
                                  ? null
                                  : _pickProfileImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: _isUploadingPhoto
                                    ? SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.onPrimary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: colorScheme.onPrimary,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Nom d'utilisateur",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                if (!_isEditingName)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() => _isEditingName = true);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_isEditingName) ...[
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  hintText: "Entrez votre nom",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: _isSavingName
                                        ? null
                                        : () {
                                            setState(
                                              () => _isEditingName = false,
                                            );
                                            _usernameController.text = username;
                                          },
                                    child: const Text("Annuler"),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _isSavingName
                                        ? null
                                        : _saveUsername,
                                    child: _isSavingName
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text("Enregistrer"),
                                  ),
                                ],
                              ),
                            ] else
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Email",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(email),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.color_lens_outlined,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Thème",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Choisir le thème du système ou personnalisé",
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<ThemePreference>(
                              initialValue: themeProvider.preference,
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setThemePreference(value);
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: ThemePreference.system,
                                  child: Text("Système"),
                                ),
                                DropdownMenuItem(
                                  value: ThemePreference.light,
                                  child: Text("Clair"),
                                ),
                                DropdownMenuItem(
                                  value: ThemePreference.dark,
                                  child: Text("Sombre"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          spacing: 8,
                          children: [
                            Icon(
                              FontAwesomeIcons.alarmClock,
                              color: colorScheme.primary,
                            ),
                            Text("Activer les Notifications"),
                            const Spacer(),
                            CupertinoSwitch(
                              value: _notificationsEnabled,
                              onChanged: _isTogglingNotifications
                                  ? null
                                  : _toggleNotifications,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          spacing: 8,
                          children: [
                            Icon(
                              FontAwesomeIcons.userSecret,
                              color: colorScheme.primary,
                            ),
                            const Text(
                              'Profil public',
                            ),
                            const Spacer(),
                            CupertinoSwitch(
                              value: isPublicProfile,
                              onChanged: _isTogglingProfileVisibility
                                  ? null
                                  : _toggleProfileVisibility,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DictionaryScreen(),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                spacing: 8,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.paperclip,
                                    color: colorScheme.primary,
                                  ),
                                  Text("Dictionnaire"),
                                ],
                              ),
                              Icon(Icons.arrow_right_sharp),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DictionaryScreen(),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                spacing: 8,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.shop,
                                    color: colorScheme.primary,
                                  ),
                                  Text("Boutique"),
                                ],
                              ),
                              Icon(Icons.arrow_right_sharp),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      spacing: 6,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Devenir un"),
                        Text(
                          "Créateur ?",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}
