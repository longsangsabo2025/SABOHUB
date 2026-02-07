#!/usr/bin/env python3
"""Check Supabase Storage buckets"""

import os
from supabase import create_client, Client

# Supabase credentials from .env
SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.zLzk5cWJqYcM0zFhJzTxCx3K3Q-ZvFN7X5JKzV-vQps"

def main():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    # List all buckets
    print("=" * 60)
    print("SUPABASE STORAGE BUCKETS")
    print("=" * 60)
    
    try:
        buckets = supabase.storage.list_buckets()
        print(f"\nFound {len(buckets)} buckets:\n")
        for bucket in buckets:
            print(f"  - {bucket.name}")
            print(f"    ID: {bucket.id}")
            print(f"    Public: {bucket.public}")
            print(f"    Created: {bucket.created_at}")
            print()
    except Exception as e:
        print(f"Error listing buckets: {e}")
    
    # Check specific buckets used in the app
    print("\n" + "=" * 60)
    print("CHECKING BUCKETS USED IN APP:")
    print("=" * 60)
    
    buckets_to_check = ['uploads', 'avatars', 'product-images', 'customer-images', 
                        'company-images', 'documents', 'bills', 'visit-assets', 
                        'ai-files', 'public']
    
    for bucket_name in buckets_to_check:
        try:
            # Try to list files in bucket to see if it exists
            files = supabase.storage.from_(bucket_name).list()
            print(f"✅ '{bucket_name}' exists - {len(files)} files in root")
        except Exception as e:
            print(f"❌ '{bucket_name}' - {e}")

if __name__ == "__main__":
    main()
