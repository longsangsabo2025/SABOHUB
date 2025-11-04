# 💰 HỆ THỐNG HOA HỒNG - HƯỚNG DẪN SỬ DỤNG

## 🎯 TỔNG QUAN
Hệ thống commission cho phép CEO thiết lập quy tắc hoa hồng, Manager upload bill, và nhân viên theo dõi hoa hồng của mình.

## 👥 VAI TRÒ & QUYỀN HẠN

### 🏆 CEO
- ⚙️ **Quản lý quy tắc hoa hồng**: Tạo, sửa, bật/tắt các quy tắc
- ✅ **Duyệt bills**: Approve/Reject bills từ Manager
- 💰 **Thanh toán**: Đánh dấu hoa hồng đã thanh toán
- 📊 **Xem dashboard**: Tổng quan toàn công ty

### 👔 MANAGER
- 📋 **Upload bills**: Chụp/Upload bill với thông tin chi tiết
- 👀 **Xem bills**: Danh sách bills đã upload
- 💰 **Xem hoa hồng**: Hoa hồng của bản thân

### 👨‍💼 NHÂN VIÊN (Staff/Shift Leader)
- 💰 **Xem hoa hồng**: Dashboard hoa hồng cá nhân
- 📊 **Thống kê**: Tổng/Chờ duyệt/Đã duyệt/Đã thanh toán
- 📅 **Filter**: Hôm nay/7 ngày/Tháng/Tất cả

---

## 📱 HƯỚNG DẪN SỬ DỤNG

### 1️⃣ CEO: TẠO QUY TẮC HOA HỒNG

#### Bước 1: Vào trang Quy Tắc
- Mở app → Bottom navigation → **"⚙️ Quy tắc"** (chỉ CEO thấy)

#### Bước 2: Tạo quy tắc mới
- Nhấn nút **"+ Tạo Quy Tắc"** (FAB góc dưới phải)

#### Bước 3: Điền thông tin
- **Tên Quy Tắc**: VD: "Hoa hồng nhân viên bán hàng"
- **Mô Tả**: VD: "5% cho mỗi bill trên 1 triệu"
- **Áp Dụng Cho**: 
  - **👥 Tất cả**: Mọi nhân viên
  - **🎭 Theo vai trò**: Chỉ Staff/Manager/CEO
  - **👤 Cá nhân**: Chọn 1 người cụ thể
- **Phần Trăm Hoa Hồng**: 0-100% (VD: 5)
- **Bill Tối Thiểu**: Chỉ bill >= số tiền này (VD: 1000000)
- **Độ Ưu Tiên**: Số càng lớn càng ưu tiên (VD: 0)

#### Bước 4: Lưu
- Nhấn **"Tạo"** → Quy tắc sẽ active ngay lập tức

#### Tips:
- Tạo nhiều quy tắc với priority khác nhau
- Quy tắc priority cao hơn được áp dụng trước
- Có thể bật/tắt quy tắc bất cứ lúc nào (Toggle switch)

---

### 2️⃣ MANAGER: UPLOAD BILL

#### Bước 1: Vào trang Bills
- Mở app → Bottom navigation → **"📋 Bills"**

#### Bước 2: Upload bill mới
- Nhấn nút **"+ Upload Bill"** (FAB góc dưới phải)

#### Bước 3: Chụp/Chọn ảnh bill
- Nhấn **"Chọn Ảnh Bill"**
- Chọn ảnh từ thư viện hoặc chụp mới

#### Bước 4: Điền thông tin
- **Số Bill\***: VD: BILL001 (bắt buộc)
- **Ngày Bill**: Chọn ngày từ calendar
- **Tổng Tiền\***: VD: 1500000 (bắt buộc)
- **Tên Cửa Hàng**: VD: Chi nhánh 1 (tùy chọn)
- **Ghi Chú**: Thêm ghi chú nếu cần

#### Bước 5: Upload
- Nhấn **"✅ Upload Bill"**
- Bill sẽ ở trạng thái **"⏳ Chờ duyệt"**

---

### 3️⃣ CEO: DUYỆT BILL & TÍNH HOA HỒNG

#### Bước 1: Xem danh sách bills
- Vào **"📋 Bills"** → Xem bills pending

#### Bước 2: Duyệt bill
- Mở bill → Xem chi tiết
- Nhấn **"✅ Duyệt & Tính HH"**

#### Điều gì xảy ra khi duyệt?
1. ✅ Bill status → **Approved**
2. 🔄 Hệ thống tự động tính hoa hồng cho **TẤT CẢ nhân viên**
3. 📊 Dựa trên quy tắc (priority cao nhất)
4. 💾 Lưu vào bảng `bill_commissions`
5. ✅ Auto approve tất cả commissions

#### Nếu từ chối:
- Nhấn **"❌ Từ chối"** → Bill bị reject, không tính hoa hồng

---

### 4️⃣ NHÂN VIÊN: XEM HOA HỒNG

