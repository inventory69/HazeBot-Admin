#!/usr/bin/env bash
#
# Generates Android adaptive launcher icons from a source PNG image using ImageMagick
#

set -e

SOURCE_IMAGE="app_icon_source.png"
ANDROID_RES="android/app/src/main/res"
BACKGROUND_COLOR="#1a1a2e"  # Dark background matching the icon

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "============================================================"
echo "🤖 Android Adaptive Launcher Icon Generator"
echo "============================================================"

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo -e "${RED}❌ Error: Source image '$SOURCE_IMAGE' not found!${NC}"
    echo ""
    echo "Please save the ghost icon as 'app_icon_source.png' in this directory:"
    echo "  $(pwd)"
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}❌ Error: ImageMagick is not installed!${NC}"
    echo "Install it with: sudo apt-get install imagemagick"
    exit 1
fi

echo -e "${BLUE}📸 Loading source image: $SOURCE_IMAGE${NC}"
SIZE=$(identify -format "%wx%h" "$SOURCE_IMAGE")
echo "   Original size: $SIZE"

echo ""
echo -e "${CYAN}🎨 Generating Android Adaptive Icons (round masks)...${NC}"

# Adaptive icon sizes (foreground layer needs 108dp, safe zone is 66dp)
declare -A SIZES=(
    ["mipmap-mdpi"]=108
    ["mipmap-hdpi"]=162
    ["mipmap-xhdpi"]=216
    ["mipmap-xxhdpi"]=324
    ["mipmap-xxxhdpi"]=432
)

# Generate foreground and background layers
for folder in "${!SIZES[@]}"; do
    size=${SIZES[$folder]}
    target_dir="$ANDROID_RES/$folder"
    mkdir -p "$target_dir"
    
    # Foreground layer (the ghost icon, slightly padded for safe zone)
    foreground_path="$target_dir/ic_launcher_foreground.png"
    
    # Scale down to 70% to fit in safe zone (66dp / 108dp ≈ 0.7)
    safe_size=$(( size * 70 / 100 ))
    
    convert "$SOURCE_IMAGE" \
        -resize "${safe_size}x${safe_size}" \
        -gravity center \
        -background none \
        -extent "${size}x${size}" \
        "$foreground_path"
    
    # Background layer (solid color)
    background_path="$target_dir/ic_launcher_background.png"
    convert -size "${size}x${size}" \
        "xc:${BACKGROUND_COLOR}" \
        "$background_path"
    
    echo -e "   ${GREEN}✅ $folder/ic_launcher_foreground.png (${size}x${size})${NC}"
    echo -e "   ${GREEN}✅ $folder/ic_launcher_background.png (${size}x${size})${NC}"
done

echo ""
echo -e "${CYAN}📱 Creating adaptive icon XML descriptors...${NC}"

# Create mipmap-anydpi-v26 folder for XML descriptors
ANYDPI_DIR="$ANDROID_RES/mipmap-anydpi-v26"
mkdir -p "$ANYDPI_DIR"

# Create ic_launcher.xml (adaptive icon descriptor)
cat > "$ANYDPI_DIR/ic_launcher.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
EOF

echo -e "   ${GREEN}✅ mipmap-anydpi-v26/ic_launcher.xml${NC}"

# Optional: Create round icon variant (uses same resources)
cat > "$ANYDPI_DIR/ic_launcher_round.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
EOF

echo -e "   ${GREEN}✅ mipmap-anydpi-v26/ic_launcher_round.xml${NC}"

echo ""
echo -e "${GREEN}✨ Android Adaptive Icons generated successfully!${NC}"
echo ""
echo -e "${CYAN}ℹ️  About Adaptive Icons:${NC}"
echo "   • Foreground: Ghost icon (70% size for safe zone)"
echo "   • Background: Dark color ($BACKGROUND_COLOR)"
echo "   • Android will apply round, squircle, or square mask automatically"
echo "   • Supports Android 8.0 (API 26) and above"
echo ""
echo -e "${YELLOW}📱 Next steps:${NC}"
echo "   1. Icons saved in android/app/src/main/res/mipmap-*/"
echo "   2. AndroidManifest.xml already configured correctly"
echo "   3. Build the app: flutter build apk"
echo ""
