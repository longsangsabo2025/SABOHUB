# 🎉 GOOGLE DRIVE INTEGRATION - HOÀN THÀNH 100%

## ✅ Tổng quan

Đã tích hợp **HOÀN CHỈNH** Google Drive vào SABOHUB app để lưu trữ và quản lý tài liệu!

### 🎯 Tính năng đã hoàn thành:

1. ✅ **Google Drive Service** - Upload, download, delete files
2. ✅ **Database Schema** - Lưu metadata vào Supabase
3. ✅ **Documents Repository** - CRUD operations cho documents
4. ✅ **Provider & State Management** - Riverpod integration
5. ✅ **UI Screens** - Giao diện đầy đủ cho quản lý tài liệu
6. ✅ **CEO Integration** - Thêm tab "Tài liệu" vào CEO Dashboard
7. ✅ **Company Selector** - CEO có thể chọn công ty để quản lý tài liệu

---

## 📂 Cấu trúc code đã tạo

### 1. Models
```
lib/features/documents/models/
  └── document.dart              # Document model với enums
```

### 2. Services
```
lib/features/documents/services/
  └── google_drive_service.dart  # Google Drive API integration
```

### 3. Repositories
```
lib/features/documents/repositories/
  └── documents_repository.dart  # Supabase CRUD operations
```

### 4. Providers
```
lib/providers/
  └── documents_drive_provider.dart  # Riverpod state management
```

### 5. Screens
```
lib/features/documents/screens/
  └── documents_screen.dart      # Màn hình quản lý tài liệu

lib/pages/ceo/
  └── ceo_documents_page.dart    # CEO Documents với company selector
```

### 6. Database
```
create_documents_table.sql       # SQL migration file
create_documents_table.py        # Python script to run migration
```

### 7. Docs
```
GOOGLE-DRIVE-SETUP-GUIDE.md     # Hướng dẫn setup Google Cloud Console
```

---

## 🚀 Cách sử dụng

### Bước 1: Setup Google Cloud Console

**QUAN TRỌNG**: Phải làm bước này trước!

1. Mở file `GOOGLE-DRIVE-SETUP-GUIDE.md`
2. Làm theo hướng dẫn chi tiết:
   - Tạo Google Cloud Project
   - Enable Google Drive API
   - Tạo OAuth 2.0 credentials (Android, iOS, Web)
   - Lưu CLIENT_ID vào file `.env`

### Bước 2: Tạo bảng documents trong Supabase

**Option 1**: Dùng Python script (Khuyến nghị)
```bash
python create_documents_table.py
```

**Option 2**: Chạy SQL thủ công
1. Mở Supabase Dashboard → SQL Editor
2. Copy nội dung từ `create_documents_table.sql`
3. Paste và Execute

### Bước 3: Chạy app

```bash
flutter pub get
flutter run
```

### Bước 4: Sử dụng tính năng Documents

1. **Mở app** → Login với tài khoản CEO
2. **Vào tab "Tài liệu"** (icon folder) ở bottom navigation
3. **Chọn công ty** từ dropdown
4. **Click "Tải lên"** để upload file
5. **Chọn loại tài liệu** và nhập mô tả
6. **Upload thành công!** File được lưu vào Google Drive

---

## 🎨 Giao diện

### Documents Screen
- ✅ Search bar để tìm kiếm tài liệu
- ✅ Filter chips theo loại tài liệu (Tổng quát, Hợp đồng, Hóa đơn, ...)
- ✅ Document cards với:
  - File icon tự động theo loại file
  - File name, size, type
  - Description
  - Created date
  - Actions menu (View, Download, Edit, Delete)
- ✅ Floating Action Button để upload
- ✅ Google Drive connection status indicator
- ✅ Empty state khi chưa có tài liệu
- ✅ Error handling với retry button

### CEO Documents Page
- ✅ Company selector dropdown
- ✅ Tự động chọn công ty đầu tiên
- ✅ Embedded DocumentsScreen cho mỗi công ty
- ✅ Empty state khi chưa có công ty

---

## 🔐 Bảo mật & RLS

### Row Level Security Policies:

1. **SELECT**: 
   - CEO: Xem tất cả documents của tất cả công ty
   - Manager/Employee: Chỉ xem documents của công ty mình

2. **INSERT**:
   - CEO: Upload vào bất kỳ công ty nào
   - Manager/Employee: Chỉ upload vào công ty mình

3. **UPDATE**:
   - CEO: Cập nhật mọi document
   - Manager: Cập nhật documents của công ty mình
   - User: Cập nhật documents do mình upload

4. **DELETE** (Soft delete):
   - CEO: Xóa mọi document
   - Manager: Xóa documents của công ty mình
   - User: Xóa documents do mình upload

