# run this command to build SwiftyAnimTool.xcframework by yourself.
#!/bin/sh
set -eu

rm -rf animtool
git clone https://github.com/dinghaoz/animtool.git

cat > animtool/xcode/build-animtool.sh <<'EOF'
#!/bin/sh
set -eu

echo "${TARGET_BUILD_DIR}"
echo "EFFECTIVE_PLATFORM_NAME ${EFFECTIVE_PLATFORM_NAME}."

PLATFORM=OS64
if [ "${EFFECTIVE_PLATFORM_NAME:-}" = "-iphonesimulator" ]; then
  case "${ARCHS:-}" in
    *arm64*) PLATFORM=SIMULATORARM64 ;;
    *) PLATFORM=SIMULATOR64 ;;
  esac
fi

PATH=/usr/local/bin/:/opt/homebrew/bin/:$PATH
echo "$PATH"

if ! command -v cmake >/dev/null 2>&1; then
  echo "Error: cmake is not installed. Use \`brew install cmake\` to install." >&2
  exit 1
fi

CMAKE_BIN="$(command -v cmake)"
CPM_CACHE_DIR="${PROJECT_DIR}/../.cpm-source-cache"
mkdir -p "$CPM_CACHE_DIR"
export CPM_SOURCE_CACHE="$CPM_CACHE_DIR"

mkdir -p "${TARGET_BUILD_DIR}/cmake" "${TARGET_BUILD_DIR}/cmake-products"

"$CMAKE_BIN" \
  -DBUILD_ANIMTOOL_EXECUTABLE=OFF \
  -DCPM_SOURCE_CACHE="${CPM_SOURCE_CACHE}" \
  -S "${PROJECT_DIR}/.." \
  -B "${TARGET_BUILD_DIR}/cmake" \
  -GXcode \
  -DCMAKE_TOOLCHAIN_FILE="${PROJECT_DIR}/../cmake/ios.toolchain.cmake" \
  -DPLATFORM="${PLATFORM}" \
  -DDEPLOYMENT_TARGET=12.0 \
  -DENABLE_BITCODE=FALSE

"$CMAKE_BIN" --build "${TARGET_BUILD_DIR}/cmake" --config "${CONFIGURATION}"

for i in "" "/_deps/webp-build" "/_deps/jpeg-build" "/_deps/png-build"; do
  LIB_PATH="${TARGET_BUILD_DIR}/cmake${i}/${CONFIGURATION}${EFFECTIVE_PLATFORM_NAME}"
  echo "$LIB_PATH"
  if [ ! -d "$LIB_PATH" ]; then
    echo "Missing output directory: $LIB_PATH" >&2
    continue
  fi

  found_artifact=0
  for FILE_PATH in "$LIB_PATH"/*; do
    if [ ! -e "$FILE_PATH" ]; then
      continue
    fi
    found_artifact=1
    FILE_NAME="$(basename "$FILE_PATH")"
    rm -f "${TARGET_BUILD_DIR}/cmake-products/$FILE_NAME"
    ln -s "$FILE_PATH" "${TARGET_BUILD_DIR}/cmake-products/$FILE_NAME"
  done

  if [ "$found_artifact" -eq 0 ]; then
    echo "No build artifacts in $LIB_PATH" >&2
  fi
done

for lib in \
  libwebpdecoder.a \
  libanimtoolcore.a \
  libwebpdemux.a \
  libwebp_imageio.a \
  libgiflib.a \
  libwebpmux.a \
  libwebp.a \
  libjpeg.a \
  libpng.a \
  libsharpyuv.a; do
  if [ ! -e "${TARGET_BUILD_DIR}/cmake-products/${lib}" ]; then
    echo "Missing required library: ${TARGET_BUILD_DIR}/cmake-products/${lib}" >&2
    echo "CMake dependency build did not finish correctly; stop before framework link." >&2
    exit 1
  fi
done
EOF
chmod +x animtool/xcode/build-animtool.sh

cd animtool/xcode

xcodebuild -scheme SwiftyAnimTool -derivedDataPath derived_data_device -destination 'generic/platform=iOS' BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild -scheme SwiftyAnimTool -derivedDataPath derived_data_sim_x86_64 -destination 'generic/platform=iOS Simulator' ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild -scheme SwiftyAnimTool -derivedDataPath derived_data_sim_arm64 -destination 'generic/platform=iOS Simulator' ARCHS=arm64 ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

SIM_ARM64=derived_data_sim_arm64/Build/Products/Debug-iphonesimulator/SwiftyAnimTool.framework
SIM_X86_64=derived_data_sim_x86_64/Build/Products/Debug-iphonesimulator/SwiftyAnimTool.framework
SIM_FAT=derived_data_sim_fat/SwiftyAnimTool.framework
DEVICE=derived_data_device/Build/Products/Debug-iphoneos/SwiftyAnimTool.framework

mkdir -p derived_data_sim_fat
cp -R "$SIM_ARM64" "$SIM_FAT"
lipo -create "$SIM_X86_64/SwiftyAnimTool" "$SIM_ARM64/SwiftyAnimTool" -output "$SIM_FAT/SwiftyAnimTool"
ditto "$SIM_X86_64/Modules/SwiftyAnimTool.swiftmodule" "$SIM_FAT/Modules/SwiftyAnimTool.swiftmodule"

mkdir -p derived_data/Build/Products
xcodebuild -create-xcframework \
  -framework "$SIM_FAT" \
  -framework "$DEVICE" \
  -output derived_data/Build/Products/SwiftyAnimTool.xcframework

cd ../..
mkdir -p SwiftyAnimTool
rm -rf SwiftyAnimTool/SwiftyAnimTool.xcframework
cp -R animtool/xcode/derived_data/Build/Products/SwiftyAnimTool.xcframework SwiftyAnimTool/SwiftyAnimTool.xcframework
