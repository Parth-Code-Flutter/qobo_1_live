import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_clock_finish.dart';

void main() {
  test('a running battle clock reveals a winner when time is over', () {
    expect(
      pkBattleClockShouldFinish(
        battleOnScreen: true,
        remainingSeconds: 0,
        clockHasRun: true,
        alreadyHandled: false,
        earlyFinishBufferSec: 0,
      ),
      isTrue,
    );
    expect(
      pkBattleClockShouldFinish(
        battleOnScreen: true,
        remainingSeconds: 5,
        clockHasRun: true,
        alreadyHandled: false,
        earlyFinishBufferSec: 0,
      ),
      isFalse,
    );
  });

  test('the starting stage still finishes when its clock hits zero', () {
    expect(
      pkBattleClockShouldFinish(
        battleOnScreen: true,
        remainingSeconds: 0,
        clockHasRun: true,
        alreadyHandled: false,
        earlyFinishBufferSec: 0,
      ),
      isTrue,
    );
  });

  test('a new session that arrives at 0 does not finish immediately', () {
    expect(
      pkBattleClockShouldFinish(
        battleOnScreen: true,
        remainingSeconds: 0,
        clockHasRun: false,
        alreadyHandled: false,
      ),
      isFalse,
    );
  });

  test('time still on the clock does not finish', () {
    expect(
      pkBattleClockShouldFinish(
        battleOnScreen: true,
        remainingSeconds: 44,
        clockHasRun: true,
        alreadyHandled: false,
      ),
      isFalse,
    );
  });

  test('a finished battle is not revealed twice', () {
    expect(
      pkBattleClockShouldFinish(
        battleOnScreen: true,
        remainingSeconds: 0,
        clockHasRun: true,
        alreadyHandled: true,
        earlyFinishBufferSec: 0,
      ),
      isFalse,
    );
  });

  test('the clock does not finish when the PK stage is not up', () {
    expect(
      pkBattleClockShouldFinish(
        battleOnScreen: false,
        remainingSeconds: 0,
        clockHasRun: true,
        alreadyHandled: false,
        earlyFinishBufferSec: 0,
      ),
      isFalse,
    );
  });
}