#### Bước 1: Vào trang Hoa Hồng
- Mở app → Bottom navigation → **"💰 Hoa hồng"**

#### Bước 2: Xem dashboard
- **💰 Tổng Hoa Hồng**: Tổng cộng tất cả
- **⏳ Chờ Duyệt**: Bills chưa được CEO duyệt
- **✅ Đã Duyệt**: Bills đã duyệt, chưa thanh toán
- **💸 Đã Thanh Toán**: Đã nhận tiền

#### Bước 3: Filter theo thời gian
- Nhấn icon **filter** (góc phải AppBar)
- Chọn:
  - 📅 Hôm nay
  - 📆 7 ngày qua
  - 📊 Tháng này
  - 🗓️ Tất cả

#### Bước 4: Xem chi tiết
- Scroll xuống xem danh sách từng bill
- Mỗi bill hiển thị:
  - Số tiền hoa hồng
  - % hoa hồng
  - Base amount
  - Ngày giờ
  - Status

---

### 5️⃣ CEO: THANH TOÁN HOA HỒNG

#### Bước 1: Vào Bills → Filter "✅ Đã duyệt"
- Nhấn filter → Chọn **"Đã duyệt"**

#### Bước 2: Đánh dấu đã thanh toán
- Mở bill → Nhấn **"💰 Đánh dấu đã thanh toán"**

#### Điều gì xảy ra?
1. Bill status → **Paid**
2. Tất cả commissions của bill → **Paid**
3. Nhân viên thấy hoa hồng chuyển sang **💸 Đã Thanh Toán**

---

## 🎨 TIPS & TRICKS

### 💡 CEO Tips
1. **Tạo quy tắc theo tầng**:
   - Priority 10: Nhân viên xuất sắc (10%)
   - Priority 5: Staff thường (5%)
   - Priority 0: Default (3%)

2. **Set min bill amount** để chỉ tính hoa hồng cho bill lớn

3. **Dùng effective dates** cho campaign có thời hạn

### 💡 Manager Tips
1. **Chụp ảnh rõ ràng** - Ảnh bill dễ đọc
2. **Ghi chú đầy đủ** - Giúp CEO duyệt nhanh
3. **Check lại số tiền** - Đảm bảo chính xác

### 💡 Staff Tips
1. **Check dashboard hàng ngày** - Theo dõi hoa hồng
2. **Dùng filter** - Xem theo tháng để tính lương
3. **Screenshot dashboard** - Lưu proof khi cần

---

## 🔧 TROUBLESHOOTING

### ❓ Không thấy quy tắc nào?
- Chỉ CEO mới tạo được quy tắc
- Vào CEO app → "⚙️ Quy tắc"

### ❓ Upload bill bị lỗi?
- Kiểm tra kết nối internet
- Đảm bảo ảnh không quá lớn (< 10MB)
- Điền đầy đủ thông tin bắt buộc (*)

### ❓ Không tính hoa hồng?
- Kiểm tra có quy tắc active không
- Bill amount phải >= min_bill_amount
- CEO cần approve bill trước

### ❓ Hoa hồng sai số tiền?
- Kiểm tra % trong quy tắc
- Kiểm tra priority (quy tắc nào được áp dụng)
- CEO có thể sửa commission trực tiếp trong DB

---

## 📊 VÍ DỤ THỰC TẾ

### Scenario 1: Hoa hồng đồng đều cho tất cả
**CEO tạo rule:**
- Tên: "Default 5%"
- Áp dụng: **Tất cả**
- Phần trăm: **5%**
- Min bill: **0**

→ Mọi nhân viên đều được 5% từ mọi bill

---

### Scenario 2: Bonus cho nhân viên xuất sắc
**CEO tạo 2 rules:**

**Rule 1:**
- Tên: "Top Performer Bonus"
- Áp dụng: **Cá nhân** (chọn user A)
- Phần trăm: **10%**
- Priority: **10**

**Rule 2:**
- Tên: "Default"
- Áp dụng: **Tất cả**
- Phần trăm: **5%**
- Priority: **0**

→ User A được 10%, còn lại được 5%

---

### Scenario 3: Chỉ tính bill lớn
**CEO tạo rule:**
- Tên: "Big Bill Bonus"
- Áp dụng: **Tất cả**
- Phần trăm: **7%**
- Min bill: **5000000** (5 triệu)

→ Chỉ bill >= 5 triệu mới được hoa hồng 7%

---

## ✅ CHECKLIST HOÀN THÀNH

- [x] CEO tạo ít nhất 1 quy tắc hoa hồng
- [x] Manager upload 1 bill test
- [x] CEO approve bill → Check hoa hồng được tính
- [x] Nhân viên vào xem dashboard hoa hồng
- [x] CEO đánh dấu đã thanh toán
- [x] Nhân viên check status chuyển sang Paid

---

## 🎉 CHÚC MỪNG!
Hệ thống commission đã sẵn sàng sử dụng! 💰✨
