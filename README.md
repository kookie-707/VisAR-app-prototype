# VisAR Smart Helmet Companion App

A premium cross-platform mobile application (iOS and Android) for the AR Motorcycle Smart Helmet Visor project. Built with Flutter.

## Features

- **Home Dashboard**: Real-time helmet connection status with glowing animations, quick-glance ride data, and Start/Stop ride controls
- **HUD Customization**: Interactive visor preview with drag-and-drop HUD element positioning, brightness/transparency controls, and element toggles
- **Rider Profile & Analytics**: Comprehensive ride statistics, performance graphs, safety scores, and AI-powered riding insights

## Design

The app features a bold, minimal, and immersive design with:
- **Color Palette**: Black background, white typography, striking red accents
- **Typography**: Orbitron for headings (futuristic), Inter for body text
- **Animations**: Smooth, mechanical, and precise micro-animations
- **Aesthetics**: Racing dashboard meets tactical HUD system

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / Xcode (for building)
- A physical device or emulator

### Installation

1. **Install Flutter** (if not already installed):
   - Follow the official guide: https://docs.flutter.dev/get-started/install
   - Run `flutter doctor` to verify installation

2. **Get Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

### Project Structure

```
lib/
├── main.dart                 # App entry point & navigation
├── theme/
│   └── app_theme.dart        # Color palette, typography, theme
├── screens/
│   ├── home_screen.dart      # Main dashboard
│   ├── hud_customization_screen.dart  # HUD settings
│   └── profile_screen.dart   # Analytics & profile
├── widgets/
│   ├── connection_status_widget.dart  # Animated connection status
│   ├── racing_background.dart         # Background patterns
│   ├── circuit_background.dart        # Circuit line patterns
│   ├── stat_card.dart                 # Quick stat cards
│   ├── visor_preview.dart             # Interactive HUD preview
│   └── analytics_card.dart            # Analytics cards
├── providers/
│   └── app_state_provider.dart        # State management
└── models/
    └── hud_element.dart               # HUD element model
```

## Dependencies

- `provider`: State management
- `google_fonts`: Custom typography (Orbitron, Inter)
- `fl_chart`: Performance graphs and charts

## Features in Detail

### Home Screen
- Animated connection status ring (glows red when connected)
- Real-time speed and battery level display
- Start/Stop ride button with pulse animation
- System status overview

### HUD Customization
- Interactive visor preview mockup
- Drag-and-drop HUD element positioning
- Toggle individual HUD elements (speed, navigation, notifications, battery, alerts)
- Brightness and transparency sliders
- Visual feedback with red glow on selected elements

### Profile & Analytics
- Rider profile header with safety score
- Analytics cards: Total rides, distance, average/max speed, riding time
- Performance graph (weekly/monthly toggle)
- AI-powered riding style insights

## Development Notes

- The app uses Provider for state management
- All animations are smooth and performance-optimized
- The design follows a strict black/white/red color scheme
- Typography uses Orbitron for headings and Inter for body text

## Next Steps

To connect to actual hardware:
1. Add Bluetooth connectivity package (`flutter_bluetooth_serial` or similar)
2. Implement real-time data streaming from helmet
3. Add data persistence (SQLite/Hive)
4. Implement ride recording and analytics calculation

## License

This project is part of the VisAR Smart Helmet system.
