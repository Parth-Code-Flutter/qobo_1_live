import 'package:get/get.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/constants/image_constants.dart';

/// Controller for live room flow.
class LiveRoomController extends GetxController {
  final RoomRepo _roomRepo = RoomRepo();

  int selectedCategoryIndex = 0;
  final isLoading = false.obs;
  final rooms = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchActiveRooms();
  }

  void onCategorySelected(int index) {
    if (selectedCategoryIndex == index) return;
    selectedCategoryIndex = index;
    update();
    fetchActiveRooms();
  }

  Future<void> fetchActiveRooms() async {
    try {
      isLoading.value = true;
      // Map category tab to room type or country filter
      // Tab 0: Sab (All, load VIDEO by default)
      // Tab 1: Shresth (Load AUDIO rooms)
      // Tab 2: Naya (Load VIDEO rooms)
      // Tab 3: Bangladesh (Load with country filter)
      String type = 'VIDEO';
      String? country;
      
      if (selectedCategoryIndex == 1) {
        type = 'AUDIO';
      } else if (selectedCategoryIndex == 3) {
        country = 'BD';
      }

      final response = await _roomRepo.listActiveRooms(type: type, country: country, isShowLoader: false);
      
      final List<Map<String, dynamic>> fetchedList = [];
      if (response != null && response['statusCode'] == 1 && response['data'] is List) {
        final rawRooms = response['data'] as List;
        for (final item in rawRooms) {
          if (item is Map) {
            fetchedList.add({
              'id': item['_id'] ?? item['id'] ?? '',
              'nameAge': '${item['name'] ?? 'Room'}, ${item['maxSeats'] ?? 8} Seats',
              'badge': item['type'] ?? 'VIDEO',
              'location': item['country'] ?? 'IN',
              'points': '100',
              'favorite': false,
              'image': item['type'] == 'AUDIO' ? kImgTemp2 : kImgTemp3,
            });
          }
        }
      }

      // Fallback list to display beautiful mock rooms if backend has none
      if (fetchedList.isEmpty) {
        fetchedList.addAll([
          {
            'id': 'mock_1',
            'nameAge': 'Mariana, 25',
            'badge': 'Premier',
            'location': 'Roha',
            'points': '2105',
            'favorite': false,
            'image': kImgTemp2,
          },
          {
            'id': 'mock_2',
            'nameAge': 'Afrin, 22',
            'badge': 'Premier',
            'location': 'Roha',
            'points': '2105',
            'favorite': true,
            'image': kImgTemp3,
          },
          {
            'id': 'mock_3',
            'nameAge': 'Zara, 24',
            'badge': 'Hourly',
            'location': 'Dhaka',
            'points': '1950',
            'favorite': false,
            'image': kImgTemp4,
          },
          {
            'id': 'mock_4',
            'nameAge': 'Elena, 26',
            'badge': 'Supreme',
            'location': 'Mumbai',
            'points': '3200',
            'favorite': false,
            'image': kImgTemp5,
          },
        ]);
      }
      
      rooms.assignAll(fetchedList);
    } catch (_) {
      // ignore
    } finally {
      isLoading.value = false;
    }
  }
}
