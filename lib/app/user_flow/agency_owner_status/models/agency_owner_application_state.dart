/// Super-admin review state for "become an agency" applications.
enum AgencyOwnerApplicationState {
  none,
  pending,
  approved,
  rejected;

  static AgencyOwnerApplicationState fromApi(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value == 'approved' || value == 'active') {
      return AgencyOwnerApplicationState.approved;
    }
    if (value == 'rejected' || value == 'declined') {
      return AgencyOwnerApplicationState.rejected;
    }
    if (value == 'pending' ||
        value == 'under_review' ||
        value == 'under review' ||
        value == 'submitted') {
      return AgencyOwnerApplicationState.pending;
    }
    return AgencyOwnerApplicationState.none;
  }

  String get apiLabel {
    switch (this) {
      case AgencyOwnerApplicationState.none:
        return 'none';
      case AgencyOwnerApplicationState.pending:
        return 'pending';
      case AgencyOwnerApplicationState.approved:
        return 'approved';
      case AgencyOwnerApplicationState.rejected:
        return 'rejected';
    }
  }
}
