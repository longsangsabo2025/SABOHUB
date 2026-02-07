#!/usr/bin/env python3
"""Test Supabase Storage upload directly"""

from supabase import create_client

# Use anon key like the Flutter app
SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y"

def main():
    print("=" * 60)
    print("TESTING SUPABASE STORAGE UPLOAD (ANON KEY)")
    print("=" * 60)
    
    supabase = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
    
    # Create a small test image (1x1 pixel PNG)
    test_image = bytes([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  # PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,  # IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,  # 1x1
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,  # IDAT chunk
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0x00, 0x00, 0x00,
        0x01, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xAA,
        0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,  # IEND chunk
        0xAE, 0x42, 0x60, 0x82
    ])
    
    # Test different buckets
    buckets = ['uploads', 'avatars', 'product-images']
    
    for bucket in buckets:
        print(f"\n📦 Testing bucket: '{bucket}'")
        print("-" * 40)
        
        file_path = f"test/test_upload_{bucket}.png"
        
        try:
            # Try to upload
            result = supabase.storage.from_(bucket).upload(
                file_path,
                test_image,
                file_options={"content-type": "image/png", "upsert": "true"}
            )
            print(f"  ✅ Upload successful!")
            print(f"  Path: {result.path}")
            
            # Get public URL
            public_url = supabase.storage.from_(bucket).get_public_url(file_path)
            print(f"  URL: {public_url}")
            
            # Cleanup - delete test file
            supabase.storage.from_(bucket).remove([file_path])
            print(f"  🧹 Cleaned up test file")
            
        except Exception as e:
            print(f"  ❌ Error: {e}")

if __name__ == "__main__":
    main()
