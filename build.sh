#!/bin/bash
set -e

echo "Building Opal Terminal..."

cargo build -p opal-ffi --lib --release
# Generate Swift bindings from the library (proc-macro mode)
cargo run -p opal-ffi --bin uniffi-bindgen -- generate --library --language swift --out-dir Opal/Sources/OpalCore target/release/libopal_ffi.dylib 2>/dev/null || echo "Note: FFI bindings generation may require manual step"
# Keep Copal systemLibrary headers synchronized with latest generated UniFFI bridge.
cp Opal/Sources/OpalCore/opal_ffiFFI.h Opal/Sources/Copal/opal_ffiFFI.h
cp Opal/Sources/OpalCore/opal_ffiFFI.modulemap Opal/Sources/Copal/opal_ffiFFI.modulemap

cd Opal
swift build -c release
cd ..

echo "Creating app bundle..."

mkdir -p Opal.app/Contents/MacOS
mkdir -p Opal.app/Contents/Resources
mkdir -p Opal.app/Contents/Frameworks
mkdir -p Opal.app/Contents/Resources/seashell

cp Opal/.build/release/Opal Opal.app/Contents/MacOS/
# Copy icon files
cp Opal/Resources/Opal.icns Opal.app/Contents/Resources/
cp target/release/libopal_ffi.dylib Opal.app/Contents/Frameworks/

# Bundle Seashell runtime if available (parallel repo at ../seashell).
if [ -x ../seashell/sea ]; then
  cp ../seashell/sea Opal.app/Contents/Resources/seashell/sea
  chmod +x Opal.app/Contents/Resources/seashell/sea
  if [ -d ../seashell/lib ]; then
    cp -R ../seashell/lib Opal.app/Contents/Resources/seashell/
  fi
  if [ -f ../seashell/VERSION ]; then
    cp ../seashell/VERSION Opal.app/Contents/Resources/seashell/VERSION
    SEASHELL_VERSION="$(tr -d ' \n' < ../seashell/VERSION)"
  else
    SEASHELL_VERSION="unknown"
  fi
  printf 'version=%s\n' "${SEASHELL_VERSION}" > Opal.app/Contents/Resources/SeashellBuild.txt
else
  printf 'version=unavailable\n' > Opal.app/Contents/Resources/SeashellBuild.txt
fi

chmod +x Opal.app/Contents/MacOS/Opal
chmod +x Opal.app/Contents/Frameworks/libopal_ffi.dylib

cat > Opal.app/Contents/Info.plist << 'ENDINFO'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleExecutable</key>
    <string>Opal</string>
    <key>CFBundleIconFile</key>
    <string>Opal.icns</string>
    <key>CFBundleIdentifier</key>
    <string>com.opal.terminal</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Opal</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.3</string>
    <key>CFBundleVersion</key>
    <string>113</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
ENDINFO

install_name_tool -id "@rpath/libopal_ffi.dylib" Opal.app/Contents/Frameworks/libopal_ffi.dylib
install_name_tool -change "/Users/june/projects/Opal/target/release/deps/libopal_ffi.dylib" "@rpath/libopal_ffi.dylib" Opal.app/Contents/MacOS/Opal 2>/dev/null || true
install_name_tool -add_rpath "@executable_path/../Frameworks" Opal.app/Contents/MacOS/Opal 2>/dev/null || true

codesign --force --deep --sign - Opal.app

echo "Build complete!"
echo ""
echo "To install: cp -R Opal.app /Applications/"
echo "To run: /Applications/Opal.app/Contents/MacOS/Opal"
