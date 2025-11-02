# 🔄 HƯỚNG DẪN LÀM MỚI DỮ LIỆU CEO DASHBOARD

## ✅ Đã thêm nút "Làm mới" vào AppBar!

Tôi đã thêm nút **Refresh (🔄)** vào AppBar của CEO Tasks Page.

### Cách dùng:

1. **Mở app** trên Chrome (đang chạy rồi)

2. **Vào CEO Dashboard:**
   - Click nút tím ở góc dưới phải
   - Chọn "CEO" từ menu
   
3. **Click tab "Phân tích"** (tab thứ 3)

4. **Click nút "🔄 Refresh"** ở góc trên bên phải (trong AppBar)
   - Nút này sẽ:
     - Invalidate tất cả providers
     - Fetch lại data từ database
     - Hiển thị snackbar "🔄 Đã làm mới dữ liệu từ database!"

5. **Xem kết quả:**
   - Sẽ thấy 2 cards của 2 công ty:
   
   ```
   🏢 Nhà hàng Sabo HCM
   📋 Tổng: 5
   ✅ Hoàn thành: 3
   🔄 Đang làm: 1
   ⏰ Chờ xử lý: 1
   
   🏢 Cafe Sabo Hà Nội
   📋 Tổng: 11
   ✅ Hoàn thành: 2
   ✅ Đang làm: 3
   ⏰ Chờ xử lý: 6
   ```

## 🐛 Nếu vẫn thấy mock data:

### Option 1: Hot Reload
1. Vào terminal đang chạy Flutter
2. Nhấn phím `R` (shift + r) để **hot restart**

### Option 2: Restart App
```bash
# Stop app hiện tại (Ctrl + C trong terminal Flutter)
# Hoặc click "Stop" trong VS Code

# Start lại:
flutter run -d chrome
```

### Option 3: Clear Cache
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

## 📊 Data hiện tại trong Database:

Tôi đã seed data sau:

### Companies (2):
1. **Nhà hàng Sabo HCM** (ID: 10000000-0000-0000-0000-000000000001)
   - 5 tasks total
   - 3 completed
   - 1 in_progress  
   - 1 pending

2. **Cafe Sabo Hà Nội** (ID: 10000000-0000-0000-0000-000000000002)
   - 11 tasks total
   - 2 completed
   - 3 in_progress
   - 6 pending

### Users created:
- **CEO**: ceo1@sabohub.com, ceo2@sabohub.com
- **Managers**: manager1-4@sabohub.com
- **Staff**: staff1-4@sabohub.com

## 🔍 Debug:

Nếu vẫn không thấy data, check console:

1. **Mở DevTools** (F12)
2. **Xem Console** tab
3. **Tìm lỗi** liên quan đến:
   - Supabase connection
   - Database queries
   - Provider errors

## ✨ Tính năng đã có:

✅ Nút Refresh trong AppBar
✅ Auto-fetch data từ database
✅ Show loading spinner
✅ Show error messages
✅ Company statistics cards
✅ Progress percentages
✅ Color-coded status

---

**Tóm lại**: Click nút 🔄 ở góc trên bên phải để fetch data mới!
