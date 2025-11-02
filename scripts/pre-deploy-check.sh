#!/bin/bash

# SABOHUB - Pre-deployment Check Script
# This script validates the app is ready for deployment

echo "🔍 SABOHUB Pre-Deployment Check"
echo "================================"
echo ""

ERRORS=0
WARNINGS=0

# Check Flutter installation
echo "📱 Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "   ❌ Flutter not found"
    ((ERRORS++))
else
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo "   ✅ $FLUTTER_VERSION"
fi

# Check Flutter doctor
echo ""
echo "🏥 Running Flutter doctor..."
if flutter doctor | grep -q "\[!\]"; then
    echo "   ⚠️  Some issues found (check above)"
    ((WARNINGS++))
else
    echo "   ✅ All checks passed"
fi

# Check dependencies
echo ""
echo "📦 Checking dependencies..."
if [ -f "pubspec.lock" ]; then
    echo "   ✅ Dependencies locked"
else
    echo "   ❌ pubspec.lock not found. Run: flutter pub get"
    ((ERRORS++))
fi

# Check .env file
echo ""
echo "🔐 Checking environment configuration..."
if [ -f ".env" ]; then
    echo "   ✅ .env file exists"
    if grep -q "SUPABASE_URL" .env && grep -q "SUPABASE_ANON_KEY" .env; then
        echo "   ✅ Environment variables configured"
    else
        echo "   ⚠️  Missing required environment variables"
        ((WARNINGS++))
    fi
else
    echo "   ⚠️  .env file not found"
    ((WARNINGS++))
fi

# Run Flutter analyze
echo ""
echo "🔍 Running Flutter analyze..."
if flutter analyze --no-fatal-warnings > /dev/null 2>&1; then
    echo "   ✅ No issues found"
else
    echo "   ⚠️  Analysis found issues"
    flutter analyze --no-fatal-warnings
    ((WARNINGS++))
fi

# Run Flutter tests
echo ""
echo "🧪 Running Flutter tests..."
if flutter test > /dev/null 2>&1; then
    echo "   ✅ All tests passed"
else
    echo "   ⚠️  Some tests failed"
    ((WARNINGS++))
fi

# Check iOS configuration
echo ""
echo "🍎 Checking iOS configuration..."
if [ -d "ios" ]; then
    echo "   ✅ iOS project exists"
    
    if grep -q "com.sabohub.app" ios/Runner/Info.plist; then
        echo "   ✅ Bundle ID configured"
    else
        echo "   ⚠️  Bundle ID not properly configured"
        ((WARNINGS++))
    fi
    
    if [ -f "ios/Podfile.lock" ]; then
        echo "   ✅ CocoaPods installed"
    else
        echo "   ⚠️  CocoaPods not installed. Run: cd ios && pod install"
        ((WARNINGS++))
    fi
else
    echo "   ❌ iOS project not found"
    ((ERRORS++))
fi

# Check Android configuration
echo ""
echo "🤖 Checking Android configuration..."
if [ -d "android" ]; then
    echo "   ✅ Android project exists"
    
    if grep -q "com.sabohub.app" android/app/build.gradle; then
        echo "   ✅ Package name configured"
    else
        echo "   ⚠️  Package name not properly configured"
        ((WARNINGS++))
    fi
    
    if [ -f "android/key.properties" ]; then
        echo "   ✅ Signing configuration exists"
    else
        echo "   ⚠️  key.properties not found (needed for release build)"
        ((WARNINGS++))
    fi
else
    echo "   ❌ Android project not found"
    ((ERRORS++))
fi

# Check codemagic.yaml
echo ""
echo "🔧 Checking CodeMagic configuration..."
if [ -f "codemagic.yaml" ]; then
    echo "   ✅ codemagic.yaml exists"
else
    echo "   ⚠️  codemagic.yaml not found"
    ((WARNINGS++))
fi

# Summary
echo ""
echo "================================"
echo "📊 Summary"
echo "================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All checks passed! Ready for deployment."
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  $WARNINGS warning(s) found."
    echo "   Review warnings before deployment."
    echo ""
    exit 0
else
    echo "❌ $ERRORS error(s) and $WARNINGS warning(s) found."
    echo "   Please fix errors before deployment."
    echo ""
    exit 1
fi
