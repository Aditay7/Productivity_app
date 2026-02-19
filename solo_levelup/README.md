# Solo Level Up 🎮

A Solo Leveling-inspired RPG gamification app for real-life activities. Transform your daily tasks into epic quests, earn XP, level up, and unlock achievements!

## Features ✨

- **🎯 Quest System**: Create quests for real-life activities (gym, studying, work, etc.)
- **📊 5 Core Stats**: Strength, Intelligence, Discipline, Wealth, Charisma
- **⚡ XP & Leveling**: Earn XP from quests, level up your character
- **🔥 Streak System**: Maintain daily streaks for XP multipliers
- **🏆 Achievements**: Unlock 14 predefined achievements
- **💾 100% Offline**: All data stored locally in SQLite
- **🎨 Dark RPG Theme**: Beautiful dark fantasy UI with purple/gold accents

## Setup Instructions 🚀

### Prerequisites
- Flutter SDK 3.10.4 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone or navigate to the project directory**
   ```bash
   cd "/Users/aditay/Documents/Solo Leveling/solo_levelup"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

   Or for a specific device:
   ```bash
   flutter run -d chrome  # Web
   flutter run -d macos   # macOS
   flutter run -d <device-id>  # Mobile device
   ```

## How It Works 🎮

### The Loop
**Real-Life Action → Quest → XP Gain → Stat Increase → Level Up**

### XP Calculation
```
XP = timeMinutes × difficulty × streakMultiplier
```
- Difficulty: Easy (1.0×), Medium (2.0×), Hard (3.0×)
- Streak Multiplier: 1 + (currentStreak / 10)

Example: 30min coding quest (Medium) with 5-day streak
→ 30 × 2 × 1.5 = **90 XP**

### Level Calculation
```
level = floor(sqrt(totalXP / 100))
```
- 1,000 XP → Level 3
- 10,000 XP → Level 10
- 40,000 XP → Level 20

### Stats System
Each quest increases ONE stat:
- **💪 Strength**: Physical fitness (gym, running, diet)
- **🧠 Intelligence**: Mental growth (reading, studying, coding)
- **🎯 Discipline**: Consistency (meditation, wake time, habits)
- **💰 Wealth**: Productivity (deep work, projects, earning)
- **✨ Charisma**: Social skills (public speaking, networking)

## Usage Guide 📱

### Creating a Quest
1. Tap the **"New Quest"** FAB on Dashboard
2. Enter quest details:
   - Title (required)
   - Description (optional)
   - Stat Type (which attribute it improves)
   - Difficulty (Easy/Medium/Hard)
   - Time Investment (minutes)
3. See live XP preview
4. Tap **"Create Quest"**

### Completing a Quest
1. Find the quest in Dashboard or Quests tab
2. Tap the **checkmark icon**
3. Earn XP and increase your stat!
4. If you level up, see the celebration dialog

### Maintaining Streaks
- Complete at least one quest per day
- Consecutive days increase your streak
- Higher streaks = higher XP multipliers!
- Miss a day? Streak resets to 1

### Unlocking Achievements
Achievements unlock automatically when you:
- Complete your first quest
- Reach streak milestones (7, 30, 100 days)
- Earn XP milestones (1k, 10k, 100k)
- Reach stat milestones (100+ in any stat)
- Complete 50 quests
- Balance all stats above 50

## Project Structure 📁

```
lib/
├── main.dart                    # App entry point
├── app/                         # App configuration
│   ├── app.dart                # Main app widget
│   └── theme.dart              # Dark RPG theme
├── core/                        # Core utilities
│   ├── constants/              # App constants
│   ├── utils/                  # XP calculator, date utils
│   └── extensions/             # Context extensions
├── data/                        # Data layer
│   ├── database/               # SQLite setup
│   ├── models/                 # Data models
│   └── repositories/           # Data access
├── providers/                   # Riverpod state management
├── screens/                     # UI screens
│   ├── dashboard/              # Main dashboard
│   ├── quests/                 # Quest management
│   ├── stats/                  # Stats overview
│   └── achievements/           # Achievements
└── widgets/                     # Reusable widgets
```

## Tech Stack 🛠️

- **Flutter** 3.10.4+
- **Riverpod** 2.4.0 - State management
- **SQLite** (sqflite) - Local database
- **Material Design 3** - UI framework

## Key Features Implementation ⚙️

### Offline-First
- All data stored in local SQLite database
- No internet connection required
- Zero backend dependencies

### Clean Architecture
- Separation of concerns (data/domain/presentation)
- Repository pattern for data access
- Provider pattern for state management

### Gamification
- RPG-style progression system
- Achievement system with auto-unlock
- Streak mechanics for engagement
- Level-up celebrations

## Troubleshooting 🔧

### Database Issues
The database is automatically created on first launch. If you encounter issues:
```bash
# Clear app data (this will reset all progress!)
flutter clean
flutter pub get
flutter run
```

### Build Issues
```bash
# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter run
```

## Future Enhancements 💡

Potential features to add:
- [ ] Quest templates (pre-defined common quests)
- [ ] Recurring quests (daily/weekly)
- [ ] Data export/import (backup)
- [ ] Statistics charts and analytics
- [ ] Custom achievements
- [ ] Dark/Light theme toggle
- [ ] Quest scheduling and reminders
- [ ] Widget for quick quest logging

## License 📄

This is a personal project. Feel free to use and modify as needed.

## Credits 🙏

Inspired by the Solo Leveling manhwa/anime series.

---

**Built with ❤️ using Flutter**
