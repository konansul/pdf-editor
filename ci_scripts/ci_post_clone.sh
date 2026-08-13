#!/bin/sh

set -e

FLUTTER_CHANNEL="stable"
FLUTTER_HOME="$HOME/flutter"

echo "Installing Flutter ($FLUTTER_CHANNEL)"
git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_CHANNEL" "$FLUTTER_HOME"
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter precache --ios

echo "Installing Rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
export PATH="$HOME/.cargo/bin:$PATH"
rustup target add aarch64-apple-ios aarch64-apple-ios-sim

cd "$CI_PRIMARY_REPOSITORY_PATH"

if [ -n "$CI_BUILD_NUMBER" ]; then
  echo "Setting build number to $CI_BUILD_NUMBER"
  sed -i '' -E "s/^version: ([0-9]+\.[0-9]+\.[0-9]+)\+.*/version: \1+$CI_BUILD_NUMBER/" pubspec.yaml
  grep '^version:' pubspec.yaml
fi

echo "Resolving packages"
flutter pub get

echo "Installing pods"
cd "$CI_PRIMARY_REPOSITORY_PATH/ios"
pod install

echo "Done"
