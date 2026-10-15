#!/bin/bash
set -e

echo "=== Installing Flutter SDK ==="
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"

echo "=== Flutter Doctor ==="
flutter doctor

echo "=== Building Flutter Web ==="
flutter config --enable-web
flutter pub get
flutter build web --release

echo "=== Build Complete ==="
