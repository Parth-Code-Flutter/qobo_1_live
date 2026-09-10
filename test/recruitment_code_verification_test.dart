import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/utils/roles/recruitment_code_verification.dart';

void main() {
  Map<String, dynamic> valid() => {
    'statusCode': 1,
    'data': {'valid': true, 'agencyName': 'Apex'},
  };
  test('editing a verified code immediately invalidates it', () async {
    final input = TextEditingController(text: 'APEX99');
    final state = RecruitmentCodeVerification(input, (_) async => valid());
    expect(await state.verify(), isTrue);
    expect(state.verifiedCode, 'APEX99');
    input.text = 'OTHER';
    expect(state.isVerified.value, isFalse);
    expect(state.verifiedCode, isEmpty);
    state.dispose();
    input.dispose();
  });
  test(
    'old response cannot verify a changed code, even changed back',
    () async {
      final input = TextEditingController(text: 'A');
      final response = Completer<Map<String, dynamic>?>();
      final state = RecruitmentCodeVerification(input, (_) => response.future);
      final result = state.verify();
      input.text = 'B';
      input.text = 'A';
      response.complete(valid());
      expect(await result, isFalse);
      expect(state.verifiedCode, isEmpty);
      state.dispose();
      input.dispose();
    },
  );
  test(
    'invalid and malformed success responses never allow submission',
    () async {
      for (final response in [
        null,
        {
          'statusCode': 0,
          'data': {'valid': true},
        },
        {
          'statusCode': 1,
          'data': {'valid': false},
        },
        {'statusCode': 1, 'data': {}},
      ]) {
        final input = TextEditingController(text: 'A');
        final state = RecruitmentCodeVerification(input, (_) async => response);
        expect(await state.verify(), isFalse);
        expect(state.verifiedCode, isEmpty);
        state.dispose();
        input.dispose();
      }
    },
  );
  test('network error releases busy state and allows retry', () async {
    var attempts = 0;
    final input = TextEditingController(text: 'A');
    final state = RecruitmentCodeVerification(input, (_) async {
      if (++attempts == 1) throw Exception('offline');
      return valid();
    });
    expect(await state.verify(), isFalse);
    expect(state.isChecking.value, isFalse);
    expect(await state.verify(), isTrue);
    state.dispose();
    input.dispose();
  });
  test('duplicate verification does not send a second request', () async {
    var count = 0;
    final input = TextEditingController(text: 'A');
    final response = Completer<Map<String, dynamic>?>();
    final state = RecruitmentCodeVerification(input, (_) {
      count++;
      return response.future;
    });
    final first = state.verify();
    expect(await state.verify(), isFalse);
    response.complete(valid());
    await first;
    expect(count, 1);
    state.dispose();
    input.dispose();
  });
}
