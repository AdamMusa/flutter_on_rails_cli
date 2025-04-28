require 'thor'
require 'colorize'
require 'tty-prompt'
require 'tty-spinner'
require 'yaml'

class FlutterCLI < Thor
  # Set package name for both 'flutter_on_rails' and 'frails'
  package_name "Flutter on Rails CLI"

  # Define exit_on_failure? to maintain Thor's exit with status 0 on errors
  def self.exit_on_failure?
    false
  end

  # Commands
  map %w[n new] => :create
  map "r" => :run_app
  map "b" => :build
  map "a" => :apply
  map "i" => :install

  desc "apply", "Apply configurations (TYPE=splash_screen or icon_launcher)"
  def apply(type)
    case type
    when "splash_screen"
      spinner = TTY::Spinner.new("[:spinner] Generating splash screen ...", format: :dots)
      spinner.auto_spin
      system("dart run flutter_native_splash:create > /dev/null 2>&1")
      spinner.success("Splash screen generated!".colorize(:green))
    when "icon_launcher"
      spinner = TTY::Spinner.new("[:spinner] Generating launcher icons ...", format: :dots)
      spinner.auto_spin
      system("dart run flutter_launcher_icons > /dev/null 2>&1")
      spinner.success("Launcher icons generated!".colorize(:green))
    else
      puts "Invalid type. Use 'splash_screen' or 'icon_launcher'".colorize(:red)
    end
  end

  desc "run", "Run the Flutter app in debug mode"
  def run_app
    prompt = TTY::Prompt.new
    # Show spinner while getting devices
    spinner = TTY::Spinner.new("[:spinner] Detecting devices...", format: :dots)
    spinner.auto_spin

    # Get list of available devices using --machine flag for faster parsing
    devices_output = `flutter devices --machine 2>/dev/null`
    devices = []

    begin
      require 'json'
      JSON.parse(devices_output).each do |device|
        devices << {
          name: device['name'],
          id: device['id'],
          platform: device['targetPlatform'] || device['platformType']
        }
      end
    rescue JSON::ParserError
      # Fallback to regular output parsing if JSON fails
      devices_output = `flutter devices`
      devices_output.each_line do |line|
        next if line.strip.empty? || line.include?("Found") || line.include?("No devices")
        if match = line.match(/^([^•]+)•([^•]+)•(.+)$/)
          name, id, platform = match.captures.map(&:strip)
          devices << {
            name: name,
            id: id,
            platform: platform
          }
        end
      end
    end

    spinner.stop

    if devices.empty?
      puts "No devices found. Please connect a device or start a simulator.".colorize(:red)
      return
    end

    # No need to show device count, just show the selection prompt

    # Let user choose device
    choices = devices.map do |d|
      # Get device type from platform and name
      device_type = case
        when d[:platform].downcase.include?('ios') then :ios
        when d[:platform].downcase.include?('android') then :android
        when d[:platform].downcase.include?('chrome') || d[:platform].downcase.include?('web') then :web
        when d[:platform].downcase.include?('darwin') || d[:name].downcase.include?('mac') then :macos
        when d[:platform].downcase.include?('windows') then :windows
        when d[:platform].downcase.include?('linux') then :linux
        else :unknown
      end

      # Determine device type icon and platform color
      icon, platform_color = case device_type
        when :ios
          if d[:name].downcase.include?('simulator')
            ["📱", :light_blue]  # iOS simulator
          else
            ["📲", :light_blue]  # Physical iOS device
          end
        when :android
          if d[:name].downcase.include?('emulator')
            ["📱", :green]      # Android emulator
          else
            ["🤖", :green]      # Physical Android device
          end
        when :macos
          if d[:name].downcase.include?('ipad')
            ["💻", :magenta]    # Mac for iPad
          else
            ["🖥", :magenta]    # macOS desktop
          end
        when :windows
          ["🪟", :blue]        # Windows desktop
        when :linux
          ["🐧", :red]         # Linux desktop
        when :web
          if d[:platform].downcase.include?('chrome')
            ["🌐", :yellow]     # Chrome browser
          else
            ["🌎", :yellow]     # Other web platform
          end
        else
          ["💻", :white]      # Unknown platform
      end

      # Clean up and format the device name
      device_name = case device_type
        when :macos
          if d[:name].downcase.include?('ipad')
            'Mac (iPad)'
          else
            ' macOS'
          end
        else
          d[:name].gsub(/\s+\([^)]*\)/, '') # Remove parenthetical descriptions only
      end

      # Format the device info with consistent spacing
      icon_part = "#{icon}".ljust(6)     # Icon with padding
      name_part = device_name.ljust(22)   # Name with padding
      platform_part = d[:platform].colorize(platform_color)  # Platform name
      
      {
        name: "#{icon_part}#{name_part}#{platform_part}",  # Using only padding for alignment
        value: d[:id],
        disabled: d[:platform].include?("unavailable") ? "Device unavailable" : false
      }
    end

    begin
      # Configure prompt to be more stable
      prompt.on(:keypress) {}
      device = prompt.select(
        "Select a device to run on:".colorize(:cyan),
        choices,
        cycle: true,
        per_page: devices.length,
        interrupt: :exit  # Exit cleanly on Ctrl+C during selection
      )
      
      spinner = TTY::Spinner.new("[:spinner] Starting app on selected device ...", format: :dots)
      spinner.auto_spin

      # Handle Ctrl+C gracefully for the Flutter process
      begin
        pid = spawn("flutter run -d #{device}")
        Process.wait(pid)
      rescue Interrupt
        # Stop the spinner and clear the line
        spinner.stop
        print "\n" # Move to new line
        puts "Stopping Flutter app...".colorize(:yellow)
        # Kill the Flutter process group
        Process.kill('-INT', pid) rescue nil
        Process.wait(pid) rescue nil
        exit(0)
      end

      spinner.success("App started in debug mode!".colorize(:green))
    rescue TTY::Reader::InputInterrupt
      # Handle Ctrl+C during device selection
      puts "\n\nInterrupted.".colorize(:yellow)
      exit(0)
    rescue StandardError => e
      # Handle any other errors gracefully
      puts "\n\nError: #{e.message}".colorize(:red)
      exit(1)
    end
  end

  desc "build [PLATFORM]", "Build Flutter on Rails app for different platforms"
  def build(platform = nil)
    prompt = TTY::Prompt.new
    
    platform ||= prompt.select("Choose platform to build for:".colorize(:cyan), [
      "android",
      "ios",
      "windows",
      "macos",
      "linux"
    ])
    
    spinner = TTY::Spinner.new("[:spinner] Building #{platform} release ...", format: :dots)
    spinner.auto_spin
    system("flutter build #{platform} --release")
    spinner.success("#{platform.capitalize} release build completed!".colorize(:green))
  end

  desc "create", "Create a new Flutter on Rails application"
  def create
    prompt = TTY::Prompt.new
    spinner = TTY::Spinner.new("[:spinner] Creating Flutter on Rails app ...", format: :dots)
    
    app_name = prompt.ask("What's your Flutter on Rails app name?".colorize(:cyan))
    return puts "App name is required!".colorize(:red) unless app_name
    
    spinner.auto_spin
    system("flutter create #{app_name} > /dev/null 2>&1")
    spinner.success("Flutter on Rails app created!".colorize(:green))
    
    # Add dependencies first
    add_dependencies(app_name)
    
    # Replace main.dart content
    replace_main_dart(app_name)
    
    # Add configurations before installing dependencies
    configure_splash_screen(app_name)
    configure_launcher_icons(app_name)
    
    # Clean up and normalize pubspec.yaml
    normalize_pubspec_yaml(app_name)
    
    # Install dependencies after configurations are added
    spinner = TTY::Spinner.new("[:spinner] Installing dependencies ...", format: :dots)
    spinner.auto_spin
    system("cd #{app_name} && flutter pub get > /dev/null 2>&1")
    spinner.success("Dependencies installed!".colorize(:green))
    
    # Copy assets folder from CLI to new project
    spinner = TTY::Spinner.new("[:spinner] Copying assets folder ...", format: :dots)
    spinner.auto_spin
    cli_root = File.expand_path(File.dirname(__FILE__) + "/../")
    system("cp -r #{cli_root}/assets #{app_name}/")
    spinner.success("Assets folder copied!".colorize(:green))
    
    puts "\n✨ Your Flutter on Rails app is ready! ✨".colorize(:green)
    puts "\nNext steps:".colorize(:yellow)
    puts "1. cd #{app_name}".colorize(:cyan)
    puts "2. frails run".colorize(:cyan)
    
    puts "\nNote:".colorize(:yellow)
    puts "- To update splash screen: frails apply splash_screen".colorize(:cyan)
    puts "- To update app icons: frails apply icon_launcher".colorize(:cyan)
  end
  
  private

  def replace_main_dart(app_name)
    main_dart_content = <<~DART
      import 'package:flutter/material.dart';
      import 'package:flutter_on_rails/flutter_on_rails.dart';

      void main() async {
        WidgetsFlutterBinding.ensureInitialized();
        await init();
        runApp(MaterialApp(home: MainScreen()));
      }
    DART
    
    File.write("#{app_name}/lib/main.dart", main_dart_content)
    system("rm -rf #{app_name}/test")
  end

  def normalize_pubspec_yaml(app_name)
    spinner = TTY::Spinner.new("[:spinner] Normalizing pubspec.yaml ...", format: :dots)
    spinner.auto_spin

    pubspec_path = "#{app_name}/pubspec.yaml"
    temp_config_path = "#{app_name}/.temp_config.yaml"

    # Write our configurations to a temporary file
    config = {}
    config['flutter_native_splash'] = @splash_screen_config if @splash_screen_config
    config['flutter_launcher_icons'] = @launcher_icons_config if @launcher_icons_config
    
    # Only write and append if we have configurations to add
    unless config.empty?
      File.write(temp_config_path, config.to_yaml.sub(/^---\n/, ''))
      system("cat #{temp_config_path} >> #{pubspec_path} && rm #{temp_config_path}")
    end
    
    spinner.success("pubspec.yaml normalized".colorize(:green))
  end

  
  def add_dependencies(app_name)
    spinner = TTY::Spinner.new("[:spinner] Adding dependencies ...", format: :dots)
    
    # Silently add Flutter on Rails
    spinner.auto_spin
    system("cd #{app_name} && flutter pub add flutter_on_rails > /dev/null 2>&1")
    spinner.success("Added Flutter on Rails package".colorize(:green))

    # Silently add flutter_launcher_icons as dev dependency
    spinner.auto_spin
    system("cd #{app_name} && flutter pub add -d flutter_launcher_icons:^0.14.3 > /dev/null 2>&1")
    spinner.success("Added flutter_launcher_icons package".colorize(:green))

    # Add flutter_native_splash dependency
    spinner.auto_spin
    system("cd #{app_name} && flutter pub add flutter_native_splash > /dev/null 2>&1")
    spinner.success("Added flutter_native_splash".colorize(:green))
  end
  
  def configure_splash_screen(app_name)
    spinner = TTY::Spinner.new("[:spinner] Configuring splash screen ...", format: :dots)
    spinner.auto_spin
    
    # Read and parse existing pubspec.yaml
    pubspec_path = "#{app_name}/pubspec.yaml"
    yaml_data = YAML.load_file(pubspec_path) || {}
    
    # Check if configuration already exists
    return if yaml_data['flutter_native_splash']
    
    # Create assets directory structure
    system("cd #{app_name} && mkdir -p assets")
    
    # Add splash screen configuration
    yaml_data['flutter_native_splash'] = {
      'color' => '#42a5f5',
      'image' => 'assets/splash.png',
      'branding' => 'assets/branding.png',
      'color_dark' => '#042a49',
      'image_dark' => 'assets/splash.png',
      'branding_dark' => 'assets/splash.png',
      'android_12' => {
        'image' => 'assets/splash.png',
        'icon_background_color' => '#42a5f5',
        'image_dark' => 'assets/splash.png',
        'icon_background_color_dark' => '#042a49'
      },
      'android' => true,
      'ios' => true,
      'web' => false
    }
    
    # Add uses-material-design if not present
    yaml_data['flutter'] ||= {}
    yaml_data['flutter']['uses-material-design'] = true
    
    # Save the configuration to be applied during normalization
    @splash_screen_config = yaml_data['flutter_native_splash']
    spinner.success("Splash screen configuration added!".colorize(:green))
  end

  def configure_launcher_icons(app_name)
    spinner = TTY::Spinner.new("[:spinner] Configuring launcher icons ...", format: :dots)
    spinner.auto_spin
    
    # Read and parse existing pubspec.yaml
    pubspec_path = "#{app_name}/pubspec.yaml"
    yaml_data = YAML.load_file(pubspec_path) || {}
    
    # Check if configuration already exists
    return if yaml_data['flutter_launcher_icons']
    
    # Create assets directory structure
    system("cd #{app_name} && mkdir -p assets/icon")
    
    # Add launcher icons configuration
    yaml_data['flutter_launcher_icons'] = {
      'android' => 'launcher_icon',
      'ios' => true,
      'image_path' => 'assets/icon/logo.png',
      'min_sdk_android' => 21,
      'web' => {
        'generate' => true,
        'image_path' => 'assets/icon/logo.png',
        'background_color' => '#ffffff',
        'theme_color' => '#42a5f5'
      },
      'windows' => {
        'generate' => true,
        'image_path' => 'assets/icon/logo.png',
        'icon_size' => 48
      },
      'macos' => {
        'generate' => true,
        'image_path' => 'assets/icon/logo.png'
      }
    }
    
    # Save the configuration to be applied during normalization
    @launcher_icons_config = yaml_data['flutter_launcher_icons']
    spinner.success("Launcher icons configuration added!".colorize(:green))
  end

  desc "install", "Install dependencies (flutter pub get)"
  def install
    spinner = TTY::Spinner.new("[:spinner] Installing dependencies ...", format: :dots)
    spinner.auto_spin
    system("flutter pub get > /dev/null 2>&1")
    spinner.success("Dependencies installed!".colorize(:green))
  end
end

# Allow both 'flutter_on_rails' and 'frails' commands
FlutterCLI.start(ARGV)