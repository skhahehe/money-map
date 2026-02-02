# Money Map

Money Map is a powerful, privacy-first finance tracking application designed for individuals who want to take control of their financial destiny without compromising their data security.

## 📥 Download

You can download the latest pre-compiled binaries for Android, Windows, and macOS directly from our **[Releases Page](https://github.com/skhahehe/money-map/releases)**.


## Features

### Comprehensive Expense Tracking
- **Transaction Management**: Easily record income and expenses with precise amounts and dates.
- **Smart Categorization**: Organize your spending into customizable categories like Food, Travel, Utilities, and more.
- **Instant Overview**: Get a clear snapshot of your financial health directly from the home screen.

### Intuitive Navigation
- **Zonal Swipe System**: Optimized navigation with smooth, follow-finger gestures restricted to the bottom of the screen.
- **Context-Aware Gestures**: Main page navigation is localized to the bottom zone, allowing nested sub-tabs (like in Categories) to function independently without interference.
- **High Performance**: Built for speed with optimized animation curves and low-latency transitions.

### Powerful Analytics
- **Visual Reports**: Understand your spending patterns with intuitive charts and graphs.
- **Spending Trends**: Track how your expenses change over time to identify saving opportunities.
- **Detailed Breakdowns**: View transaction history with advanced filtering and search capabilities.

### Professional Exporting
- **PDF Reports**: Generate and export professional PDF statements of your transactions for records or sharing.

### Secure and Private
- **Local Storage**: Your sensitive financial data stays on your device, ensuring maximum privacy.
- **Offline Access**: Manage your money anytime, anywhere, without needing an internet connection.

### Multi-Platform and Architecture Support
Built with Flutter, providing a seamless experience across:
- **Android**: Supports all major architectures (armv7, arm64-v8a, x86_64).
- **iOS**: iPhone and iPad support.
- **Desktop**: Windows, macOS, and Linux.
- **Web**: Modern browsers.

## Project Structure

```
lib/
├── main.dart           # Application entry point
├── models/             # Data models
├── providers/          # State management
├── screens/            # UI screens
├── services/           # Business logic and APIs
└── widgets/            # Reusable UI components
```

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

*   **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
*   **IDE**: VS Code, Android Studio, or IntelliJ IDEA with Flutter/Dart plugins.

### Installation & Running

1.  **Clone the repository**
    ```bash
    git clone https://github.com/skhahehe/money-map.git
    cd money-map
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the application**
    *   **Desktop (Windows/macOS/Linux)**:
        ```bash
        flutter run -d windows  # or macos / linux
        ```
    *   **Mobile (Android/iOS)**:
        Connect your device or start an emulator/simulator, then:
        ```bash
        flutter run
        ```
    *   **Web**:
        ```bash
        flutter run -d chrome
        ```


## Supported Platforms

- Android
- iOS
- Web
- Windows
- Linux
- macOS

## Contributing

Contributions are welcome. Please follow Flutter best practices and submit pull requests for review.

## License

This project is open source and available under the MIT License.