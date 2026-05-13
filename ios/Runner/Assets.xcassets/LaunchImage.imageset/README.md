# MuseAI iOS Launch Image Assets

This folder contains the image set used by the iOS launch screen for the Flutter app.

MuseAI itself is documented at the repository root in `README.md`. The launch images here are only the native iOS startup assets shown before Flutter finishes rendering the branded splash/onboarding flow.

## Files

- `LaunchImage.png`
- `LaunchImage@2x.png`
- `LaunchImage@3x.png`
- `Contents.json`

To update the launch artwork, replace the PNG files with matching 1x, 2x, and 3x assets or edit them through Xcode:

```bash
open ios/Runner.xcworkspace
```

Then select `Runner/Assets.xcassets/LaunchImage.imageset`.