---

## 📊 Database Schema

### Bảng `documents`:

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| google_drive_file_id | TEXT | Google Drive file ID (UNIQUE) |
| google_drive_web_view_link | TEXT | Link xem trên Drive |
| google_drive_download_link | TEXT | Link download |
| file_name | TEXT | Tên file |
| file_type | TEXT | MIME type |
| file_size | BIGINT | Kích thước (bytes) |
| file_extension | TEXT | Extension (.pdf, .docx, ...) |
| company_id | UUID | FK to companies |
| uploaded_by | UUID | FK to auth.users |
| document_type | TEXT | Loại (general, contract, invoice, ...) |
| category | TEXT | Danh mục |
| tags | TEXT[] | Array of tags |
| description | TEXT | Mô tả |
| created_at | TIMESTAMPTZ | Thời gian tạo |
| updated_at | TIMESTAMPTZ | Thời gian cập nhật |
| deleted_at | TIMESTAMPTZ | Thời gian xóa (soft delete) |
| is_deleted | BOOLEAN | Flag soft delete |

### Indexes:
- ✅ company_id
- ✅ uploaded_by
- ✅ google_drive_file_id
- ✅ document_type
- ✅ created_at
- ✅ is_deleted
- ✅ Full-text search (file_name + description)

---

## 🎯 Document Types

Đã định nghĩa các loại tài liệu:

1. **Tổng quát** (general)
2. **Hợp đồng** (contract)
3. **Hóa đơn** (invoice)
4. **Báo cáo** (report)
5. **Chính sách** (policy)
6. **Quy trình** (procedure)
7. **Khác** (other)

Có thể thêm loại mới trong `lib/features/documents/models/document.dart`:

```dart
enum DocumentType {
  // Thêm loại mới ở đây
  newType('new_type', 'Loại mới'),
}
```

---

## 🔧 API Methods

### GoogleDriveService

```dart
// Sign in/out
await GoogleDriveService().signIn();
await GoogleDriveService().signOut();

// Upload file
final driveFile = await GoogleDriveService().uploadFile(
  file: File('path/to/file'),
  fileName: 'document.pdf',
  description: 'Optional description',
);

// Download file
final bytes = await GoogleDriveService().downloadFile(driveFileId);

// Delete file
await GoogleDriveService().deleteFile(driveFileId);

// List files
final files = await GoogleDriveService().listFiles(maxResults: 100);

// Search files
final results = await GoogleDriveService().searchFiles('query');
```

### DocumentsRepository

```dart
// Get documents
final docs = await repository.getDocumentsByCompany(companyId);
final myDocs = await repository.getDocumentsByUser(userId);
final typedDocs = await repository.getDocumentsByType(
  companyId: companyId,
  documentType: 'contract',
);

// Search
final results = await repository.searchDocuments(
  companyId: companyId,
  searchQuery: 'hợp đồng',
);

// CRUD operations
final doc = await repository.createDocument(...);
final updated = await repository.updateDocument(...);
await repository.deleteDocument(documentId); // Soft delete
await repository.hardDeleteDocument(documentId); // Permanent

// Stats
final count = await repository.getDocumentsCount(companyId);
final storageUsed = await repository.getTotalStorageUsed(companyId);

// Real-time stream
repository.streamDocuments(companyId).listen((docs) {
  print('Documents updated: ${docs.length}');
});
```

### Provider Usage (Riverpod)

```dart
// In your widget
final documentsState = ref.watch(documentsProvider);

// Upload file
await ref.read(documentsProvider.notifier).uploadFile(
  file: selectedFile,
  fileName: 'document.pdf',
  companyId: currentCompanyId,
  uploadedBy: currentUserId,
  documentType: 'contract',
  description: 'Important contract',
);

// Load documents
await ref.read(documentsProvider.notifier).loadDocuments(companyId);

// Search
await ref.read(documentsProvider.notifier).searchDocuments(
  companyId,
  'search query',
);

// Delete
await ref.read(documentsProvider.notifier).deleteDocument(document);
```

---

## 📦 Dependencies đã thêm

```yaml
dependencies:
  # Google Drive Integration
  googleapis: ^13.2.0
  google_sign_in: ^6.2.2
  extension_google_sign_in_as_googleapis_auth: ^2.0.12
  path_provider: ^2.1.5
  mime: ^2.0.0
```

---

## 🚨 Lưu ý quan trọng

### 1. Environment Variables

Tạo file `.env` trong root project:

```env
# Supabase
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Google Drive
GOOGLE_DRIVE_CLIENT_ID_WEB=your-web-client-id.apps.googleusercontent.com
GOOGLE_DRIVE_CLIENT_ID_ANDROID=your-android-client-id.apps.googleusercontent.com
GOOGLE_DRIVE_CLIENT_ID_IOS=your-ios-client-id.apps.googleusercontent.com
```

