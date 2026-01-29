#!/usr/bin/env python3
"""
Quick script to add sample documents to SABO Billiards company
"""

import os
from datetime import datetime
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv('.env')

# Initialize Supabase client
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

def add_sample_documents():
    """Add sample documents for SABO Billiards"""
    
    print("🔍 Finding SABO Billiards company...")
    
    # Get SABO Billiards company
    company = supabase.table('companies').select('*').ilike('name', '%SABO%Billiards%').execute()
    
    if not company.data:
        print("❌ SABO Billiards company not found!")
        return
    
    company_id = company.data[0]['id']
    company_name = company.data[0]['name']
    print(f"✅ Found: {company_name} (ID: {company_id})")
    
    # Sample documents to add
    documents = [
        {
            "title": "📋 Quy trình vận hành cơ bản",
            "description": "Tài liệu hướng dẫn quy trình vận hành hàng ngày tại SABO Billiards",
            "content": """
# QUY TRÌNH VẬN HÀNH SABO BILLIARDS

## 1. Cơ cấu tổ chức
- CEO: Quản lý toàn bộ hoạt động
- Manager: Giám sát chi nhánh, quản lý nhân sự
- Shift Leader: Trực ca, giám sát nhân viên ca
- Staff: Phục vụ khách hàng, vệ sinh, thu ngân

## 2. Quy trình làm việc theo ca
### Ca sáng (8:00 - 16:00)
- 7:45: Họp ca, kiểm tra trang thiết bị
- 8:00: Mở cửa, sẵn sàng phục vụ
- 12:00: Nghỉ trưa theo lịch luân phiên
- 15:45: Bàn giao ca chiều

### Ca chiều (16:00 - 00:00)
- 15:45: Nhận ca, kiểm tra bàn bi-a
- 16:00: Tiếp tục phục vụ
- 23:30: Dọn dẹp, chuẩn bị đóng cửa
- 00:00: Khóa cửa, báo cáo doanh thu

## 3. KPI đánh giá
- Doanh thu/ca: Tối thiểu 5 triệu VNĐ
- Tỷ lệ bàn hoạt động: >70%
- Điểm phục vụ khách hàng: >8/10
- Số lượng khách quay lại: >60%

## 4. Công việc cần làm hàng ngày
- Vệ sinh bàn bi-a, thay vải nếu cần
- Kiểm tra và bảo dưỡng gậy, bi
- Cập nhật menu đồ uống
- Ghi nhận feedback khách hàng
- Báo cáo tình trạng thiết bị hư hỏng
            """,
            "category": "operations",
            "tags": ["quy-trình", "vận-hành", "hướng-dẫn"],
        },
        {
            "title": "📊 Mục tiêu KPI Q4/2025",
            "description": "Các chỉ tiêu KPI cần đạt được trong quý 4 năm 2025",
            "content": """
# MỤC TIÊU KPI Q4/2025 - SABO BILLIARDS

## Chỉ tiêu doanh thu
- Tháng 10: 450 triệu VNĐ
- Tháng 11: 500 triệu VNĐ
- Tháng 12: 600 triệu VNĐ
**Tổng Q4: 1,55 tỷ VNĐ**

## Chỉ tiêu khách hàng
- Số lượng khách mới: 200 người/tháng
- Khách hàng quay lại: 65%
- Điểm đánh giá trung bình: 4.5/5 sao

## Chỉ tiêu nhân sự
- Tỷ lệ hoàn thành KPI cá nhân: >80%
- Tỷ lệ chuyên cần: >95%
- Số giờ đào tạo: 8 giờ/người/tháng

## Chỉ tiêu vận hành
- Tỷ lệ bàn hoạt động: >75%
- Thời gian phục vụ trung bình: <5 phút
- Tỷ lệ thiết bị hư hỏng: <5%

## Khen thưởng
- Đạt 100% KPI: Thưởng 1 tháng lương
- Đạt 80-99% KPI: Thưởng 50% tháng lương
- Nhân viên xuất sắc tháng: 2 triệu VNĐ
            """,
            "category": "kpi",
            "tags": ["KPI", "mục-tiêu", "Q4-2025"],
        },
        {
            "title": "👥 Sơ đồ tổ chức hiện tại",
            "description": "Cơ cấu tổ chức và phân công nhiệm vụ",
            "content": """
# SƠ ĐỒ TỔ CHỨC SABO BILLIARDS

## Ban Lãnh đạo
**CEO - Tổng Giám đốc**
- Họ tên: [CEO Name]
- Email: sabobilliard2025@gmail.com
- Trách nhiệm: Chiến lược kinh doanh, mở rộng quy mô

## Ban Quản lý
**Manager - Giám đốc Chi nhánh**
- Họ tên: Ngọc Diễm
- Email: ngocdiem1112@gmail.com
- Trách nhiệm: Quản lý vận hành, nhân sự, tài chính chi nhánh

## Nhân viên vận hành (đang tuyển thêm)
**Shift Leader - Trưởng ca**
- Số lượng: 2 người (Ca sáng + Ca chiều)
- Trách nhiệm: Giám sát ca làm việc, xử lý sự cố

**Staff - Nhân viên phục vụ**
- Số lượng: 6-8 người
- Phân ca: 3-4 người/ca
- Trách nhiệm: Phục vụ khách, thu ngân, vệ sinh

## Kế hoạch mở rộng
- Q1/2026: Tuyển thêm 2 Shift Leaders
- Q2/2026: Tuyển thêm 4 Staff
- Q3/2026: Mở chi nhánh thứ 2
            """,
            "category": "organization",
            "tags": ["tổ-chức", "nhân-sự", "sơ-đồ"],
        },
        {
            "title": "📝 Quy định nội bộ",
            "description": "Các quy định về giờ giấc, trang phục, kỷ luật",
            "content": """
# QUY ĐỊNH NỘI BỘ SABO BILLIARDS

## 1. Giờ làm việc
- Ca sáng: 8:00 - 16:00
- Ca chiều: 16:00 - 00:00
- Đến muộn >15 phút: Trừ 200.000 VNĐ
- Nghỉ không phép: Trừ 1 ngày lương

## 2. Trang phục
- Đồng phục công ty (áo xanh logo SABO)
- Quần đen/xanh navy, giày thể thao sạch sẽ
- Badge tên, tóc gọn gàng
- Không được: quần jean rách, dép lê, trang sức quá mức

## 3. Hành vi cấm
- Sử dụng điện thoại quá 10 phút/ca
- Ăn uống trong khu vực làm việc
- Nói tục, cãi vã với khách hàng
- Trộm cắp, gian lận doanh thu
→ Vi phạm nghiêm trọng: SA THẢI NGAY

## 4. Khen thưởng
- Nhân viên của tháng: 2 triệu VNĐ
- Làm thêm giờ: 1.5x lương
- Giới thiệu nhân viên mới: 500.000 VNĐ

## 5. Nghỉ phép
- Nghỉ phép năm: 12 ngày/năm
- Nghỉ thai sản: Theo luật lao động
- Nghỉ ốm: Có xác nhận bệnh viện
- Đăng ký trước 3 ngày qua Manager
            """,
            "category": "policy",
            "tags": ["quy-định", "nội-quy", "kỷ-luật"],
        },
        {
            "title": "💰 Bảng lương và phúc lợi",
            "description": "Chi tiết về mức lương, thưởng, bảo hiểm",
            "content": """
# BẢNG LƯƠNG VÀ PHÚC LỢI

## Mức lương cơ bản (net)
- **Staff**: 6-8 triệu VNĐ/tháng
- **Shift Leader**: 10-12 triệu VNĐ/tháng
- **Manager**: 18-25 triệu VNĐ/tháng
- **CEO**: Theo thỏa thuận

## Thưởng hiệu suất
- Đạt 100% KPI: +1 tháng lương
- Đạt 80-99% KPI: +50% lương
- Nhân viên xuất sắc tháng: +2 triệu

## Phụ cấp
- Ăn ca: 50.000 VNĐ/ca
- Xăng xe: 30.000 VNĐ/ngày
- Điện thoại (Manager): 500.000 VNĐ/tháng

## Bảo hiểm
- BHXH, BHYT, BHTN: Theo luật
- Bảo hiểm tai nạn: 100 triệu/người

## Ngày lễ/Tết
- Lương x2: Tết Dương lịch, Giỗ Tổ
- Lương x3: Tết Âm lịch (3 ngày)
- Quà tết: 1-3 tháng lương (tùy thâm niên)

## Phúc lợi khác
- Đồng phục miễn phí: 3 bộ/năm
- Team building: 2 lần/năm
- Khám sức khỏe: 1 lần/năm
- Sinh nhật: Quà 500.000 VNĐ
            """,
            "category": "salary",
            "tags": ["lương", "thưởng", "phúc-lợi"],
        },
    ]
    
    print(f"\n📄 Adding {len(documents)} sample documents...")
    
    for idx, doc in enumerate(documents, 1):
        try:
            # Prepare document data
            doc_data = {
                "company_id": company_id,
                "title": doc["title"],
                "description": doc["description"],
                "content": doc["content"].strip(),
                "category": doc["category"],
                "tags": doc["tags"],
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat(),
            }
            
            # Insert into ai_uploaded_files table (reusing existing structure)
            result = supabase.table('ai_uploaded_files').insert({
                "company_id": company_id,
                "filename": f"{doc['title']}.md",
                "file_type": "text/markdown",
                "file_size": len(doc["content"]),
                "storage_path": f"documents/{company_id}/{doc['category']}/{idx}.md",
                "upload_status": "completed",
                "metadata": {
                    "category": doc["category"],
                    "tags": doc["tags"],
                    "description": doc["description"],
                    "content_preview": doc["content"][:200] + "..."
                }
            }).execute()
            
            print(f"  ✅ {idx}. {doc['title']}")
            
        except Exception as e:
            print(f"  ❌ {idx}. Failed: {e}")
    
    print(f"\n🎉 Done! Added documents to {company_name}")
    print(f"🔗 Company ID: {company_id}")
    print(f"\n💡 Next steps:")
    print(f"   1. View documents in AI Assistant tab")
    print(f"   2. AI will analyze these docs to suggest org structure, KPIs, tasks")
    print(f"   3. We'll integrate auto-brainstorming feature later")

if __name__ == "__main__":
    add_sample_documents()
