/// Active filters for `GET /api/discover`.
class DiscoverFilterState {
  const DiscoverFilterState({
    this.country,
    this.gender,
    this.excludeFollowing = false,
  });

  final String? country;
  final String? gender;
  final bool excludeFollowing;

  bool get hasActiveFilters =>
      (country != null && country!.trim().isNotEmpty) ||
      (gender != null && gender!.trim().isNotEmpty) ||
      excludeFollowing;

  DiscoverFilterState copyWith({
    String? country,
    String? gender,
    bool? excludeFollowing,
    bool clearCountry = false,
    bool clearGender = false,
  }) {
    return DiscoverFilterState(
      country: clearCountry ? null : (country ?? this.country),
      gender: clearGender ? null : (gender ?? this.gender),
      excludeFollowing: excludeFollowing ?? this.excludeFollowing,
    );
  }

  static const genderMale = 'male';
  static const genderFemale = 'female';
}
