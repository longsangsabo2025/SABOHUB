#!/usr/bin/env python3
"""
Process SABO Billiards operational document and add to database
"""

import os
from datetime import datetime
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv('.env')

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

def add_sabo_documents():
    """Add SABO operational documents to database"""
    
    print("🔍 Finding SABO Billiards company...")
    
    # Get SABO Billiards company
    company = supabase.table('companies').select('*').ilike('name', '%SABO%').execute()
    
    if not company.data:
        print("❌ SABO Billiards company not found!")
        return
    
    company_id = company.data[0]['id']
    company_name = company.data[0]['name']
    print(f"✅ Found: {company_name} (ID: {company_id})")
    
    # Documents extracted from the Word file
    documents = [
        {
            "title": "📋 1. Sơ đồ tổ chức & Mô tả công việc",
            "category": "organization",
            "description": "Cơ cấu tổ chức quán bida và phân công nhiệm vụ chi tiết từng vị trí",
            "content": """
# SƠ ĐỒ TỔ CHỨC & MÔ TẢ CÔNG VIỆC

## 1.1. Sơ đồ tổ chức (Cơ bản – Quán bida quy mô vừa)

```
Chủ quán
   │
Quản lý tổng
   ├── Trưởng ca (Ca sáng / Ca tối)
   │     ├── Nhân viên phục vụ
   │     ├── Thu ngân (nếu có)
   │     └── Kỹ thuật / Vệ sinh / Sự cố (nếu có)
   └── Marketing / Sự kiện (nếu có)
```

**Chú ý quan trọng:**
- Thiếu nhân viên ở đâu thì người phụ trách giữ luôn vai trò đó
- Thiếu phục vụ, thu ngân, kỹ thuật → Trưởng ca nhận trách nhiệm
- Thiếu trưởng ca → Quản lý tổng nhận trách nhiệm
- Thiếu quản lý tổng → Chủ quán nhận trách nhiệm

## 1.2. Checklist mô tả công việc theo vai trò

### Chủ quán
**Nhiệm vụ chính:** Định hướng & quản lý cấp cao
- Giám sát hệ thống
- Phê duyệt ngân sách, chiến lược
- Nhận báo cáo tuần/tháng

### Quản lý tổng
**Nhiệm vụ chính:** Điều hành hoạt động toàn quán
- Phân ca, xử lý sự cố
- Kiểm soát chi phí, báo cáo
- Đào tạo nhân sự mới

### Trưởng ca
**Nhiệm vụ chính:** Quản lý ca làm việc
- Nhận & giao ca
- Kiểm tra vệ sinh, thiết bị
- Chốt ca, báo cáo, chụp ảnh Checksheet

### Nhân viên Phục vụ
**Nhiệm vụ chính:** Phục vụ khách & duy trì khu vực
- Chào khách, order nước
- Vệ sinh khu bàn chơi
- Hỗ trợ tổ chức sự kiện

### Thu ngân
**Nhiệm vụ chính:** Giao dịch khách hàng
- Check-in, tính giờ, thanh toán
- Báo cáo tiền cuối ca

### Kỹ thuật/Vệ sinh
**Nhiệm vụ chính:** Quản lý thiết bị & vệ sinh
- Lau bàn, thiết bị, toilet
- Ghi nhận & xử lý sự cố
- Bảo trì định kỳ

### Marketing/Sự kiện (nếu có)
**Nhiệm vụ chính:** Truyền thông & tổ chức event
- Viết bài, livestream
- Lên kế hoạch giải đấu
- Quản lý hình ảnh thương hiệu
"""
        },
        {
            "title": "👥 2. Phân công nhiệm vụ chi tiết",
            "category": "job-description",
            "description": "Mô tả chi tiết công việc của Quản lý tổng và 2 Nhân viên phục vụ",
            "content": """
# PHÂN CÔNG NHIỆM VỤ CHI TIẾT

## 🧑‍💼 1. QUẢN LÝ TỔNG (FULL-TIME)

| Nhiệm vụ | Mô tả cụ thể |
|----------|--------------|
| Mở – đóng quán | Kiểm tra thiết bị, đèn, camera, máy lạnh – tắt điện cuối ca |
| Phân ca – lịch làm việc | Lập lịch cho nhân viên, linh động theo tình hình thực tế |
| Kiểm tra Checksheet vệ sinh | Theo dõi từng mục: toàn quán, bàn bida, toilet, quầy, khu vực trước quán |
| Quản lý tài chính trong ca | Theo dõi tiền mặt, đối chiếu thu chi, xử lý chênh lệch |
| Hướng dẫn khách – giải quyết sự cố | Tiếp khách, xử lý tranh chấp bàn chơi, hỗ trợ kỹ thuật |
| Theo dõi vật tư tiêu hao | Kiểm kho cuối mỗi ca dựa trên báo cáo kiểm kho của trưởng ca |
| Đề xuất, mua sắm vật tư | Lên kế hoạch và tự mua nếu là khoản chi nhỏ, đối với khoản chi lớn thì đề xuất với chủ quán |
| Đào tạo nhân viên mới | Hướng dẫn tiêu chuẩn phục vụ, giao tiếp, vệ sinh, báo cáo |
| Báo cáo chủ quán | Tổng hợp doanh thu, sự cố, đề xuất cải tiến (tuần/tháng) |

## 👕 2. NHÂN VIÊN PHỤC VỤ A (Hướng tới trưởng ca ca sáng)

| Nhiệm vụ | Mô tả cụ thể |
|----------|--------------|
| Vệ sinh mở quán | Hút bụi sàn, bàn bida, đánh bi, Lau bàn, ghế, nhà vệ sinh, khu vực trước quán, kiểm tra cơ |
| Tiếp khách | Chào hỏi, mời nước, gợi ý combo, giới thiệu bảng giá, nắm được thông tin khách |
| Quản lý khu bàn | Bấm giờ, áp khuyến mãi tùy vào đối tượng khách |
| Phục vụ đồ uống | Nhận order – chuẩn bị – giao đúng bàn, đúng món |
| Hướng dẫn khách mới | Hỗ trợ cách sử dụng bàn chơi, đưa cơ, giới thiệu luật cơ bản |
| Vệ sinh định kỳ | Lau bàn mỗi lượt khách rời – quét dọn theo checklist |
| Bàn giao ca | Bàn giao ca cho nhân viên ca tối, báo cáo ca |
| Báo cáo quản lý | Báo cáo sự cố, đề xuất cải tiến |

## 👕 3. NHÂN VIÊN PHỤC VỤ B (Hướng tới trưởng ca ca tối)

| Nhiệm vụ | Mô tả cụ thể |
|----------|--------------|
| Vệ sinh đầu ca tối | Nhà vệ sinh, khu vực trước quán, bàn ghế, quầy, đánh bi |
| Setup quán buổi tối | Bật đèn bảng hiệu, kiểm tra ánh sáng |
| Tiếp khách | Chào hỏi, mời nước, gợi ý combo, giới thiệu bảng giá, nắm được thông tin khách |
| Quản lý khu bàn | Bấm giờ, áp khuyến mãi tùy vào đối tượng khách |
| Giao tiếp & chăm sóc khách | Hỏi thăm, phục vụ thêm nước – upsell combo |
| Vệ sinh định kỳ | Lau bàn mỗi lượt khách rời – quét dọn theo checklist |
| Báo cáo cuối ca | Báo cáo ca, chụp hình bàn giao cho ca sáng trên group |
| Báo cáo quản lý | Báo cáo sự cố, đề xuất cải tiến |

## 📌 Lưu ý quan trọng:
- Cả 2 nhân viên phục vụ luân phiên gửi hình ảnh Checksheet cuối ca → group Zalo
- Quản lý chịu trách nhiệm huấn luyện luân phiên để họ tiến tới làm trưởng ca
- Mỗi người đều có mẫu "Nhật ký công việc" trong Google Sheet
"""
        },
        {
            "title": "✅ 3. Checksheet vệ sinh hằng ngày",
            "category": "checklist",
            "description": "Bảng kiểm tra vệ sinh chi tiết cho 3 ca làm việc",
            "content": """
# CHECKSHEET VỆ SINH HẰNG NGÀY – SABO BILLIARDS

| Khu vực / Thiết bị | Ca sáng | Ca chiều | Ca tối | Ghi chú |
|-------------------|---------|----------|--------|---------|
| Hút bụi sàn, bàn bida | ☐ | ☐ | ☐ | Vệ sinh máy hút sau khi thực hiện xong |
| Lau toàn bộ bàn bida | ☐ | ☐ | ☐ | Lau khô, không để sót bụi phấn |
| Lau & chùi gác cơ | ☐ | ☐ | ☐ | Gọn, sạch, không có vết nước |
| Lau bàn, ghế khu vực chơi | ☐ | ☐ | ☐ | Gọn gàng sạch sẽ |
| Lau dọn khu vực rửa ly, bếp | ☐ | ☐ | ☐ | Đổ rác, thay túi rác, dọn vỏ chai |
| Lau dọn khu vực toilet | ☐ | ☐ | ☐ | Lau sàn, gương, kiểm tra thùng rác |
| Vệ sinh bồn rửa, bồn cầu | ☐ | ☐ | ☐ | Dùng nước tẩy & bàn chải chuyên dụng |
| Lau dọn gọn gàng khu vực quầy | ☐ | ☐ | ☐ | Gọn gàng sạch sẽ |
| Lau dọn tủ lạnh | ☐ | ☐ | ☐ | Gọn gàng sạch sẽ |
| Check kho (nước, thực phẩm) | ☐ | ☐ | ☐ | Nắm số lượng và order |
| Check nước rửa tay, giấy vệ sinh | ☐ | ☐ | ☐ | Đảm bảo không thiếu cho khách |
| Xịt tinh dầu thơm không gian | ☐ | ☐ | ☐ | Mỗi ca xịt 1–2 lần khu vực chính |
| Vệ sinh cửa kính, cửa sổ lan can | ☐ | ☐ | ☐ | Sạch sẽ, bóng bẩy |
| Vệ sinh khu vực trước quán | ☐ | ☐ | ☐ | Giữ mặt tiền sạch sẽ, gọn gàng |
| Vệ sinh quạt | ☐ | ☐ | ☐ | Thực hiện 1 lần / tháng |

## 📌 Quy định thực hiện:
1. Hoàn thành → tích ✓ vào từng ô theo ca
2. Chụp hình gửi check sheet vào group Zalo để quản lý đối chiếu
3. Không hoàn thành phải ghi rõ lý do, người chịu trách nhiệm
"""
        },
        {
            "title": "📜 4. Nội quy & Văn hóa làm việc",
            "category": "policy",
            "description": "Quy định làm việc và tinh thần 5S của SABO Billiards",
            "content": """
# NỘI QUY & VĂN HÓA LÀM VIỆC – SABO BILLIARDS

## I. 🎯 TÔN CHỈ VẬN HÀNH

1. **Khách hàng là trung tâm**: Mỗi hành động đều hướng đến trải nghiệm của khách
2. **Tôn trọng – Gọn gàng – Kỷ luật**: Là nền tảng giữ sự chuyên nghiệp và lâu dài
3. **Tự chủ & Có trách nhiệm**: Làm đúng ngay cả khi không có ai giám sát

## II. 📌 NỘI QUY LÀM VIỆC

| Nội dung | Quy định bắt buộc |
|----------|-------------------|
| ⏰ Thời gian | Có mặt trước ca 10 phút. Đi trễ > 5 phút phải báo trước |
| 🧥 Trang phục | Đồng phục gọn gàng, sạch sẽ, lịch sự, đầu tóc gọn, mang giày hoặc dép quai hậu |
| 📵 Thiết bị cá nhân | Không sử dụng điện thoại trong giờ làm (trừ khi được giao việc) |
| 💬 Giao tiếp | Lịch sự – tôn trọng đồng nghiệp và khách. Không nói tục, đùa cợt quá đà |
| 🚭 Hút thuốc/ăn uống | Cấm hút thuốc trong khu khách. Không ăn uống trong khu vực phục vụ |
| 📋 Báo cáo – check ca | Gửi đầy đủ checksheet, ảnh vệ sinh trước khi bàn giao ca |
| 🔄 Thay ca / nghỉ phép | Báo trước ít nhất 24h, có người thay thế hoặc được duyệt |
| 💸 Tiền bạc – thu ngân | Không tự ý thu tiền, không "giữ hộ", không ứng tiền khách |

## III. 💡 VĂN HÓA LÀM VIỆC SABO – TINH THẦN 5 CHỮ "S"

| Chữ "S" | Ý nghĩa | Thực hành |
|---------|---------|-----------|
| **Sạch** | Không gian sạch – đầu óc sạch | Giữ bàn – sàn – toilet luôn sạch dù bận |
| **Sáng** | Biết nghĩ – chủ động – tự học | Không đợi nhắc – chủ động lau, dọn, phục vụ |
| **Sắc** | Giao tiếp rõ – thái độ chuyên nghiệp | Cười nhẹ, trả lời rõ, biết lắng nghe |
| **Sẵn** | Luôn trong tư thế phục vụ | Tay không cầm điện thoại – mắt quan sát khách |
| **Sống** | Làm việc như người sống cùng thương hiệu | Yêu nơi làm việc – nghĩ lâu dài – không "cho có" |

## IV. 📍 XỬ LÝ VI PHẠM & KHEN THƯỞNG

### Vi phạm

| Mức độ | Vi phạm | Hình thức xử lý |
|--------|---------|-----------------|
| Nhẹ | Quên vệ sinh, không chụp hình báo ca | Nhắc nhở – trừ điểm KPI |
| Trung bình | Đi trễ không lý do, cố ý không hoàn thành nhiệm vụ | Cảnh cáo, ghi vào bảng theo dõi |
| Nặng | Ẩu trong phục vụ, thu sai tiền, thái độ tệ với khách | Xem xét nghỉ việc |

### Khen thưởng

- Đạt KPI vệ sinh liên tục → +100K/tháng
- Khách feedback tốt → thưởng nóng
- Góp ý cải tiến → ghi nhận, tăng lương khi có thể
"""
        },
        {
            "title": "🔄 5. SOP Mở - Đóng ca",
            "category": "sop",
            "description": "Quy trình chuẩn mở và đóng ca hằng ngày",
            "content": """
# SOP MỞ – ĐÓNG CA (STANDARD OPERATING PROCEDURE)

## 🟢 MỞ CA (30 phút trước giờ mở cửa)

| Nhiệm vụ | Thực hiện bởi | Ghi chú |
|----------|---------------|---------|
| Xả phòng, bật quạt, mở cửa khử mùi | Quản lý | Tắt hết sau khi vệ sinh xong |
| Thực hiện các công việc vệ sinh | Quản lý | Hoàn thành checksheet |
| Kiểm tra tình trạng bàn giao ca tối | Quản lý | Chụp ảnh, báo cáo bất thường |
| Kiểm tra tiền mặt, kho, đối chiếu sổ | Quản lý | Xác nhận trên group |
| Chụp ảnh vệ sinh & gửi Zalo | Quản lý | Theo checklist ngày |

## 🔴 ĐÓNG CA (sau khách cuối cùng rời)

| Nhiệm vụ | Thực hiện bởi | Ghi chú |
|----------|---------------|---------|
| Lau lại bàn chơi + dọn rác | Trưởng ca | Gọn – không để sót cơ |
| Tắt thiết bị: đèn, quạt, máy lạnh, loa | Trưởng ca | Không nhảy bước, tắt cầu sau cùng |
| Kiểm tra kho | Trưởng ca | Đề xuất mua thêm nếu hết |
| Vệ sinh quầy, bồn rửa, bếp | Trưởng ca | Chụp ảnh bàn giao ca sáng |
| Đếm tiền mặt – đối chiếu doanh thu | Trưởng ca | Ghi sổ giao ca, nhập Google Sheet |
| Gửi báo cáo & ảnh về group Zalo | Trưởng ca | Trước 24h |
| Đóng tất cả cửa cẩn thận | Trưởng ca | Người đóng cửa chịu trách nhiệm bồi thường nếu mất mát |

## 📊 BÁO CÁO DOANH THU HẰNG NGÀY

**Mẫu tin nhắn gửi Group Zalo:**

```
Thứ 6: 16/05
- Doanh thu: [số tiền]
- Chuyển khoản: [số tiền]
- Tiền mặt: [số tiền]
```
"""
        },
        {
            "title": "👋 6. Hướng dẫn tiếp khách & Xử lý sự cố",
            "category": "customer-service",
            "description": "Quy trình tiếp khách chuẩn và cách xử lý các tình huống phát sinh",
            "content": """
# HƯỚNG DẪN TIẾP KHÁCH & XỬ LÝ SỰ CỐ

## ✅ Tiếp khách bài bản

| Tình huống | Thực hiện |
|------------|-----------|
| Khách mới bước vào | Chào khách lịch sự: "SABO xin chào anh/chị, mời mình vào bàn" |
| Khách chưa biết luật | Hướng dẫn ngắn gọn, đưa cơ – gợi ý combo chơi |
| Khách quen quay lại | Nhận diện – hỏi thăm – ưu tiên bàn tốt |
| Khách hỏi giá | Đưa bảng giá, giải thích minh bạch |

## ⚠️ Xử lý tình huống

| Vấn đề | Cách xử lý |
|--------|------------|
| Thắc mắc về giá cả | Đưa bảng giá, giải thích minh bạch |
| Khách nóng giận / cãi nhau | Mời ra nói riêng – giữ bình tĩnh – mời quản lý xử lý |
| Khách phản ánh dịch vụ | Ghi nhận – xin lỗi – báo quản lý – ưu tiên giải pháp nhẹ nhàng |
"""
        },
        {
            "title": "📈 7. KPI Nhân sự hằng tuần",
            "category": "kpi",
            "description": "Tiêu chí đánh giá hiệu suất làm việc của nhân viên",
            "content": """
# KPI NHÂN SỰ HẰNG TUẦN
*(Áp dụng cho 2 nhân viên phục vụ & quản lý)*

| Tiêu chí | Trọng số | Mức đánh giá |
|----------|----------|--------------|
| Vệ sinh đúng checklist | 30% | Hoàn thành đủ, không sai sót |
| Đúng giờ – có mặt đầy đủ | 20% | Không trễ – không vắng không phép |
| Giao tiếp – thái độ | 20% | Lịch sự, cởi mở, phục vụ có tâm |
| Báo cáo – hình ảnh – nhật ký | 20% | Gửi đầy đủ cuối ca |
| Đề xuất hoặc phản hồi tốt | 10% | Có ý tưởng cải tiến, góp ý thật |

**Tổng:** 100%
"""
        },
        {
            "title": "🗂️ 8. Hệ thống quản lý Chương trình - Sự kiện - Khuyến mãi",
            "category": "marketing",
            "description": "Phân loại và theo dõi các chương trình khuyến mãi, sự kiện",
            "content": """
# HỆ THỐNG QUẢN LÝ CHƯƠNG TRÌNH – SỰ KIỆN – KHUYẾN MÃI – DỊCH VỤ

## I. PHÂN LOẠI HOẠT ĐỘNG

| Mã | Loại hình | Mục đích chính |
|----|-----------|----------------|
| KM | Khuyến mãi giá giờ chơi | Tăng traffic khung giờ thấp |
| HV | Hội viên | Duy trì khách hàng trung thành |
| DV | Dịch vụ bổ sung | Tăng doanh thu trên mỗi khách |
| SK | Sự kiện – giải đấu | Tăng nhận diện – tương tác cộng đồng |
| QC | Quảng cáo – truyền thông | Thu hút khách mới |

## II. BẢNG THEO DÕI CHƯƠNG TRÌNH

| STT | Mã | Tên chương trình | Thời gian | Nội dung | Người PT | KPI | Ghi chú |
|-----|----|--------------------|-----------|----------|----------|-----|---------|
| 1 | KM001 | Giảm giá 18K/h đầu tiên | 13–19/5/2025 (T2–T6, 8–18h) | 18K giờ đầu, sau đó 48K. Min 2h | Quản lý + NV | ≥50 lượt/ngày | Đã in poster |
| 2 | HV001 | Gói hội viên 99K | Từ 15/5/2025 | Sáng 35K, chiều 45K, tối 55K | Quản lý | ≥30 đăng ký/tháng | Link QR |
| 3 | SK001 | Giải 9 Pool WTA Open | 17/5/2025 | 150K/slot, Winner Take All, 16 người | G. Danh | Đủ slot & livestream | FB livestream |
| 4 | DV001 | Dịch vụ nước | Từ 1/6/2025 | Thức uống đóng chai tại quầy | NV quầy | ≥20 chai/ngày | - |
| 5 | QC001 | Mini clip review | Hè 2025 | 1 clip 30–60s/tuần trên TikTok | NV truyền thông | ≥5 clip/tuần | Video cũ + mới |

## III. CÁCH VẬN HÀNH HỆ THỐNG

1. **Tạo biểu mẫu đăng ký & duyệt** (Google Form/Notion)
   - Nhân viên/quản lý đề xuất khuyến mãi/sự kiện điền form

2. **Lịch sự kiện tuần/tháng** (Google Calendar)
   - Gắn toàn bộ hoạt động, phân loại màu theo mã

3. **Bảng KPI theo dõi** (Excel/Notion)
   - Theo dõi lượt chơi, đăng ký, doanh thu, hiệu quả truyền thông

4. **Tổng kết – đánh giá hiệu quả mỗi tháng**
   - Giữ lại cái hiệu quả, tối ưu hoặc thay thế cái chưa tốt

## IV. QUY TRÌNH TRIỂN KHAI CHƯƠNG TRÌNH MỚI

1. Lên ý tưởng & mục tiêu
2. Viết mô tả ngắn (phổ biến cho nhân viên)
3. Thiết kế poster/bài post
4. Đưa vào lịch vận hành
5. Phân công người phụ trách
6. Gắn biểu mẫu đo hiệu quả (tracking)
7. Báo cáo sau chương trình
"""
        },
    ]
    
    # First, get or create an assistant for this company
    print("\n🤖 Getting AI Assistant...")
    assistant_result = supabase.table('ai_assistants').select('*').eq('company_id', company_id).execute()
    
    if assistant_result.data and len(assistant_result.data) > 0:
        assistant_id = assistant_result.data[0]['id']
        print(f"✅ Found existing assistant: {assistant_id}")
    else:
        # Create new assistant with correct schema
        new_assistant = supabase.table('ai_assistants').insert({
            "company_id": company_id,
            "name": "SABO Assistant",
            "instructions": "Bạn là trợ lý AI chuyên nghiệp giúp quản lý vận hành quán bida SABO Billiards.",
            "model": "gpt-4",
            "settings": {"auto_brainstorm": True, "language": "vi"},
            "is_active": True
        }).execute()
        assistant_id = new_assistant.data[0]['id']
        print(f"✅ Created new assistant: {assistant_id}")
    
    print(f"\n📄 Processing {len(documents)} documents from SABO operational manual...")
    
    success_count = 0
    for idx, doc in enumerate(documents, 1):
        try:
            # Insert into ai_uploaded_files table with correct column names
            supabase.table('ai_uploaded_files').insert({
                "assistant_id": assistant_id,
                "company_id": company_id,
                "file_name": f"{doc['title']}.md",
                "file_type": "text",
                "mime_type": "text/markdown",
                "file_size": len(doc["content"]),
                "storage_path": f"documents/{company_id}/{doc['category']}/{idx}.md",
                "processing_status": "completed",
                "extracted_text": doc["content"],
                "tags": [doc["category"], "operational-manual", "sabo"]
            }).execute()
            
            print(f"  ✅ {idx}. {doc['title']}")
            success_count += 1
            
        except Exception as e:
            print(f"  ❌ {idx}. Failed: {e}")
    
    print(f"\n🎉 Successfully added {success_count}/{len(documents)} documents!")
    print(f"🏢 Company: {company_name}")
    print(f"🆔 Company ID: {company_id}")
    print(f"\n📊 Document categories:")
    print(f"   - Tổ chức & Mô tả công việc")
    print(f"   - Phân công nhiệm vụ chi tiết")
    print(f"   - Checksheet vệ sinh")
    print(f"   - Nội quy & Văn hóa làm việc")
    print(f"   - SOP Mở - Đóng ca")
    print(f"   - Tiếp khách & Xử lý sự cố")
    print(f"   - KPI Nhân sự")
    print(f"   - Quản lý Chương trình/Sự kiện")
    print(f"\n💡 Next: AI sẽ phân tích tài liệu này để tự động:")
    print(f"   1. Tạo sơ đồ tổ chức (org chart)")
    print(f"   2. Gợi ý danh sách nhân viên cần tuyển")
    print(f"   3. Generate tasks từ checklist")
    print(f"   4. Thiết lập KPI tracking")
    print(f"   5. Lên lịch các chương trình khuyến mãi")

if __name__ == "__main__":
    add_sabo_documents()
