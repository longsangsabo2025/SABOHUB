# Hệ thống Người giới thiệu & Hoa hồng (Referral Commission System)

> **Trạng thái**: ✅ Database & UI cơ bản đã hoàn thành  
> **Cập nhật**: 2026-02-01

---

## 📋 Tổng quan

Hệ thống quản lý người giới thiệu khách hàng mới và tính hoa hồng theo đơn hàng.

### Yêu cầu nghiệp vụ:
- Người giới thiệu có thể là **bất kỳ ai** (KH cũ, CTV, người quen...)
- **% hoa hồng tùy chỉnh** theo từng người (không cố định)
- Tính hoa hồng khi **khách hàng thanh toán xong**
- Tính trên **giá trị hàng không VAT**
- Có thể cài đặt tính **chỉ đơn đầu** hoặc **tất cả đơn** theo từng người

---

## 🗄️ Database Schema

### Bảng `referrers` - Người giới thiệu

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `company_id` | UUID | FK → companies |
| `name` | VARCHAR(255) | Họ tên người giới thiệu |
| `phone` | VARCHAR(20) | Số điện thoại |
| `email` | VARCHAR(255) | Email |
| `bank_name` | VARCHAR(100) | Tên ngân hàng |
| `bank_account` | VARCHAR(50) | Số tài khoản |
| `bank_holder` | VARCHAR(255) | Chủ tài khoản |
| `commission_rate` | DECIMAL(5,2) | % hoa hồng (VD: 3.00 = 3%) |
| `commission_type` | VARCHAR(20) | `first_order` hoặc `all_orders` |
| `notes` | TEXT | Ghi chú |
| `status` | VARCHAR(20) | `active` / `inactive` |
| `total_earned` | DECIMAL(15,2) | Tổng hoa hồng đã tích lũy |
| `total_paid` | DECIMAL(15,2) | Tổng đã thanh toán |
| `created_at` | TIMESTAMPTZ | Ngày tạo |
| `updated_at` | TIMESTAMPTZ | Ngày cập nhật |

### Bảng `commissions` - Chi tiết hoa hồng

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `company_id` | UUID | FK → companies |
| `referrer_id` | UUID | FK → referrers |
| `customer_id` | UUID | FK → customers |
| `order_id` | UUID | FK → orders (nullable) |
| `order_code` | VARCHAR(50) | Mã đơn hàng |
| `order_amount` | DECIMAL(15,2) | Giá trị đơn (không VAT) |
| `commission_rate` | DECIMAL(5,2) | % tại thời điểm tính |
| `commission_amount` | DECIMAL(15,2) | Số tiền hoa hồng |
| `status` | VARCHAR(20) | `pending` / `approved` / `paid` / `cancelled` |
| `approved_at` | TIMESTAMPTZ | Ngày duyệt |
| `approved_by` | UUID | Người duyệt |
| `paid_at` | TIMESTAMPTZ | Ngày thanh toán |
| `paid_by` | UUID | Người thanh toán |
| `payment_note` | TEXT | Ghi chú thanh toán |
| `created_at` | TIMESTAMPTZ | Ngày tạo |

### Bảng `customers` - Thêm cột

| Column | Type | Description |
|--------|------|-------------|
| `referrer_id` | UUID | FK → referrers (nullable) |

---

## 📱 Flutter Implementation

### Models
- `lib/models/referrer.dart` - Model cho `Referrer` và `Commission`

### Providers (odori_providers.dart)
- `referrersProvider` - Danh sách người giới thiệu với filter
- `activeReferrersProvider` - Danh sách active (cho dropdown)
- `commissionsProvider` - Danh sách hoa hồng với filter

### Pages
- `lib/pages/distribution_manager/referrers_page.dart` - Quản lý người giới thiệu

### Customer Forms (đã tích hợp)
- `customers_page.dart` - Dropdown chọn người giới thiệu
- `distribution_sales_layout.dart` - Dropdown chọn người giới thiệu

### Menu Navigation
- Drawer menu → "Người giới thiệu" (icon màu cam)

---

## 🔄 Flow xử lý hoa hồng

```
┌─────────────────────────────────────────────────────────────────┐
│  1. Tạo khách hàng mới → Chọn người giới thiệu (referrer_id)    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  2. Khách đặt đơn hàng                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  3. Khách thanh toán xong (payment_status = 'paid')             │
│     → Trigger tự động tạo commission record                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  4. Admin duyệt commission (status: pending → approved)          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  5. Thanh toán hoa hồng (status: approved → paid)                │
│     → Cập nhật referrer.total_paid                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚀 TODO - Phát triển tiếp

### Phase 2: Tự động tính hoa hồng
- [ ] Tạo database trigger khi order payment_status = 'paid'
- [ ] Logic kiểm tra commission_type (first_order vs all_orders)
- [ ] Tính toán order_amount không VAT
- [ ] Tạo commission record tự động

```sql
-- Pseudo trigger
CREATE OR REPLACE FUNCTION calculate_commission()
RETURNS TRIGGER AS $$
BEGIN
  -- Kiểm tra order đã thanh toán
  IF NEW.payment_status = 'paid' AND OLD.payment_status != 'paid' THEN
    -- Lấy thông tin referrer của customer
    -- Kiểm tra commission_type
    -- Tính hoa hồng
    -- Insert vào commissions table
    -- Cập nhật referrer.total_earned
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Phase 3: UI Quản lý Commissions
- [ ] Trang danh sách commissions (filter theo status, referrer)
- [ ] Nút duyệt hàng loạt (bulk approve)
- [ ] Nút thanh toán (ghi nhận đã trả)
- [ ] Export báo cáo hoa hồng

### Phase 4: Báo cáo & Thống kê
- [ ] Dashboard tổng hoa hồng theo tháng
- [ ] Top người giới thiệu
- [ ] Thống kê KH mới từ referral
- [ ] ROI của chương trình referral

### Phase 5: Mở rộng (Optional)
- [ ] Multi-level referral (cấp 1, cấp 2...)
- [ ] Hoa hồng theo sản phẩm
- [ ] Hoa hồng theo tier khách hàng
- [ ] Tích hợp thanh toán tự động

---

## 📝 Ghi chú

- Hoa hồng được tính trên **giá trị hàng không VAT**
- Mỗi người giới thiệu có thể có **% khác nhau**
- Có thể cài **chỉ đơn đầu** (tạo động lực giới thiệu KH mới) hoặc **tất cả đơn** (duy trì quan hệ lâu dài)
- Commission record lưu lại `commission_rate` tại thời điểm tính (phòng trường hợp thay đổi % sau)

---

## 🔗 Files liên quan

```
sabohub-app/SABOHUB/
├── lib/
│   ├── models/
│   │   ├── referrer.dart              # Model Referrer & Commission
│   │   └── odori_customer.dart        # Thêm referrer_id, referrerName
│   ├── providers/
│   │   └── odori_providers.dart       # Providers cho referrers, commissions
│   ├── pages/
│   │   └── distribution_manager/
│   │       ├── referrers_page.dart    # Trang quản lý người giới thiệu
│   │       └── customers_page.dart    # Form có dropdown referrer
│   └── layouts/
│       ├── distribution_manager_layout.dart  # Menu navigation
│       └── distribution_sales_layout.dart    # Form có dropdown referrer
└── docs/
    └── REFERRAL_COMMISSION_SYSTEM.md  # File này
```

---

*Tài liệu này được tạo để theo dõi tiến độ phát triển hệ thống Referral Commission.*
