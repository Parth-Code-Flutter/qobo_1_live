import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/super_admin/super_admin_repo.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Super Admin must pick an agency before calling `/api/agency/dashboard`
/// (backend requires `agency_id` for non-owner tokens).
abstract final class SuperAdminAgencyPickerSheet {
  SuperAdminAgencyPickerSheet._();

  static Future<SuperAdminAgencyItem?> show() {
    return Get.bottomSheet<SuperAdminAgencyItem>(
      const _SuperAdminAgencyPickerBody(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: kColorBlack.withValues(alpha: 0.55),
    );
  }
}

class _SuperAdminAgencyPickerBody extends StatefulWidget {
  const _SuperAdminAgencyPickerBody();

  @override
  State<_SuperAdminAgencyPickerBody> createState() =>
      _SuperAdminAgencyPickerBodyState();
}

class _SuperAdminAgencyPickerBodyState
    extends State<_SuperAdminAgencyPickerBody> {
  final _repo = SuperAdminRepo();
  final _searchController = TextEditingController();

  bool _loading = true;
  String _error = '';
  List<SuperAdminAgencyItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String search = ''}) async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await _repo.getAgencies(
        status: 'approved',
        search: search,
        limit: 50,
        isShowLoader: false,
      );
      if (!mounted) return;
      if (isAgencyApiSuccess(response)) {
        final maps = extractSuperAdminListMaps(
          response?['data'],
          nestedKey: 'agencies',
        );
        var parsed = maps.map(SuperAdminAgencyItem.fromJson).toList();
        // Fallback if backend uses `active` / omits `approved` filter.
        if (parsed.isEmpty && search.trim().isEmpty) {
          final allResponse = await _repo.getAgencies(
            status: 'all',
            limit: 50,
            isShowLoader: false,
          );
          if (isAgencyApiSuccess(allResponse)) {
            final allMaps = extractSuperAdminListMaps(
              allResponse?['data'],
              nestedKey: 'agencies',
            );
            parsed = allMaps
                .map(SuperAdminAgencyItem.fromJson)
                .where((e) => e.isApproved)
                .toList();
          }
        }
        setState(() {
          _items = parsed.where((e) => e.id.trim().isNotEmpty).toList();
          _loading = false;
        });
        return;
      }
      setState(() {
        _items = const [];
        _loading = false;
        _error =
            agencyApiMessage(response) ?? 'Unable to load agencies.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error = 'Network error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2B1654).withValues(alpha: 0.96),
                const Color(0xFF171339).withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Spacing.v12,
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kColorWhite.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SemiBoldText(
                            text: 'Select agency',
                            fontSize: TextStyles.k18FontSize,
                            color: kColorWhite,
                          ),
                          Spacing.v4,
                          AppText(
                            text:
                                'Super Admin must choose an agency to open its dashboard',
                            fontSize: TextStyles.k12FontSize,
                            color: kColorWhite.withValues(alpha: 0.72),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back<void>(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: kColorWhite.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: kColorWhite),
                  cursorColor: const Color(0xFFFF3EA5),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => _load(search: value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search agency name or code',
                    hintStyle: TextStyle(
                      color: kColorWhite.withValues(alpha: 0.45),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: kColorWhite.withValues(alpha: 0.55),
                    ),
                    filled: true,
                    fillColor: kColorWhite.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              Spacing.v12,
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF3EA5)),
      );
    }
    if (_error.isNotEmpty && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                text: _error,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.8),
                align: TextAlign.center,
              ),
              Spacing.v16,
              TextButton(
                onPressed: () => _load(search: _searchController.text.trim()),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFFFF3EA5)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: AppText(
          text: 'No approved agencies found',
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite.withValues(alpha: 0.7),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: _items.length,
      separatorBuilder: (_, __) => Spacing.v10,
      itemBuilder: (_, index) {
        final agency = _items[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Get.back(result: agency),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: kColorWhite.withValues(alpha: 0.07),
                border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF355D).withValues(alpha: 0.9),
                          const Color(0xFFFF3EA5).withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: SemiBoldText(
                      text: agency.name.isNotEmpty
                          ? agency.name[0].toUpperCase()
                          : 'A',
                      fontSize: TextStyles.k16FontSize,
                      color: kColorWhite,
                    ),
                  ),
                  Spacing.h12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SemiBoldText(
                          text: agency.name,
                          fontSize: TextStyles.k14FontSize,
                          color: kColorWhite,
                        ),
                        Spacing.v4,
                        AppText(
                          text: agency.code.isNotEmpty
                              ? '${agency.code} · ${agency.ownerName}'
                              : agency.ownerName,
                          fontSize: TextStyles.k10FontSize,
                          color: kColorWhite.withValues(alpha: 0.65),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: kColorWhite.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
