import 'package:get/get.dart';
import 'package:qobo_one_live/models/geo/country_state_models.dart';
import 'package:qobo_one_live/repo/geo/geo_repo.dart';

/// Shared country/state list state for profile and host registration forms.
mixin CountryStateSelectionMixin on GetxController {
  GeoRepo get geoRepo => GeoRepo();

  final countries = <CountryOption>[].obs;
  final states = <StateOption>[].obs;
  final selectedCountry = Rxn<CountryOption>();
  final selectedState = Rxn<StateOption>();
  final isCountriesLoading = false.obs;
  final isStatesLoading = false.obs;

  Future<void>? _countriesLoadFuture;
  Future<void>? _statesLoadFuture;
  String? _statesLoadCountryId;

  /// Loads countries from API — waits for any in-flight request, then fetches if needed.
  Future<void> ensureCountriesLoaded({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _countriesLoadFuture = null;
      countries.clear();
    }
    if (countries.isNotEmpty && !forceRefresh) return;

    if (_countriesLoadFuture != null) {
      await _countriesLoadFuture;
      return;
    }

    _countriesLoadFuture = _fetchCountries();
    await _countriesLoadFuture;
    _countriesLoadFuture = null;
  }

  Future<void> _fetchCountries() async {
    try {
      isCountriesLoading.value = true;
      countries.assignAll(await geoRepo.fetchCountries(isShowLoader: false));
    } finally {
      isCountriesLoading.value = false;
    }
  }

  Future<void> selectCountry(CountryOption country) async {
    selectedCountry.value = country;
    selectedState.value = null;
    states.clear();
    _statesLoadFuture = null;
    _statesLoadCountryId = null;
    await loadStatesForCountry(country.id, forceRefresh: true);
  }

  Future<void> loadStatesForCountry(
    String countryId, {
    bool forceRefresh = false,
  }) async {
    final id = countryId.trim();
    if (id.isEmpty) return;

    if (!forceRefresh &&
        _statesLoadCountryId == id &&
        states.isNotEmpty &&
        _statesLoadFuture == null) {
      return;
    }

    if (_statesLoadFuture != null && _statesLoadCountryId == id) {
      await _statesLoadFuture;
      return;
    }

    _statesLoadCountryId = id;
    if (forceRefresh) states.clear();

    _statesLoadFuture = _fetchStates(id);
    await _statesLoadFuture;
    _statesLoadFuture = null;
  }

  Future<void> _fetchStates(String countryId) async {
    try {
      isStatesLoading.value = true;
      states.assignAll(
        await geoRepo.fetchStates(countryId: countryId, isShowLoader: false),
      );
    } finally {
      isStatesLoading.value = false;
    }
  }

  void selectState(StateOption state) {
    selectedState.value = state;
  }

  void clearCountryStateSelection() {
    selectedCountry.value = null;
    selectedState.value = null;
    states.clear();
    _statesLoadFuture = null;
    _statesLoadCountryId = null;
  }

  String? validateCountrySelection() {
    if (selectedCountry.value == null) return 'Country is required';
    return null;
  }

  String? validateStateSelection() {
    if (selectedState.value == null) return 'State is required';
    return null;
  }
}
