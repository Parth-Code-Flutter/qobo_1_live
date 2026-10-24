# Lucky client demo artwork
Downloaded from https://github.com/microsoft/fluentui-emoji (Microsoft, MIT).
Original paths: assets/Balloon/3D/balloon_3d.png,
assets/Party popper/3D/party_popper_3d.png, assets/Coin/3D/coin_3d.png.
The original license is included alongside these files.

Temporary presentation logic: LuckyDemoStreak counts consecutive taps on a
single product, resets on another product or reopening the sheet, and triggers
at each group of five. The displayed 50 + 20 = 70 reward is decorative only.
It never credits a wallet. Existing real send requests remain unchanged.
Replace the demo streak/overlay invocation with confirmed backend reward events
before shipping this promotional reward to users.
