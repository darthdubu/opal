#!/bin/bash
set -e

echo "Building Opal Terminal..."

cargo build -p opal-ffi --lib --release
# Generate Swift bindings from the library (proc-macro mode)
cargo run -p opal-ffi --bin uniffi-bindgen -- generate --library --language swift --out-dir Opal/Sources/OpalCore target/release/libopal_ffi.dylib 2>/dev/null || echo "Note: FFI bindings generation may require manual step"

cd Opal
swift build -c release
cd ..

echo "Creating app bundle..."

mkdir -p Opal.app/Contents/MacOS
mkdir -p Opal.app/Contents/Resources
mkdir -p Opal.app/Contents/Frameworks

cp Opal/.build/release/Opal Opal.app/Contents/MacOS/
# Copy icon files
cp Opal/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png Opal.app/Contents/Resources/Opal.png
cp target/release/libopal_ffi.dylib Opal.app/Contents/Frameworks/
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
    <string>Opal</string>
    <key>CFBundleIconName</key>
    <string>Opal</string>
    <key>CFBundleIdentifier</key>
    <string>com.opal.terminal</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Opal</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
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