**⚠️ KHÔNG COMMIT FILE `.env` LÊN GIT!**

Thêm vào `.gitignore`:
```
.env
*.env
```

### 2. Android Configuration

Thêm vào `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Minimum for Google Sign-In
    }
}
```

### 3. iOS Configuration

Thêm vào `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 4. Web Configuration

Thêm vào `web/index.html`:

```html
<script src="https://accounts.google.com/gsi/client" async defer></script>
```

---

## 🎬 Demo Flow

### Upload Document:

1. User clicks "Tải lên" button
2. File picker opens → User selects file
3. Dialog shows với options:
   - Document type dropdown
   - Description textfield
4. User clicks "Tải lên"
5. Loading indicator shows
6. File uploads to Google Drive
7. Metadata saves to Supabase
8. Success notification
9. Document appears in list

### View/Download:

1. User clicks on document card
2. Details dialog shows
3. User clicks "Xem trong Drive" → Opens Google Drive
4. OR clicks "Tải xuống" → Downloads file

### Delete:

1. User clicks ⋮ menu → Delete
2. Confirmation dialog shows
3. User confirms
4. Soft delete in Supabase
5. Hard delete from Google Drive
6. Document removed from list

---

## 🐛 Troubleshooting

### Lỗi: "Not signed in to Google Drive"

**Giải pháp**:
1. Check Google Cloud Console setup
2. Verify CLIENT_ID trong `.env`
3. Rebuild app: `flutter clean && flutter pub get && flutter run`

### Lỗi: "Failed to upload file"

**Giải pháp**:
1. Check internet connection
2. Verify Google Drive API is enabled
3. Check OAuth scopes are correct
4. Try signing out and signing in again

### Lỗi database: "documents table not found"

**Giải pháp**:
```bash
python create_documents_table.py
```

Hoặc chạy SQL trong Supabase Dashboard.

### Lỗi: "RLS policy violation"

**Giải pháp**:
1. Check user role (ceo/manager/employee)
2. Verify company_id matches user's company
3. Re-run RLS policies trong SQL file

---

## 🔄 Next Steps (Tùy chọn)

### 1. Thêm tính năng nâng cao:

- [ ] Preview file (PDF, images) trong app
- [ ] Share documents với users khác
- [ ] Document versioning
- [ ] Bulk upload multiple files
- [ ] Export documents as ZIP
- [ ] OCR text extraction from images
- [ ] File encryption

### 2. Optimization:

- [ ] Caching downloaded files
- [ ] Background upload queue
- [ ] Compression trước khi upload
- [ ] Thumbnail generation

### 3. Analytics:

- [ ] Track document views
- [ ] Storage usage reports
- [ ] Most viewed documents
- [ ] Upload activity timeline

---

## 📚 Tài liệu tham khảo

- [Google Drive API Documentation](https://developers.google.com/drive/api/v3/about-sdk)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [googleapis package](https://pub.dev/packages/googleapis)
- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart/introduction)

---

## ✅ Checklist Hoàn thành

- [x] Setup Google Cloud Console guide
- [x] Add Flutter packages
- [x] Create database schema & migration
- [x] Implement Document model
- [x] Implement Google Drive Service
- [x] Implement Documents Repository
- [x] Create Riverpod Provider
- [x] Build Documents Screen UI
- [x] Build CEO Documents Page
- [x] Integrate vào CEO Main Layout
- [x] Add Documents tab to bottom navigation
- [x] Implement upload functionality
- [x] Implement download functionality
- [x] Implement delete functionality
- [x] Implement search & filter
- [x] Add RLS policies
- [x] Add error handling
- [x] Add loading states
- [x] Add empty states
- [x] Write comprehensive documentation

---

## 🎊 KẾT LUẬN

**Google Drive Integration đã hoàn thành 100%!** 🚀

App giờ có thể:
- ✅ Upload files lên Google Drive
- ✅ Lưu metadata vào Supabase
- ✅ Hiển thị danh sách tài liệu đẹp mắt
- ✅ Tìm kiếm và lọc tài liệu
- ✅ Download và xóa tài liệu
- ✅ Quản lý theo công ty (CEO)
- ✅ Bảo mật với RLS policies

**Chỉ cần làm theo hướng dẫn trong `GOOGLE-DRIVE-SETUP-GUIDE.md` để setup Google Cloud Console, sau đó app sẽ hoạt động ngay!**

---

Tạo bởi: AI Assistant
Ngày: 04/11/2025
Version: 1.0.0
Status: ✅ HOÀN THÀNH
