# Audio Assets Setup

## Required Audio File

You need to add a **tick.mp3** file to this directory for the callback notification feature.

### Where to Get Tick Sound:

1. **Free Sound Libraries:**
   - [Freesound.org](https://freesound.org/) - Search for "clock tick" or "metronome"
   - [Mixkit](https://mixkit.co/free-sound-effects/clock/) - Free clock sounds
   - [Zapsplat](https://www.zapsplat.com/) - Free sound effects

2. **Recommended Search Terms:**
   - "clock tick"
   - "metronome tick"
   - "clock ticking"
   - "tick tock"

3. **File Requirements:**
   - Format: MP3
   - Duration: 0.5 - 1 second
   - Volume: Medium (will be played at 30% volume)
   - File name: **tick.mp3** (exactly)

### Quick Setup:

1. Download a tick sound from one of the sources above
2. Convert to MP3 if needed
3. Rename to `tick.mp3`
4. Place in this directory (`assets/sounds/`)
5. Run `flutter pub get` to refresh assets
6. Rebuild the app

### Alternative (No Sound):

If you don't want the tick sound, you can comment out these lines in `lib/widgets/callback_notification_overlay.dart`:

```dart
// Comment out this line in _checkForUpcomingCallback():
// _startTickSound();

// And this line in dispose():
// _stopTickSound();
```

The notification will still work perfectly without sound.
