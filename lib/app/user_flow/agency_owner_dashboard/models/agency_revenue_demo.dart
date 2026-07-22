/// Client-preview demo data for agency owner revenue (replace with API later).
abstract final class AgencyRevenueDemo {
  static const ownerName = 'Jitendra Joshi';
  static const ownerCoinsPerSecond = 2;
  static const agencyName = 'Fun Call';
  static const agencyCode = 'FUN-CALL-01';

  /// Gross coins from host calls this month (before split).
  static const totalCallingGross = 2700;

  /// Viewer gifts sent to hosts under agency.
  static const totalGiftsVolume = 730;

  /// Company retains 50% of call gross per product rules.
  static const companyShare = 1350;

  /// Hosts retain 50% of call gross.
  static const hostCallShare = 1350;

  /// Owner commission: 2 coins/sec × total talk seconds (540 sec sample).
  static const ownerCommissionCoins = 1080;

  static const totalAgencyEarnings =
      hostCallShare + totalGiftsVolume + ownerCommissionCoins;

  static const availableForPayout = 2840;
  static const activeHosts = 2;
  static const totalTalkMinutes = 9;

  static const sampleCall = AgencyCallSample(
    hostName: 'Monika',
    viewerName: 'Parth',
    durationSeconds: 300,
    coinsPerSecond: 5,
    grossCoins: 1500,
    companyCoins: 750,
    hostCoins: 750,
    giftsDuringCall: 120,
  );

  static const hosts = <AgencyHostRevenueDemo>[
    AgencyHostRevenueDemo(
      id: 'HOST-1001',
      name: 'Monika',
      status: 'active',
      coinsPerSecond: 5,
      totalEarnings: 1170,
      totalGifts: 420,
      totalCallingSpend: 1500,
      callingMinutes: 5,
      lastViewer: 'Parth',
    ),
    AgencyHostRevenueDemo(
      id: 'HOST-1002',
      name: 'Jui',
      status: 'active',
      coinsPerSecond: 5,
      totalEarnings: 890,
      totalGifts: 310,
      totalCallingSpend: 1200,
      callingMinutes: 4,
      lastViewer: 'Parth',
    ),
  ];

  static const revenueHistory = <AgencyRevenueHistoryDemo>[
    AgencyRevenueHistoryDemo(
      date: '4 Jun 2026',
      title: 'Call — Monika × Parth',
      amount: '+1,500',
      subtitle: '5 min · 5 coins/sec · 750 host / 750 company',
      type: AgencyRevenueLineType.call,
    ),
    AgencyRevenueHistoryDemo(
      date: '3 Jun 2026',
      title: 'Gifts — Monika',
      amount: '+420',
      subtitle: 'Viewer gifts during live',
      type: AgencyRevenueLineType.gift,
    ),
    AgencyRevenueHistoryDemo(
      date: '2 Jun 2026',
      title: 'Call — Jui × Parth',
      amount: '+1,200',
      subtitle: '4 min · 5 coins/sec · 600 host / 600 company',
      type: AgencyRevenueLineType.call,
    ),
    AgencyRevenueHistoryDemo(
      date: '1 Jun 2026',
      title: 'Owner commission',
      amount: '+1,080',
      subtitle: '2 coins/sec on agency talk time',
      type: AgencyRevenueLineType.owner,
    ),
  ];
}

enum AgencyRevenueLineType { call, gift, owner, payout }

class AgencyCallSample {
  const AgencyCallSample({
    required this.hostName,
    required this.viewerName,
    required this.durationSeconds,
    required this.coinsPerSecond,
    required this.grossCoins,
    required this.companyCoins,
    required this.hostCoins,
    required this.giftsDuringCall,
  });

  final String hostName;
  final String viewerName;
  final int durationSeconds;
  final int coinsPerSecond;
  final int grossCoins;
  final int companyCoins;
  final int hostCoins;
  final int giftsDuringCall;

  int get durationMinutes => durationSeconds ~/ 60;
}

class AgencyHostRevenueDemo {
  const AgencyHostRevenueDemo({
    required this.id,
    required this.name,
    required this.status,
    required this.coinsPerSecond,
    required this.totalEarnings,
    required this.totalGifts,
    required this.totalCallingSpend,
    required this.callingMinutes,
    required this.lastViewer,
    this.photoUrl,
    this.applicationId = '',
    this.phone = '',
    this.gmail = '',
    this.category = '',
    this.reason,
    this.createdAt = '',
  });

  final String id;
  final String name;
  final String status;
  final int coinsPerSecond;
  final int totalEarnings;
  final int totalGifts;
  final int totalCallingSpend;
  final int callingMinutes;
  final String lastViewer;
  final String? photoUrl;
  final String applicationId;
  final String phone;
  final String gmail;
  final String category;
  final String? reason;
  final String createdAt;
}

class AgencyRevenueHistoryDemo {
  const AgencyRevenueHistoryDemo({
    required this.date,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.type,
  });

  final String date;
  final String title;
  final String amount;
  final String subtitle;
  final AgencyRevenueLineType type;
}
