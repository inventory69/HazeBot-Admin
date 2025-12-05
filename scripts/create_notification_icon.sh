#!/bin/bash

# Create monochrome notification icons from app icon
# Notification icons must be white/transparent for Android status bar

echo "🎨 Creating monochrome notification icons..."

# Source icon (use the largest one)
SOURCE_ICON="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

# Create drawable directories if they don't exist
mkdir -p android/app/src/main/res/drawable-mdpi
mkdir -p android/app/src/main/res/drawable-hdpi
mkdir -p android/app/src/main/res/drawable-xhdpi
mkdir -p android/app/src/main/res/drawable-xxhdpi
mkdir -p android/app/src/main/res/drawable-xxxhdpi

# Function to create monochrome icon
create_monochrome_icon() {
    local size=$1
    local output_dir=$2
    
    echo "  📱 Creating ${size}x${size} icon in ${output_dir}..."
    
    # Convert to monochrome: white on transparent background
    convert "$SOURCE_ICON" \
        -resize "${size}x${size}" \
        -colorspace Gray \
        -threshold 50% \
        -negate \
        -alpha set \
        -channel RGB -evaluate set 100% \
        +channel \
        "${output_dir}/ic_notification.png"
}

# Create icons for each density
create_monochrome_icon 24 "android/app/src/main/res/drawable-mdpi"
create_monochrome_icon 36 "android/app/src/main/res/drawable-hdpi"
create_monochrome_icon 48 "android/app/src/main/res/drawable-xhdpi"
create_monochrome_icon 72 "android/app/src/main/res/drawable-xxhdpi"
create_monochrome_icon 96 "android/app/src/main/res/drawable-xxxhdpi"

echo "✅ Monochrome notification icons created!"
echo "📋 Icons created in android/app/src/main/res/drawable-*/"
