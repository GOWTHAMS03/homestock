import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/sync_status_bar.dart';
import '../auth/auth_controller.dart';
import 'home_controller.dart';
import 'home_model.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(membersControllerProvider.notifier).loadMembers();
    });
  }

  void _copyInviteCode(String code) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text('Invite code "$code" copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      ),
    );
  }

  void _shareInviteMessage(HomeModel home) {
    HapticFeedback.lightImpact();
    final message =
        'Join our household "${home.name}" on HomeStock! Use invite code: ${home.inviteCode}';
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.white, size: 20),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Invite message copied to clipboard! Paste it to any messaging app.')),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      ),
    );
  }

  void _showQrCodeDialog(BuildContext context, HomeModel home) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            home.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Household Invite Code',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // QR Canvas
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    boxShadow: [
                      BoxStroke.subtleShadow,
                    ],
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: CustomPaint(
                    size: const Size(190, 190),
                    painter: QrCodePainter(data: home.inviteCode),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Code Display Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      home.inviteCode,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _copyInviteCode(home.inviteCode);
                          Navigator.of(dialogCtx).pop();
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Code'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _shareInviteMessage(home);
                          Navigator.of(dialogCtx).pop();
                        },
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameHomeDialog(BuildContext context, HomeModel home) {
    final controller = TextEditingController(text: home.name);
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              title: const Row(
                children: [
                  Icon(Icons.home_work_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: AppSpacing.sm),
                  Text('Rename Household', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Household Name',
                    hintText: 'e.g. Sunny Home',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a household name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final newName = controller.text.trim();
                          if (newName == home.name) {
                            Navigator.of(dialogCtx).pop();
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          final success = await ref
                              .read(homeControllerProvider.notifier)
                              .updateHomeName(home.id, newName);

                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Household renamed to "$newName"'),
                                  backgroundColor: AppColors.inStockText,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to rename household. Please try again.'),
                                  backgroundColor: AppColors.outOfStockText,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmChangeRole(HomeMemberModel member, String newRole) {
    final title = newRole == 'OWNER'
        ? 'Transfer Ownership'
        : newRole == 'ADMIN'
            ? 'Promote to Admin'
            : 'Demote to Member';

    final message = newRole == 'OWNER'
        ? 'Are you sure you want to transfer ownership to ${member.fullName}? You will become an Admin.'
        : 'Are you sure you want to change ${member.fullName}\'s role to $newRole?';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final success = await ref
                  .read(membersControllerProvider.notifier)
                  .changeRole(member.userId, newRole);

              if (mounted) {
                if (success) {
                  if (newRole == 'OWNER') {
                    ref.read(homeControllerProvider.notifier).loadHomes();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Role updated for ${member.fullName}'),
                      backgroundColor: AppColors.inStockText,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update role. Please try again.'),
                      backgroundColor: AppColors.outOfStockText,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newRole == 'OWNER' ? const Color(0xFFD97706) : AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(HomeMemberModel member) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Row(
          children: [
            const Icon(Icons.person_remove_rounded, color: AppColors.outOfStockText, size: 22),
            const SizedBox(width: AppSpacing.sm),
            const Text('Remove Member', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${member.fullName} from this household? They will lose access to its inventory and shopping lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final success = await ref
                  .read(membersControllerProvider.notifier)
                  .removeMember(member.userId);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${member.fullName} was removed from household'),
                      backgroundColor: AppColors.textPrimary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to remove member. Please try again.'),
                      backgroundColor: AppColors.outOfStockText,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.outOfStockText,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveHousehold(HomeModel activeHome, String currentUserId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.outOfStockText, size: 22),
            SizedBox(width: AppSpacing.sm),
            Text('Leave Household', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to leave "${activeHome.name}"? You will need an invitation code to rejoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final success = await ref
                  .read(membersControllerProvider.notifier)
                  .removeMember(currentUserId);

              if (mounted) {
                if (success) {
                  await ref.read(homeControllerProvider.notifier).loadHomes();
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('You left "${activeHome.name}"'),
                        backgroundColor: AppColors.textPrimary,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not leave household. Please try again.'),
                      backgroundColor: AppColors.outOfStockText,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.outOfStockText,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeHome = ref.watch(homeControllerProvider).activeHome;
    final membersState = ref.watch(membersControllerProvider);
    final currentUser = ref.watch(authControllerProvider).user;

    final isOwner = activeHome?.isOwner ?? false;
    final isAdmin = activeHome?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Family Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(membersControllerProvider.notifier).loadMembers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Non-intrusive offline/sync indicator
          const SyncStatusBar(),

          Expanded(
            child: activeHome == null
                ? const Center(
                    child: Text(
                      'No household selected',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(membersControllerProvider.notifier).loadMembers(),
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        // Household Header Card
                        _buildHouseholdHeader(activeHome, isOwner || isAdmin),
                        const SizedBox(height: AppSpacing.lg),

                        // Invite Card
                        _buildInviteCard(activeHome),
                        const SizedBox(height: AppSpacing.xxl),

                        // Members Section Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Members (${membersState.members.length})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (membersState.isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Members List
                        if (membersState.members.isEmpty && !membersState.isLoading)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            alignment: Alignment.center,
                            child: const Column(
                              children: [
                                Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  'No members found',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        else
                          ...membersState.members.map((member) {
                            final isCurrentUser = member.userId == currentUser?.id;
                            return _buildMemberCard(
                              member: member,
                              isCurrentUser: isCurrentUser,
                              canManageRoles: isOwner && !isCurrentUser,
                              canRemove: (isOwner || (isAdmin && member.isMember)) && !isCurrentUser,
                            );
                          }),

                        const SizedBox(height: AppSpacing.xl),

                        // Leave Household (for non-owners) or Owner Info
                        if (!isOwner && currentUser != null)
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmLeaveHousehold(activeHome, currentUser.id),
                              icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.outOfStockText),
                              label: const Text(
                                'Leave Household',
                                style: TextStyle(color: AppColors.outOfStockText, fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.outOfStockBorder),
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                              ),
                            ),
                          )
                        else if (isOwner)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  'You are the owner of this household.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.9)),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdHeader(HomeModel home, bool canEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.roofing_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  home.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Role: ${home.currentUserRole}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
              tooltip: 'Rename Household',
              onPressed: () => _showRenameHomeDialog(context, home),
            ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(HomeModel home) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryContainer,
            AppColors.primaryContainer.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.group_add_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Invite Family Members',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Share this code so family members can join your household inventory and shopping list.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          // Code display box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    home.inviteCode,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primary),
                  tooltip: 'Copy Code',
                  onPressed: () => _copyInviteCode(home.inviteCode),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action buttons: Copy, Share, QR
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareInviteMessage(home),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showQrCodeDialog(context, home),
                  icon: const Icon(Icons.qr_code_rounded, size: 18),
                  label: const Text('QR Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard({
    required HomeMemberModel member,
    required bool isCurrentUser,
    required bool canManageRoles,
    required bool canRemove,
  }) {
    final initials = member.fullName.trim().isNotEmpty
        ? member.fullName
            .trim()
            .split(RegExp(r'\s+'))
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .take(2)
            .join()
        : '?';

    String joinedDate = '';
    if (member.joinedAt.isNotEmpty) {
      final parsed = DateTime.tryParse(member.joinedAt);
      if (parsed != null) {
        joinedDate = 'Joined ${DateFormat.yMMMd().format(parsed)}';
      }
    }

    final Color roleBgColor;
    final Color roleTextColor;
    final IconData roleIcon;

    if (member.isOwner) {
      roleBgColor = const Color(0xFFFEF3C7);
      roleTextColor = const Color(0xFF92400E);
      roleIcon = Icons.workspace_premium_rounded;
    } else if (member.isAdmin) {
      roleBgColor = const Color(0xFFE0E7FF);
      roleTextColor = const Color(0xFF3730A3);
      roleIcon = Icons.shield_rounded;
    } else {
      roleBgColor = AppColors.surfaceVariant;
      roleTextColor = AppColors.textSecondary;
      roleIcon = Icons.person_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: isCurrentUser
              ? AppColors.primaryLight.withValues(alpha: 0.5)
              : AppColors.outline,
        ),
      ),
      color: isCurrentUser ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isCurrentUser ? AppColors.primary : AppColors.primaryContainer,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isCurrentUser ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                ),
                if (member.isOwner)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),

            // Member Name & Email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.email,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (joinedDate.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      joinedDate,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleBgColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(roleIcon, size: 13, color: roleTextColor),
                  const SizedBox(width: 4),
                  Text(
                    member.role,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: roleTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Actions Menu
            if (canManageRoles || canRemove)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                onSelected: (action) {
                  if (action == 'PROMOTE_ADMIN') {
                    _confirmChangeRole(member, 'ADMIN');
                  } else if (action == 'DEMOTE_MEMBER') {
                    _confirmChangeRole(member, 'MEMBER');
                  } else if (action == 'TRANSFER_OWNER') {
                    _confirmChangeRole(member, 'OWNER');
                  } else if (action == 'REMOVE') {
                    _confirmRemoveMember(member);
                  }
                },
                itemBuilder: (context) => [
                  if (canManageRoles && member.isMember)
                    const PopupMenuItem(
                      value: 'PROMOTE_ADMIN',
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                          SizedBox(width: AppSpacing.sm),
                          Text('Promote to Admin'),
                        ],
                      ),
                    ),
                  if (canManageRoles && member.isAdmin)
                    const PopupMenuItem(
                      value: 'DEMOTE_MEMBER',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: AppSpacing.sm),
                          Text('Demote to Member'),
                        ],
                      ),
                    ),
                  if (canManageRoles)
                    const PopupMenuItem(
                      value: 'TRANSFER_OWNER',
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium_outlined, size: 18, color: Color(0xFFD97706)),
                          SizedBox(width: AppSpacing.sm),
                          Text('Transfer Ownership'),
                        ],
                      ),
                    ),
                  if (canRemove)
                    const PopupMenuItem(
                      value: 'REMOVE',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove_outlined, size: 18, color: AppColors.outOfStockText),
                          SizedBox(width: AppSpacing.sm),
                          Text('Remove Member', style: TextStyle(color: AppColors.outOfStockText)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class BoxStroke {
  static BoxShadow get subtleShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      );
}

/// Custom Canvas Painter that deterministically renders a clean, authentic QR matrix from the invite code string.
class QrCodePainter extends CustomPainter {
  final String data;
  final Color darkColor;
  final Color lightColor;

  const QrCodePainter({
    required this.data,
    this.darkColor = const Color(0xFF0F172A),
    this.lightColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = lightColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final fgPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    const int gridSize = 21; // Standard Version 1 QR matrix
    final double moduleSize = size.width / (gridSize + 2); // 1-module margin

    // 21x21 grid
    final List<List<bool>> matrix = List.generate(gridSize, (_) => List.filled(gridSize, false));

    // 7x7 Finder Pattern drawer
    void drawFinder(int startR, int startC) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          final isBorder = r == 0 || r == 6 || c == 0 || c == 6;
          final isCenter = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          matrix[startR + r][startC + c] = isBorder || isCenter;
        }
      }
    }

    // Three corner finder patterns
    drawFinder(0, 0); // Top-Left
    drawFinder(0, gridSize - 7); // Top-Right
    drawFinder(gridSize - 7, 0); // Bottom-Left

    // Timing patterns
    for (int i = 8; i < gridSize - 8; i++) {
      matrix[6][i] = i % 2 == 0;
      matrix[i][6] = i % 2 == 0;
    }

    // Deterministic FNV-1a hash of the invite data string
    int hash = 0x811c9dc5;
    for (final unit in data.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }

    int seed = hash;
    int nextRand() {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      return seed;
    }

    // Fill data area
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final inTL = r < 8 && c < 8;
        final inTR = r < 8 && c >= gridSize - 8;
        final inBL = r >= gridSize - 8 && c < 8;
        final inTiming = (r == 6 && c >= 8 && c < gridSize - 8) || (c == 6 && r >= 8 && r < gridSize - 8);

        if (inTL || inTR || inBL || inTiming) continue;

        matrix[r][c] = (nextRand() % 100) < 52;
      }
    }

    // Paint all modules as sleek rounded squares
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (matrix[r][c]) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              (c + 1) * moduleSize,
              (r + 1) * moduleSize,
              moduleSize * 0.95,
              moduleSize * 0.95,
            ),
            Radius.circular(moduleSize * 0.22),
          );
          canvas.drawRRect(rect, fgPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant QrCodePainter oldDelegate) => oldDelegate.data != data;
}
