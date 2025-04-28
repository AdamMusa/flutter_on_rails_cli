# Flutter on Rails CLI

Flutter on Rails CLI is a powerful tool that helps you create and manage Flutter applications with Rails backend integration.

## Prerequisites

Before using Flutter on Rails CLI, make sure you have:

1. **Flutter SDK** installed:

   - [Install Flutter](https://docs.flutter.dev/get-started/install) for your operating system
   - After installation, verify it's working by running:
     ```bash
     flutter doctor
     ```
   - Make sure to follow any additional setup instructions provided by `flutter doctor`

2. **Ruby** installed on your system

## Installation

```bash
gem install flutter_on_rails
```

## Usage

Create a new Flutter on Rails application:

```bash
frails create my_app
# or
flutter_on_rails create my_app
```

Run the application:

```bash
frails run
# or
flutter_on_rails run
```

Build the application for a specific platform:

```bash
frails build [platform]
# or
flutter_on_rails build [platform]
```

Available platforms:

- android
- ios
- windows
- macos
- linux

## Commands

- `frails create` or `flutter_on_rails create` - Create a new Flutter on Rails application
- `frails run` or `flutter_on_rails run` - Run the Flutter app in debug mode
- `frails build` or `flutter_on_rails build` - Build Flutter app for different platforms
- `frails apply` or `flutter_on_rails apply` - Apply configurations (splash_screen or icon_launcher)
- `frails install` or `flutter_on_rails install` - Install dependencies

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Features

- Colorful CLI interface
- Interactive prompts
- Splash screen configuration
- Dependency management
- Multi-platform build support
