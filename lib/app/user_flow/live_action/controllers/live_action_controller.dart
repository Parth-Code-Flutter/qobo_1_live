import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/bottom_nav/controllers/bottom_nav_controller.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/app/user_flow/live_action/models/live_map_host.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';

/// In-room live action UI state (heart tab / agency host map).
class LiveActionController extends GetxController {
  final messageController = TextEditingController();

  List<LiveMapHost> mapHosts = List<LiveMapHost>.from(_defaultDiscoverHosts);
  bool isAgencyHostsView = false;
  List<String> suggestionAssets = List<String>.from(_suggestionPool);

  @override
  void onInit() {
    super.onInit();
    configureDiscoverHosts();
  }

  static const _defaultDiscoverHosts = <LiveMapHost>[
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.10',
      imageAsset: kImgTemp2,
      alignment: Alignment(-0.68, -0.82),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.08',
      imageAsset: kImgTemp3,
      alignment: Alignment(0.54, -0.84),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.09',
      imageAsset: kImgTemp4,
      alignment: Alignment(-0.10, -0.42),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.12',
      imageAsset: kImgTemp5,
      alignment: Alignment(0.62, -0.30),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.07',
      imageAsset: kImgTemp3,
      alignment: Alignment(-0.78, 0.10),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.14',
      imageAsset: kImgTemp2,
      alignment: Alignment(0.10, 0.10),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.11',
      imageAsset: kImgTemp4,
      alignment: Alignment(0.56, 0.46),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.06',
      imageAsset: kImgTemp5,
      alignment: Alignment(0.08, 0.78),
    ),
  ];

  static const _agencyAlignments = <Alignment>[
    Alignment(-0.35, -0.55),
    Alignment(0.42, -0.35),
    Alignment(-0.55, 0.05),
    Alignment(0.28, 0.22),
    Alignment(-0.12, -0.15),
    Alignment(0.62, 0.48),
    Alignment(-0.72, 0.42),
    Alignment(0.05, 0.72),
  ];

  static const _suggestionPool = <String>[
    kImgTemp2,
    kImgTemp3,
    kImgTemp4,
    kImgTemp5,
    kImgTemp2,
    kImgTemp3,
    kImgTemp4,
  ];

  /// Shows agency hosts on the heart map (from owner dashboard).
  void configureAgencyHosts() {
    isAgencyHostsView = true;
    final session = Get.isRegistered<AgencySessionController>()
        ? Get.find<AgencySessionController>()
        : null;
    final hosts = session != null && session.cachedHosts.isNotEmpty
        ? session.cachedHosts
        : AgencyRevenueDemo.hosts;
    final mapped = <LiveMapHost>[];
    for (var i = 0; i < hosts.length; i++) {
      final host = hosts[i];
      mapped.add(
        LiveMapHost(
          name: host.name,
          levelBadge: 'LV.${host.coinsPerSecond}',
          imageAsset: _suggestionPool[i % _suggestionPool.length],
          alignment: _agencyAlignments[i % _agencyAlignments.length],
          isAgencyHost: true,
        ),
      );
    }
    // Fill map with discover-style nodes so the network matches the design.
    for (var i = hosts.length; i < _agencyAlignments.length; i++) {
      final template = _defaultDiscoverHosts[i % _defaultDiscoverHosts.length];
      mapped.add(
        LiveMapHost(
          name: template.name,
          levelBadge: template.levelBadge,
          imageAsset: template.imageAsset,
          alignment: _agencyAlignments[i],
        ),
      );
    }
    mapHosts = mapped;
    suggestionAssets = mapped.take(7).map((h) => h.imageAsset).toList();
    update();
  }

  void configureDiscoverHosts() {
    isAgencyHostsView = false;
    mapHosts = List<LiveMapHost>.from(_defaultDiscoverHosts);
    suggestionAssets = List<String>.from(_suggestionPool);
    update();
  }

  void onBackPressed() {
    if (isAgencyHostsView) {
      configureDiscoverHosts();
      if (Get.currentRoute != Routes.AGENCY_OWNER) {
        Get.toNamed(Routes.AGENCY_OWNER);
      } else {
        Get.back<void>();
      }
      return;
    }

    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().onNavBarTabSelected(0);
      return;
    }
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
