# Lucky tap sounds
Seven short CC0 sounds by Kenney, downloaded from:
https://github.com/Calinou/kenney-interface-sounds/tree/master/addons/kenney_interface_sounds
Original collection: https://kenney.nl/assets/interface-sounds
See LICENSE.txt.

Stable A–G mapping: confirmation_001, confirmation_002, confirmation_003,
glass_001, glass_003, pluck_001, pluck_002. Other names use catalog position.
Sounds are local, one-shot, and replace the previous tap sound. Closing the
sheet or leaving/ending the room disposes playback and invalidates pending loads.
The player does not change audio-session configuration or request audio focus.

In active rooms playback uses Zego audio effects with publish=false. Bundled
WAVs are copied to the application temporary directory for native playback.
A just_audio fallback is retained when the room effect player is unavailable.
