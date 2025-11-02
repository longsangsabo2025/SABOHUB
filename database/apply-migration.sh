#!/bin/bash

# ============================================================================
# 🚀 SABOHUB DATABASE SETUP SCRIPT
# ============================================================================
# Apply core database migration to Supabase
# ============================================================================

echo "🔄 Applying SaboHub Core Database Migration..."

# Read environment variables
source .env

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Please install it first:"
    echo "npm install -g supabase"
    exit 1
fi

# Apply migration
echo "📊 Creating core tables..."
supabase db push

echo "✅ Database migration completed!"
echo ""
echo "📋 Tables created:"
echo "  - companies (CEO manages multiple companies)"
echo "  - users (User management)"
echo "  - stores (Company branches/stores)"
echo "  - tables (Billiard tables)"
echo "  - tasks (Task management)"
echo "  - activity_logs (System activity)"
echo "  - profiles (Extended user info)"
echo ""
echo "🎯 Ready for SaboHub Flutter app!"