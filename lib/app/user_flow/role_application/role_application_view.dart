import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/app/user_flow/host_dashboard/host_dashboard_view.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/role_application_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/utils/app_widgets/common_media_picker.dart';
import 'package:qobo_one_live/utils/roles/recruitment_code_field.dart';
import 'package:qobo_one_live/utils/roles/recruitment_code_verification.dart';

class RoleApplicationView extends StatefulWidget {
  const RoleApplicationView({
    super.key,
    required this.role,
    this.initialCode = '',
    this.forAnotherUser = false,
    this.lockCode = false,
    this.statusOnly = false,
    this.initialLookup = '',
    this.repo,
    this.pickFiles,
  });
  final ApplicationRole role;
  final String initialCode;
  final bool forAnotherUser;
  final bool lockCode;
  final bool statusOnly;
  final String initialLookup;
  final RoleApplicationRepo? repo;
  final Future<List<String>> Function()? pickFiles;
  @override
  State<RoleApplicationView> createState() => _RoleApplicationViewState();
}

class _RoleApplicationViewState extends State<RoleApplicationView> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _agencyName = TextEditingController();
  final _description = TextEditingController();
  final _lookup = TextEditingController();
  late final RoleApplicationRepo _repo;
  late final RecruitmentCodeVerification _verification;
  bool _loading = true, _busy = false;
  bool _hasName = false, _hasPhone = false;
  File? _front, _back;
  Map<String, dynamic>? _application;
  String? _error;
  bool get _super => widget.role == ApplicationRole.superAdmin;
  bool get _agency => widget.role == ApplicationRole.agency;
  String get _title => _super
      ? 'Super Admin'
      : _agency
      ? 'Agency'
      : 'Host';

  @override
  void initState() {
    super.initState();
    _repo = widget.repo ?? RoleApplicationRepo();
    _code.text = widget.initialCode;
    _verification = RecruitmentCodeVerification(
      _code,
      (code) => _repo.verifyCode(widget.role, code),
    );
    _hydrate();
  }

  Future<void> _hydrate() async {
    if (!widget.forAnotherUser && Get.isRegistered<UserSessionController>()) {
      final session = Get.find<UserSessionController>();
      try {
        await session.refreshProfileFromApi();
      } catch (_) {
        // Use the current session snapshot; missing required fields remain editable.
      }
      if (!mounted) return;
      _name.text = session.userName;
      _phone.text = session.phone.replaceAll(RegExp(r'\D'), '');
      _hasName = _name.text.trim().isNotEmpty;
      _hasPhone = RegExp(r'^\d{6,15}$').hasMatch(_phone.text);
    }
    _lookup.text = _phone.text.isNotEmpty
        ? _phone.text
        : (widget.initialLookup.contains('@') ? '' : widget.initialLookup);
    if (_lookup.text.trim().isNotEmpty && !widget.forAnotherUser) {
      await _checkStatus(silent: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _verification.dispose();
    for (final c in [
      _code,
      _name,
      _phone,
      _agencyName,
      _lookup,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _noApplication(Object? status) => const {
    'none',
    'not_found',
    'not_applied',
    '',
  }.contains(status?.toString().trim().toLowerCase() ?? '');

  Future<void> _openApprovedDashboard() async {
    if (_busy || widget.forAnotherUser) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? route;
    bool hostReady = false;
    try {
      if (!Get.isRegistered<UserSessionController>()) {
        throw StateError('No session');
      }
      final session = Get.find<UserSessionController>();
      final refreshed = await session.refreshProfileFromApi();
      if (!mounted) return;
      if (!refreshed) {
        setState(
          () => _error = 'Unable to refresh your profile. Please try again.',
        );
      } else if (_super && session.isSuperAdmin) {
        route = Routes.SUPER_ADMIN_BOTTOM_NAV;
      } else if (_agency && session.isAgency) {
        route = Routes.AGENCY_OWNER;
      } else if (!_super && !_agency && session.isHost) {
        hostReady = true;
      } else {
        setState(
          () => _error =
              'Your application is approved, but your profile does not yet have dashboard access. Please sign out and sign in again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to refresh your profile. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (route != null) {
      Get.offNamed(route);
    } else if (hostReady) {
      Get.off(() => const HostDashboardView());
    }
  }

  Future<void> _checkStatus({bool silent = false}) async {
    if (_busy) return;
    if (_lookup.text.trim().isEmpty) _lookup.text = _phone.text.trim();
    if (_lookup.text.trim().isEmpty) {
      if (!silent) {
        setState(
          () => _error =
              'Add a phone number to your profile to check your application status.',
        );
      }
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await _repo.status(widget.role, _lookup.text);
      if (!mounted) return;
      final data = response?['data'];
      if (isAgencyApiSuccess(response) &&
          data is Map &&
          data['status'] != null) {
        setState(() {
          _application = _noApplication(data['status']) && !widget.statusOnly
              ? null
              : Map<String, dynamic>.from(data);
          if (_application == null && !silent) {
            _error = 'No application yet. Complete the form to apply.';
          }
        });
      } else if (!silent) {
        setState(
          () => _error = agencyApiMessage(response) ?? 'No application found.',
        );
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _error = 'Unable to check status. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<String>> _pickPhotoPaths() async {
    final source = await CommonMediaPicker.show(context);
    if (source == null || !mounted) return [];
    final photo = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    return photo == null ? [] : [photo.path];
  }

  Future<void> _pick(String which) async {
    final paths = await (widget.pickFiles?.call() ?? _pickPhotoPaths());
    if (!mounted || paths.isEmpty) return;
    setState(() {
      final file = File(paths.first);
      if (which == 'front') {
        _front = file;
      } else if (which == 'back') {
        _back = file;
      }
    });
  }

  Future<void> _submit() async {
    if (_busy ||
        _application != null ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    if (_super && (_front == null || _back == null)) {
      setState(() => _error = 'Upload both document photos.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_super && !await _verification.verify()) {
        if (mounted) setState(() => _error = _verification.message.value);
        return;
      }
      if (!mounted) return;
      final response = await _repo.submit(
        widget.role,
        code: _verification.verifiedCode,
        name: _name.text,
        phone: _phone.text,
        agencyName: _agencyName.text,
        description: _description.text,
        front: _front,
        back: _back,
      );
      if (!mounted) return;
      final data = response?['data'];
      if (isAgencyApiSuccess(response) &&
          data is Map &&
          data['status'] != null) {
        // Both first submissions and alreadySubmitted responses lead here.
        setState(() {
          _application = Map<String, dynamic>.from(data);
          _lookup.text = _phone.text;
        });
      } else {
        setState(
          () => _error =
              agencyApiMessage(response) ??
              'Unable to submit. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to submit. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController c, {
    bool required = true,
    bool phone = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        AppTextField(
          controller: c,
          borderColor: kColorHint,
          textStyle: TextStyles.kRegularPoppins(
            colors: kColorText,
            fontSize: 14,
          ),
          hintText: label,
          textInputType: phone ? TextInputType.phone : TextInputType.text,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return required ? '$label is required' : null;
            if (phone &&
                !RegExp(
                  r'^\d{6,15}$',
                ).hasMatch(text.replaceAll(RegExp(r'\D'), ''))) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    ),
  );

  Widget _primaryButton(String label, VoidCallback onPressed) => AbsorbPointer(
    absorbing: _busy,
    child: Opacity(
      opacity: _busy ? 0.6 : 1,
      child: appButton(onPressed: onPressed, buttonText: label),
    ),
  );

  Widget _upload(String label, String key, File? file) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: _busy ? null : () => _pick(key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kColorPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: file == null
                ? kColorHint.withValues(alpha: 0.35)
                : kColorPrimary.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          children: [
            Icon(
              file == null
                  ? Icons.add_photo_alternate_outlined
                  : Icons.check_circle,
              color: kColorPrimary,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file == null ? label : '$label • Selected',
                    style: TextStyles.kBoldPoppins(
                      colors: kColorText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file != null
                        ? 'Tap to replace photo'
                        : key == 'photo'
                        ? 'A clear photo of your face'
                        : key == 'front'
                        ? 'Front of your identity document'
                        : 'Back of your identity document',
                    style: TextStyles.kRegularPoppins(
                      colors: kColorHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kColorHint),
          ],
        ),
      ),
    ),
  );

  Widget _statusLookupCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kColorPrimary.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorPrimary.withValues(alpha: 0.16)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kColorPrimary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: kColorPrimary,
              size: 21,
            ),
          ),
          title: Text(
            'Already applied?',
            style: TextStyles.kBoldPoppins(colors: kColorText, fontSize: 13),
          ),
          subtitle: Text(
            'Check your application status',
            style: TextStyles.kRegularPoppins(colors: kColorHint, fontSize: 10),
          ),
          children: [
            const SizedBox(height: 8),
            Text(
              'We use your saved phone number to find your application.',
              style: TextStyles.kRegularPoppins(
                colors: kColorHint,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            _primaryButton('Check status', () => _checkStatus()),
          ],
        ),
      ),
    );
  }

  Widget _statusSummary(BuildContext context) {
    final status = _application!['status'].toString();
    final approved = isAgencyStatusApproved(status);
    final rejected = status.toLowerCase() == 'rejected';
    final empty = _noApplication(status);
    final pending = isAgencyStatusPending(status);
    final headline = empty
        ? 'No application yet'
        : approved
        ? 'Application approved'
        : rejected
        ? 'Application reviewed'
        : pending
        ? 'Under review'
        : 'Status unavailable';
    final feedback =
        (_application!['feedback'] ?? _application!['reason'] ?? '')
            .toString()
            .trim();
    final accent = approved ? const Color(0xFF8FE3C0) : const Color(0xFFDFC0FF);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Icon(
              approved
                  ? Icons.check_circle_outline_rounded
                  : rejected
                  ? Icons.info_outline_rounded
                  : empty || !pending
                  ? Icons.assignment_outlined
                  : Icons.hourglass_top_rounded,
              color: accent,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: TextStyles.kBoldPoppins(colors: AppLightUi.title, fontSize: 20),
        ),
        const SizedBox(height: 10),
        Text(
          approved
              ? 'Your $_title application has been approved.'
              : rejected
              ? 'Your application has been reviewed.'
              : empty
              ? 'Start your $_title application to get started.'
              : pending
              ? 'Your application has been received and is waiting for review.'
              : 'We could not identify your application status. Please refresh to try again.',
          textAlign: TextAlign.center,
          style: TextStyles.kRegularPoppins(
            colors: AppLightUi.subtitle,
            fontSize: 13,
          ),
        ),
        if (feedback.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(feedback, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppLightUi.cardSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                approved ? Icons.login_rounded : Icons.info_outline_rounded,
                color: accent,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approved || empty ? 'Next step' : 'Application update',
                      style: TextStyles.kBoldPoppins(
                        colors: AppLightUi.title,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      approved
                          ? widget.forAnotherUser
                                ? 'The applicant can sign in to access their dashboard.'
                                : 'Continue to refresh your profile and open your dashboard.'
                          : rejected
                          ? 'Review the feedback above. Refresh to check for any changes.'
                          : empty
                          ? 'Your saved profile details will be used when you apply.'
                          : pending
                          ? 'You do not need to apply again. Check back here for the decision.'
                          : 'Your application has not been changed. Try checking again shortly.',
                      style: TextStyles.kRegularPoppins(
                        colors: AppLightUi.subtitle,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusScreen = _application != null || widget.statusOnly;
    final foreground = AppLightUi.title;
    final textTheme = Theme.of(context).textTheme.apply(
      fontFamily: 'Poppins',
      bodyColor: foreground,
      displayColor: foreground,
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppShellBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppLightUi.title,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        statusScreen
                            ? 'Application status'
                            : 'Apply for $_title',
                        textAlign: TextAlign.center,
                        style: TextStyles.kBoldPoppins(
                          colors: AppLightUi.title,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  margin: statusScreen
                      ? const EdgeInsets.fromLTRB(20, 8, 20, 20)
                      : EdgeInsets.zero,
                  decoration: statusScreen
                      ? const BoxDecoration()
                      : const BoxDecoration(
                          color: AppLightUi.card,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textTheme: textTheme,
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: kColorPrimary,
                        onSurface: foreground,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: AppLightUi.pink,
                          textStyle: TextStyles.kRegularPoppins(fontSize: 12),
                        ),
                      ),
                      expansionTileTheme: const ExpansionTileThemeData(
                        textColor: kColorPrimary,
                        iconColor: kColorPrimary,
                        collapsedTextColor: kColorText,
                        collapsedIconColor: kColorHint,
                      ),
                      progressIndicatorTheme: ProgressIndicatorThemeData(
                        color: AppLightUi.pink,
                      ),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Builder(
                        builder: (context) => _loading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                padding: statusScreen
                                    ? EdgeInsets.zero
                                    : const EdgeInsets.all(24),
                                child: Container(
                                  padding: statusScreen
                                      ? const EdgeInsets.all(24)
                                      : EdgeInsets.zero,
                                  decoration: statusScreen
                                      ? AppLightUi.cardDecoration(radius: 24)
                                      : null,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (_application != null) ...[
                                        Text(
                                          _title,
                                          textAlign: TextAlign.center,
                                          style: TextStyles.kRegularPoppins(
                                            colors: AppLightUi.subtitle,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _statusSummary(context),
                                        if (isAgencyStatusApproved(
                                              _application!['status']
                                                  ?.toString(),
                                            ) &&
                                            !widget.forAnotherUser) ...[
                                          const SizedBox(height: 24),
                                          _primaryButton(
                                            _busy
                                                ? 'Please wait…'
                                                : 'Continue to dashboard',
                                            _openApprovedDashboard,
                                          ),
                                        ],
                                        if (_noApplication(
                                          _application!['status'],
                                        )) ...[
                                          const SizedBox(height: 24),
                                          _primaryButton(
                                            'Start application',
                                            () => Get.off(
                                              () => RoleApplicationView(
                                                role: widget.role,
                                                repo: widget.repo,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 24),
                                        _primaryButton(
                                          _busy
                                              ? 'Checking status…'
                                              : 'Refresh status',
                                          () => _checkStatus(),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () =>
                                              Get.back(result: true),
                                          child: const Text('Done'),
                                        ),
                                      ] else if (widget.statusOnly) ...[
                                        const Text(
                                          'Check the application linked to your saved phone number.',
                                        ),
                                        const SizedBox(height: 16),
                                        _primaryButton(
                                          'Check status',
                                          () => _checkStatus(),
                                        ),
                                      ] else ...[
                                        Text(
                                          _super
                                              ? 'Verify your identity'
                                              : 'Complete your application',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineSmall,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Your saved profile details are filled automatically. Upload clear photos for your application review.',
                                        ),
                                        const SizedBox(height: 24),
                                        Form(
                                          key: _form,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              if (!_super)
                                                RecruitmentCodeField(
                                                  verification: _verification,
                                                  label: 'Enter code',
                                                  readOnly: widget.lockCode,
                                                ),
                                              if (!_super)
                                                const SizedBox(height: 16),
                                              if (_agency)
                                                _field(
                                                  'Agency name',
                                                  _agencyName,
                                                ),
                                              if (!_hasName)
                                                _field(
                                                  'Full name',
                                                  _name,
                                                  required: true,
                                                ),
                                              if (!_hasPhone)
                                                _field(
                                                  'Phone number',
                                                  _phone,
                                                  phone: true,
                                                  required: true,
                                                ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _super
                                                          ? 'Verification photos'
                                                          : 'Verification photos (optional)',
                                                      style:
                                                          TextStyles.kBoldPoppins(
                                                            colors: kColorText,
                                                            fontSize: 14,
                                                          ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${[_front, _back].whereType<File>().length}/2 added',
                                                    style:
                                                        TextStyles.kRegularPoppins(
                                                          colors: kColorPrimary,
                                                          fontSize: 12,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              _upload(
                                                'Document front',
                                                'front',
                                                _front,
                                              ),
                                              _upload(
                                                'Document back',
                                                'back',
                                                _back,
                                              ),
                                              ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Description (optional)',
                                                  style:
                                                      TextStyles.kRegularPoppins(
                                                        colors: kColorText,
                                                        fontSize: 12,
                                                      ),
                                                ),
                                                const SizedBox(height: 6),
                                                AppTextField(
                                                  controller: _description,
                                                  hintText:
                                                      'Add a short description',
                                                  minLines: 2,
                                                  maxLines: 2,
                                                  borderColor: kColorHint,
                                                  textInputType:
                                                      TextInputType.multiline,
                                                  textInputAction:
                                                      TextInputAction.newline,
                                                  textStyle:
                                                      TextStyles.kRegularPoppins(
                                                        colors: kColorText,
                                                        fontSize: 14,
                                                      ),
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                              _primaryButton(
                                                'Submit application',
                                                _submit,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        _statusLookupCard(),
                                      ],
                                      if (_busy)
                                        const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                      if (_error != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 16,
                                          ),
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
