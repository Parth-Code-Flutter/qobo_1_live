/// Whether the on-screen PK clock should reveal a winner now.
///
/// [battleOnScreen] is true while the PK stage is up, including the starting
/// stage. Auto-end used to run only in the battling stage, so a clock that
/// reached 00:00 stayed up until the host tapped End PK.
///
/// [clockHasRun] is true after the timer has shown time above the finish
/// window, so a brand-new session that arrives with 0 seconds does not end
/// immediately.
bool pkBattleClockShouldFinish({
  required bool battleOnScreen,
  required int remainingSeconds,
  required bool clockHasRun,
  required bool alreadyHandled,
  int earlyFinishBufferSec = 5,
}) {
  if (alreadyHandled || !clockHasRun || !battleOnScreen) return false;
  return remainingSeconds <= earlyFinishBufferSec;
}
