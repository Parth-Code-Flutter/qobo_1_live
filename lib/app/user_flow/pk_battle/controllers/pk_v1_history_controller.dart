import 'package:get/get.dart';
import 'package:qobo_one_live/repo/pk/pk_v1_repo.dart';

/// One row in the PK history list (parsed defensively).
class PkHistoryItem {
  const PkHistoryItem({
    required this.pkId,
    required this.opponentName,
    required this.opponentAvatar,
    required this.winnerSide,
    required this.outcome,
    required this.scoreA,
    required this.scoreB,
    required this.dateLabel,
  });

  final String pkId;
  final String opponentName;
  final String opponentAvatar;
  final String winnerSide;

  /// Result relative to the current user, if the backend provides it:
  /// `WIN` | `LOSE` | `TIE`. Empty when unknown.
  final String outcome;
  final int scoreA;
  final int scoreB;
  final String dateLabel;

  factory PkHistoryItem.fromJson(Map<String, dynamic> j) {
    String s(List<String> keys) {
      for (final k in keys) {
        final v = j[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return '';
    }

    int i(List<String> keys) {
      for (final k in keys) {
        final v = j[k];
        if (v is num) return v.toInt();
        final p = int.tryParse(v?.toString() ?? '');
        if (p != null) return p;
      }
      return 0;
    }

    final createdAt = s(['createdAt', 'created_at', 'endedAt', 'ended_at']);
    return PkHistoryItem(
      pkId: s(['pkId', 'pk_id', 'id']),
      opponentName:
          s(['opponentName', 'opponent_name', 'opponentDisplayName']),
      opponentAvatar: s(['opponentAvatar', 'opponent_avatar']),
      winnerSide: s(['winnerSide', 'winner_side']).toUpperCase(),
      outcome: s(['result', 'outcome', 'userResult']).toUpperCase(),
      scoreA: i(['scoreA', 'score_a']),
      scoreB: i(['scoreB', 'score_b']),
      dateLabel: _formatDate(createdAt),
    );
  }

  static String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class PkV1HistoryController extends GetxController {
  PkV1HistoryController({PkV1Repo? repo}) : _repo = repo ?? PkV1Repo();

  final PkV1Repo _repo;

  final items = <PkHistoryItem>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      isLoading.value = true;
      final body = await _repo.getHistory();
      final data = PkV1Repo.dataOf(body);
      final list = (data['items'] as List?) ?? (body?['data'] as List?) ?? [];
      items.assignAll(
        list
            .whereType<Map>()
            .map((e) => PkHistoryItem.fromJson(
                  e.map((k, v) => MapEntry(k.toString(), v)),
                ))
            .toList(),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
