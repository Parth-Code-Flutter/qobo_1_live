import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';

void main() {
  group('extractSuperAdminListMaps', () {
    test('supports legacy array data', () {
      final maps = extractSuperAdminListMaps(
        [
          {'id': 'a1', 'name': 'A'},
          {'id': 'a2', 'name': 'B'},
        ],
        nestedKey: 'agencies',
      );
      expect(maps.length, 2);
      expect(maps.first['id'], 'a1');
    });

    test('supports paginated agencies envelope', () {
      final maps = extractSuperAdminListMaps(
        {
          'total': 1,
          'page': 1,
          'limit': 20,
          'agencies': [
            {'id': 'agency-1', 'name': 'Star'},
          ],
        },
        nestedKey: 'agencies',
      );
      expect(maps.length, 1);
      expect(maps.first['name'], 'Star');
    });

    test('supports paginated hosts envelope', () {
      final maps = extractSuperAdminListMaps(
        {
          'total': 1,
          'hosts': [
            {'id': 'host-1', 'name': 'Host'},
          ],
        },
        nestedKey: 'hosts',
      );
      expect(maps.single['id'], 'host-1');
    });
  });

  group('detail models', () {
    test('parses agency detail', () {
      final detail = SuperAdminAgencyDetail.fromJson({
        'id': 'agency-uuid-1',
        'name': 'Superstar Agency Ltd',
        'code': 'XYZ890',
        'logo': 'https://example.com/logo.png',
        'commissionRate': 0.10,
        'status': 'approved',
        'feedback': null,
        'createdAt': '2026-07-18T10:15:30.000Z',
        'updatedAt': '2026-07-18T12:00:00.000Z',
        'address': {
          'country': 'India',
          'state': 'Gujarat',
          'city': 'Ahmedabad',
          'fullAddress': '123 Business Hub',
        },
        'owner': {
          'id': 'owner-user-id',
          'name': 'John Doe',
          'email': 'john@staragency.com',
          'phone': '+1234567890',
          'countryCode': '+91',
          'displayPicture': 'https://example.com/a.png',
          'role': 'agency',
        },
        'documents': {
          'docPhotoFront': 'https://example.com/f.png',
          'docPhotoBack': 'https://example.com/b.png',
        },
        'stats': {
          'hostCount': 12,
          'pendingHostsCount': 2,
          'activeHostsCount': 10,
          'totalCommissionEarned': 4500.5,
          'totalDiamonds': 0,
          'totalCoins': 0,
        },
        'invitedBy': {
          'id': 'sa-1',
          'name': 'Super Admin',
          'email': 'sa@qobo.com',
        },
      });

      expect(detail.isApproved, isTrue);
      expect(detail.owner.name, 'John Doe');
      expect(detail.stats.hostCount, 12);
      expect(detail.commissionRate, 0.10);
    });

    test('parses host detail', () {
      final detail = SuperAdminHostDetail.fromJson({
        'id': 'host-id',
        'name': 'Host Display Name',
        'email': 'host@gmail.com',
        'phone': '+1999999999',
        'countryCode': '+91',
        'displayPicture': 'https://example.com/h.png',
        'role': 'host',
        'status': 'active',
        'category': 'Singing',
        'dob': '1998-05-12T00:00:00.000Z',
        'gender': 'female',
        'country': 'India',
        'state': 'Maharashtra',
        'city': 'Mumbai',
        'address': '123 Street',
        'joinedAt': '2026-06-01T09:00:00.000Z',
        'agency': {
          'id': 'agency-uuid-1',
          'name': 'Superstar Agency Ltd',
          'code': 'XYZ890',
          'status': 'approved',
        },
        'earnings': {
          'diamonds': 450.0,
          'coins': 1200.0,
          'totalStreamSeconds': 36000.5,
          'totalCommissionEarned': 120.0,
          'coinsPerSecond': 5,
        },
        'documents': {
          'idNo': 'ID-900800',
          'docPhotoFront': 'https://example.com/f.png',
          'docPhotoBack': 'https://example.com/b.png',
          'photo': 'https://example.com/p.png',
        },
        'recentActivity': {
          'lastLiveAt': '2026-07-20T18:30:00.000Z',
          'isLiveNow': false,
          'totalSessions': 42,
        },
      });

      expect(detail.isActive, isTrue);
      expect(detail.agency.code, 'XYZ890');
      expect(detail.earnings.coins, 1200);
      expect(detail.recentActivity.totalSessions, 42);
    });

    test('parses enhanced dashboard stats', () {
      final stats = SuperAdminStats.fromJson({
        'totalAgencies': 5,
        'activeAgencies': 4,
        'suspendedAgencies': 1,
        'activeHosts': 42,
        'pendingAgencies': 2,
        'pendingHosts': 4,
        'liveHostsNow': 3,
        'totalCommissions': 12500.5,
        'commissionsThisMonth': 2100.25,
        'topAgencies': [
          {
            'id': 'a1',
            'name': 'Top',
            'code': 'TOP1',
            'totalCommissionEarned': 100,
          },
        ],
        'recentPendingAgencies': [],
      });

      expect(stats.liveHostsNow, 3);
      expect(stats.topAgencies.single.code, 'TOP1');
      expect(stats.commissionsThisMonth, 2100.25);
    });
  });
}
