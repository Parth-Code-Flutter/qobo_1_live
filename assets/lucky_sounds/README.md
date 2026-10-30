# Lucky gift tunes

Pixabay Content License (free for commercial use, no attribution required):

- `magic_spell_02.mp3` — crowns / royal gifts. https://pixabay.com/sound-effects/film-special-effects-magic-spell-02-250240/
- `magical_whoosh.mp3` — hookah / premium. https://pixabay.com/sound-effects/film-special-effects-magical-whoosh-355988/
- `bonus_earned.mp3` — blue lucky box. https://pixabay.com/sound-effects/film-special-effects-bonus-earned-142268/
- `treasure_success.mp3` — lucky chest. https://pixabay.com/sound-effects/film-special-effects-short-success-sound-glockenspiel-treasure-video-game-6346/

Selecting a lucky gift loops its tune until that send settles. Other gifts
are not affected. Names that do not match a gift still get a tune from the
catalog position, so every lucky item has a sound. Closing the sheet or
leaving the room stops playback. The player does not change audio-session
configuration or request audio focus.

Older Kenney interface blips remain in this folder (see LICENSE.txt) and are
not used by the lucky sheet.

In active rooms playback uses Zego audio effects with publish=false. Bundled
files are copied to the application temporary directory for native playback.
A just_audio fallback is retained when the room effect player is unavailable.
