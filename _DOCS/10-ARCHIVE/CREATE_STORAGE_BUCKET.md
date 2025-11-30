# 📦 Tạo Supabase Storage Bucket cho File Uploads

## Lỗi hiện tại:
```
StorageException(message: Bucket not found, statusCode: 404, error: Bucket not found)
```

## Giải pháp: Tạo bucket `documents`

### Cách 1: Tạo qua Supabase Dashboard (Khuyên dùng - 2 phút)

1. **Truy cập Supabase Dashboard:**
   - Đăng nhập: https://supabase.com/dashboard
   - Chọn project của bạn

2. **Vào Storage:**
   - Sidebar bên trái → Click **"Storage"**

3. **Tạo bucket mới:**
   - Click button **"New bucket"**
   - **Name**: `documents`
   - **Public bucket**: ✅ **CHECKED** (để file có thể download được)
   - **File size limit**: 50 MB (hoặc tùy chỉnh)
   - **Allowed MIME types**: Để trống (allow all) hoặc thêm:
     ```
     image/jpeg, image/png, image/gif, image/webp
     application/pdf
     application/vnd.openxmlformats-officedocument.wordprocessingml.document
     application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
     application/vnd.openxmlformats-officedocument.presentationml.presentation
     text/plain
     ```
   - Click **"Create bucket"**

4. **Xác nhận:**
   - Bucket `documents` sẽ xuất hiện trong danh sách
   - Public URL format: `https://{project}.supabase.co/storage/v1/object/public/documents/...`

---

### Cách 2: Tạo bằng SQL (Nhanh hơn nếu quen SQL)

1. **Vào SQL Editor:**
   - Supabase Dashboard → **SQL Editor**

2. **Chạy lệnh SQL:**
   ```sql
   -- Create storage bucket
   INSERT INTO storage.buckets (id, name, public)
   VALUES ('documents', 'documents', true);

   -- Set bucket policies (allow authenticated users to upload)
   CREATE POLICY "Allow authenticated uploads"
   ON storage.objects FOR INSERT
   TO authenticated
   WITH CHECK (bucket_id = 'documents');

   -- Allow public downloads
   CREATE POLICY "Allow public downloads"
   ON storage.objects FOR SELECT
   TO public
   USING (bucket_id = 'documents');

   -- Allow users to delete their own files
   CREATE POLICY "Allow users to delete own files"
   ON storage.objects FOR DELETE
   TO authenticated
   USING (bucket_id = 'documents' AND owner = auth.uid());
   ```

3. **Click "Run"**

---

### Cách 3: Tạo bằng Python script (Automation)

```python
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')  # Need service role key
)

# Create bucket
try:
    supabase.storage.create_bucket('documents', {
        'public': True,
        'file_size_limit': 52428800,  # 50MB
        'allowed_mime_types': [
            'image/jpeg', 'image/png', 'image/gif', 'image/webp',
            'application/pdf',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'text/plain'
        ]
    })
    print('✅ Bucket "documents" created successfully!')
except Exception as e:
    print(f'❌ Error: {e}')
```

---

## Sau khi tạo bucket:

### Test upload ngay:
1. Refresh app (hot reload: `r` trong terminal)
2. Vào Manager Tasks → Click task
3. Click "Tải file lên" → Chọn file
4. Upload sẽ thành công ✅

### Kiểm tra file đã upload:
- Supabase Dashboard → Storage → `documents` bucket
- Xem folder `task-attachments/{taskId}/`

---

## ⚠️ LƯU Ý BẢO MẬT:

Hiện tại bucket đang **public** (ai cũng download được nếu có URL). Nếu cần bảo mật hơn:

### Option 1: Private bucket + Signed URLs
```dart
// Generate signed URL with expiration
final signedUrl = await _supabase.storage
    .from('documents')
    .createSignedUrl('path/to/file', 3600); // Expires in 1 hour
```

### Option 2: Row Level Security trên storage.objects
```sql
-- Only allow download if user is task creator or assignee
CREATE POLICY "Restrict downloads to task participants"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM tasks
    WHERE tasks.id = (storage.objects.name::text SPLIT_PART('/', 2))
    AND (tasks.created_by = auth.uid() OR tasks.assigned_to = auth.uid())
  )
);
```

---

## Troubleshooting:

**Nếu vẫn lỗi sau khi tạo bucket:**
1. Check tên bucket đúng là `documents` (lowercase, không có space)
2. Verify bucket là public
3. Clear browser cache
4. Hot restart app (Shift+R trong terminal)

**Nếu upload thành công nhưng không download được:**
- Check bucket policies
- Verify public access enabled
- Test URL trực tiếp trong browser
