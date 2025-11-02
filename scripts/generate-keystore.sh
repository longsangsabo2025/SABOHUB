#!/bin/bash

# SABOHUB - Generate Android Keystore Script
# This script generates a keystore file for signing Android release builds

echo "🔐 Generating Android Keystore for SABOHUB"
echo "==========================================="
echo ""

# Configuration
KEYSTORE_PATH="$HOME/upload-keystore.jks"
KEY_ALIAS="upload"
VALIDITY_DAYS=10000

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ Error: keytool not found!"
    echo "Please install Java JDK first."
    exit 1
fi

echo "📝 Please provide the following information:"
echo ""

# Generate keystore
keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -keyalg RSA \
    -keysize 2048 \
    -validity $VALIDITY_DAYS \
    -alias "$KEY_ALIAS"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore generated successfully!"
    echo "📁 Location: $KEYSTORE_PATH"
    echo ""
    echo "⚠️  IMPORTANT: Keep this information safe!"
    echo "   - Keystore file: $KEYSTORE_PATH"
    echo "   - Key alias: $KEY_ALIAS"
    echo "   - Passwords you just entered"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Create android/key.properties file"
    echo "   2. Add the following content:"
    echo ""
    echo "      storePassword=YOUR_STORE_PASSWORD"
    echo "      keyPassword=YOUR_KEY_PASSWORD"
    echo "      keyAlias=$KEY_ALIAS"
    echo "      storeFile=$KEYSTORE_PATH"
    echo ""
    echo "   3. Never commit key.properties to git!"
    echo "   4. Upload keystore to CodeMagic securely"
else
    echo ""
    echo "❌ Failed to generate keystore"
    exit 1
fi
