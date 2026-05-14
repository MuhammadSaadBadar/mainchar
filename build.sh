#!/bin/bash

# 1. Clone Flutter stable branch if not already present
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Setup and build
echo "Setting up Flutter..."
flutter config --no-analytics
flutter config --enable-web

echo "Getting dependencies..."
flutter pub get

echo "Building web project..."
flutter build web --release --wasm --base-href / \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo "Build complete."
