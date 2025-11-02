#!/bin/bash

# AI Features Test Script
# This script helps you test all AI features locally

echo "🚀 Starting AI Features Test..."
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found!"
    echo "Please create .env file with OPENAI_API_KEY"
    exit 1
fi

# Check if OpenAI API key is set
if ! grep -q "OPENAI_API_KEY=" .env; then
    echo "❌ Error: OPENAI_API_KEY not found in .env"
    exit 1
fi

echo "✅ Environment configured"
echo ""

# Function to test AI chat
test_chat() {
    echo "🧪 Testing AI Chat..."
    echo "1. Run app: flutter run -d chrome"
    echo "2. Navigate to Company Details → AI Assistant"
    echo "3. Send message: 'Xin chào! Phân tích doanh thu.'"
    echo ""
}

# Function to test file upload
test_files() {
    echo "🧪 Testing File Upload..."
    echo "1. Click 📎 icon in chat"
    echo "2. Select an image file"
    echo "3. Wait for AI analysis (10-15 seconds)"
    echo "4. Check file gallery (folder icon)"
    echo ""
}

# Function to test recommendations
test_recommendations() {
    echo "🧪 Testing Recommendations..."
    echo "1. Click 💡 icon in header"
    echo "2. View recommendations list"
    echo "3. Click on a recommendation"
    echo "4. Accept or Reject"
    echo ""
}

# Main menu
echo "Select test to run:"
echo "1. All tests (recommended)"
echo "2. Chat only"
echo "3. File upload only"
echo "4. Recommendations only"
echo "5. Run Flutter app"
echo ""

read -p "Enter choice (1-5): " choice

case $choice in
    1)
        echo ""
        test_chat
        test_files
        test_recommendations
        echo "✅ All test instructions displayed"
        echo ""
        read -p "Run Flutter app now? (y/n): " run_app
        if [ "$run_app" = "y" ]; then
            flutter run -d chrome
        fi
        ;;
    2)
        test_chat
        ;;
    3)
        test_files
        ;;
    4)
        test_recommendations
        ;;
    5)
        flutter run -d chrome
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
