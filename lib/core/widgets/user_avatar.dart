import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Versatile and robust avatar widget supporting network URLs, Base64 Data URLs,
/// and fallback monogram initials with a branded SaveBite gradient styling.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    this.avatarUrl,
    this.name,
    this.radius = 48.0,
    this.showEditBadge = false,
    this.onTapEdit,
    super.key,
  });

  final String? avatarUrl;
  final String? name;
  final double radius;
  final bool showEditBadge;
  final VoidCallback? onTapEdit;

  String get _initials {
    final cleanName = name?.trim() ?? '';
    if (cleanName.isEmpty) return 'U';
    final parts = cleanName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return cleanName[0].toUpperCase();
  }

  Widget _buildFallbackInitials() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: radius * 0.72,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) {
      return _buildFallbackInitials();
    }

    // 1. Base64 Data URL: data:image/png;base64,iVBORw...
    if (url.startsWith('data:image')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Str = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackInitials(),
        );
      } catch (_) {
        return _buildFallbackInitials();
      }
    }

    // 2. Standard Network Image URL
    return Image.network(
      url,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: radius * 2,
          height: radius * 2,
          color: AppColors.primary.withValues(alpha: 0.1),
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildFallbackInitials(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarBody = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildImageContent(),
      ),
    );

    if (!showEditBadge) {
      return avatarBody;
    }

    return Stack(
      children: [
        avatarBody,
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onTapEdit,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
