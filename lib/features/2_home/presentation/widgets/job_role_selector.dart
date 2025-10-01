import 'package:flutter/material.dart';
import '../../../../core/constants/theme.dart';

class JobRoleSelector extends StatefulWidget {
  final String? selectedRole;
  final Function(String) onRoleSelected;
  final List<String> jobRoles;

  const JobRoleSelector({
    super.key,
    this.selectedRole,
    required this.onRoleSelected,
    required this.jobRoles,
  });

  @override
  State<JobRoleSelector> createState() => _JobRoleSelectorState();
}

class _JobRoleSelectorState extends State<JobRoleSelector> {
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.selectedRole;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Job Role',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.paddingS),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
            border: Border.all(color: AppTheme.borderColor, width: 1),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              ...widget.jobRoles.asMap().entries.map((entry) {
                final index = entry.key;
                final role = entry.value;
                final isSelected = _selectedRole == role;
                final isLast = index == widget.jobRoles.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: AppTheme.borderColor,
                              width: 0.5,
                            ),
                          ),
                  ),
                  child: ListTile(
                    title: Text(
                      role,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.accentColor
                            : AppTheme.textPrimaryColor,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: AppTheme.fontSizeRegular,
                      ),
                    ),
                    leading: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentColor
                              : AppTheme.borderColor,
                          width: 2,
                        ),
                        color: isSelected
                            ? AppTheme.accentColor
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    trailing: _getRoleIcon(role),
                    onTap: () {
                      setState(() {
                        _selectedRole = role;
                      });
                      widget.onRoleSelected(role);
                    },
                    selected: isSelected,
                    selectedTileColor: AppTheme.accentColor.withValues(
                      alpha: 0.1,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Icon _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'software developer':
      case 'full stack developer':
      case 'frontend developer':
      case 'backend developer':
        return Icon(Icons.code, color: AppTheme.accentColor, size: 20);
      case 'data scientist':
      case 'data analyst':
        return Icon(Icons.analytics, color: AppTheme.accentColor, size: 20);
      case 'product manager':
        return Icon(Icons.inventory, color: AppTheme.accentColor, size: 20);
      case 'ui/ux designer':
      case 'designer':
        return Icon(
          Icons.design_services,
          color: AppTheme.accentColor,
          size: 20,
        );
      case 'marketing manager':
      case 'digital marketer':
        return Icon(Icons.campaign, color: AppTheme.accentColor, size: 20);
      case 'business analyst':
        return Icon(
          Icons.business_center,
          color: AppTheme.accentColor,
          size: 20,
        );
      case 'project manager':
        return Icon(
          Icons.manage_accounts,
          color: AppTheme.accentColor,
          size: 20,
        );
      default:
        return Icon(Icons.work, color: AppTheme.accentColor, size: 20);
    }
  }
}

class JobRoleChips extends StatefulWidget {
  final List<String> jobRoles;
  final List<String> selectedRoles;
  final Function(List<String>) onSelectionChanged;
  final bool multiSelect;

  const JobRoleChips({
    super.key,
    required this.jobRoles,
    required this.selectedRoles,
    required this.onSelectionChanged,
    this.multiSelect = true,
  });

  @override
  State<JobRoleChips> createState() => _JobRoleChipsState();
}

class _JobRoleChipsState extends State<JobRoleChips> {
  late List<String> _selectedRoles;

  @override
  void initState() {
    super.initState();
    _selectedRoles = List.from(widget.selectedRoles);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.jobRoles.map((role) {
        final isSelected = _selectedRoles.contains(role);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (widget.multiSelect) {
                if (isSelected) {
                  _selectedRoles.remove(role);
                } else {
                  _selectedRoles.add(role);
                }
              } else {
                _selectedRoles.clear();
                _selectedRoles.add(role);
              }
            });
            widget.onSelectionChanged(_selectedRoles);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentColor
                  : AppTheme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.accentColor : AppTheme.borderColor,
                width: 1,
              ),
            ),
            child: Text(
              role,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
