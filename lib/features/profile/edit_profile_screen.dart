// lib/features/profile/edit_profile_screen.dart
//
// Full-page editor for the user's profile.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialStandard;
  final String initialImageUrl;
  final String phone;

  const EditProfileScreen({
    super.key,
    this.initialName = '',
    this.initialStandard = '',
    this.initialImageUrl = '',
    this.phone = '',
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {

  late final TextEditingController _nameCtrl;
  final FocusNode _nameFocus = FocusNode();
  final ImagePicker _picker = ImagePicker();

  String? _selectedStandard;
  String _currentImageUrl = '';
  File? _localImage;
  bool _isLoading = false;
  bool _hasNameError = false;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<String> _standards = const [
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
    'Class 11', 'Class 12',
    'SSC / Railway', 'Banking', 'UPSC', 'Other Competitive',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _selectedStandard = widget.initialStandard.isNotEmpty
        ? widget.initialStandard
        : null;
    _currentImageUrl = widget.initialImageUrl;

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final nameChanged = _nameCtrl.text.trim() != widget.initialName.trim();
    final stdChanged = (_selectedStandard ?? '') != widget.initialStandard;
    final imgChanged = _localImage != null;
    return nameChanged || stdChanged || imgChanged;
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges || _isLoading) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        title: Text('Discard changes?',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Your edits will be lost. Are you sure?',
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Editing',
                style: GoogleFonts.poppins(color: AppColors.neonCyan)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard',
                style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.darkCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded,
                    color: AppColors.neonCyan),
                title: Text('Take Photo',
                    style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickFrom(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.neonCyan),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickFrom(ImageSource.gallery);
                },
              ),
              if (_localImage != null || _currentImageUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  title: Text('Remove Photo',
                      style: GoogleFonts.poppins(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _localImage = null;
                      _currentImageUrl = '';
                    });
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _pickFrom(ImageSource src) async {
    try {
      final XFile? f = await _picker.pickImage(
        source: src,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (f != null && mounted) {
        setState(() => _localImage = File(f.path));
      }
    } catch (e) {
      if (mounted) _toast('Could not pick image: $e', isError: true);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: (isError ? AppColors.error : AppColors.success)
                    .withValues(alpha: 0.4),
                width: 1)),
        content: Row(
          children: [
            Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: isError ? AppColors.error : AppColors.success,
                size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    setState(() => _hasNameError = name.isEmpty);
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    // 1. If user picked a new image, upload it first
    String? newImageUrl;
    if (_localImage != null) {
      newImageUrl = await UserService.uploadProfileImage(_localImage!.path);
      if (newImageUrl == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _toast('Failed to upload image. Try again.', isError: true);
        return;
      }
    }

    // 2. Update name + standard (and the new image URL if uploaded)
    final ok = await UserService.updateProfile(
      name: name,
      standard: _selectedStandard,
    );

    if (!mounted) return;

    if (ok) {
      await AuthService.setCachedName(name);
      if (_selectedStandard != null) {
        await AuthService.setCachedStandard(_selectedStandard!);
      }
      _toast('Profile updated!');
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isLoading = false);
      _toast('Failed to update. Try again.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialName.isNotEmpty
        ? widget.initialName[0].toUpperCase()
        : '?';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: const BoxDecoration(gradient: AppColors.splashBg),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      _buildAppBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              _buildAvatar(initial),
                              const SizedBox(height: 30),
                              _buildSectionLabel('YOUR NAME'),
                              const SizedBox(height: 8),
                              _buildNameField(),
                              const SizedBox(height: 24),
                              _buildSectionLabel('PHONE'),
                              const SizedBox(height: 8),
                              _buildPhoneField(),
                              const SizedBox(height: 24),
                              _buildSectionLabel('CLASS / EXAM'),
                              const SizedBox(height: 8),
                              _buildStandardGrid(),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                      _buildSaveBar(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final ok = await _onWillPop();
              if (ok && mounted) Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.neonCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Text('EDIT PROFILE',
              style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neonCyan,
                  letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildAvatar(String letter) {
    final hasImage = _localImage != null || _currentImageUrl.isNotEmpty;
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withValues(alpha: 0.12),
                border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: hasImage
                    ? (_localImage != null
                        ? Image.file(_localImage!, fit: BoxFit.cover)
                        : Image.network(
                            _currentImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _initialFallback(letter),
                          ))
                    : _initialFallback(letter),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan,
                border: Border.all(color: AppColors.darkBg, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.darkBg, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialFallback(String letter) => Center(
        child: Text(
          letter,
          style: GoogleFonts.orbitron(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.neonCyan,
          ),
        ),
      );

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameCtrl,
      focusNode: _nameFocus,
      style: GoogleFonts.poppins(
          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      cursorColor: AppColors.neonCyan,
      textCapitalization: TextCapitalization.words,
      maxLength: 32,
      onChanged: (_) {
        if (_hasNameError) setState(() => _hasNameError = false);
      },
      decoration: InputDecoration(
        hintText: 'Enter your name',
        hintStyle: GoogleFonts.poppins(color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.person_rounded,
            color: AppColors.neonCyan, size: 20),
        counterText: '',
        errorText: _hasNameError ? 'Name cannot be empty' : null,
        errorStyle: GoogleFonts.poppins(color: AppColors.error, fontSize: 11),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.neonCyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_rounded,
              color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.phone.isEmpty ? '— not set —' : widget.phone,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.phone));
              _toast('Phone copied');
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded,
                      color: AppColors.textMuted, size: 11),
                  const SizedBox(width: 4),
                  Text('VERIFIED',
                      style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _standards.map((s) {
        final selected = _selectedStandard == s;
        return GestureDetector(
          onTap: () => setState(() => _selectedStandard = s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.neonCyan.withValues(alpha: 0.13)
                  : AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.neonCyan
                    : AppColors.neonCyan.withValues(alpha: 0.1),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.neonCyan, size: 14),
                  const SizedBox(width: 6),
                ],
                Text(
                  s,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? AppColors.neonCyan
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveBar() {
    final canSave = _hasChanges && !_isLoading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: GestureDetector(
        onTap: canSave ? _save : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: canSave
                ? const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF00ACC1)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: canSave ? null : AppColors.darkCard,
            borderRadius: BorderRadius.circular(28),
            boxShadow: canSave
                ? [
                    BoxShadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.darkBg,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _hasChanges ? 'SAVE CHANGES' : 'NO CHANGES TO SAVE',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: canSave
                          ? AppColors.darkBg
                          : AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
