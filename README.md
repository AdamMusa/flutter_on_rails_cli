# Flutter on Rails CLI

A Ruby CLI tool for managing Flutter applications with ease.

## Installation

1. Make sure you have Ruby installed
2. Install dependencies:
```bash
bundle install
```

## Usage

### Create a new Flutter app
```bash
./bin/flutter_on_rails create
```
This will:
- Create a new Flutter application
- Optionally add dependencies
- Optionally configure splash screen

### Build Flutter app
```bash
./bin/flutter_on_rails build
```
This will:
- Let you choose the platform (android/ios/web/windows/macos/linux)
- Let you choose build type (debug/release)
- Build the application for the selected platform

## Features

- Colorful CLI interface
- Interactive prompts
- Splash screen configuration
- Dependency management
- Multi-platform build support
