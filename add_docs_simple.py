#!/usr/bin/env python3
"""
Simple script to add SABO documents - only required fields
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv('.env')

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

def add_documents():
    # Get company
    company = supabase.table('companies').select('*').ilike('name', '%SABO%').execute()
    company_id = company.data[0]['id']
    print(f"✅ Company: {company.data[0]['name']}")
    
    # Get or create assistant
    assistant = supabase.table('ai_assistants').select('*').eq('company_id', company_id).limit(1).execute()
    if assistant.data:
        assistant_id = assistant.data[0]['id']
        print(f"✅ Assistant: {assistant_id}")
    else:
        print("❌ No assistant found - create one first")
        return
    
    # Full 8 documents from SABO operational manual
    docs = [
        {
            "title": "📋 1. Sơ đồ tổ chức & Mô tả công việc",
            "content": """# SƠ ĐỒ TỔ CHỨC & MÔ TẢ CÔNG VIỆC

## Sơ đồ tổ chức
Chủ quán → Quản lý tổng → Trưởng ca (Ca sáng/Ca tối) → Nhân viên phục vụ, Thu ngân, Kỹ thuật

## Vị trí cần tuyển:
- **Quản lý tổng** (1 người): Điều hành hoạt động toàn quán, phân ca, kiểm soát chi phí
- **Nhân viên phục vụ A** (hướng tới trưởng ca sáng): Vệ sinh mở quán, tiếp khách, quản lý khu bàn
- **Nhân viên phục vụ B** (hướng tới trưởng ca tối): Setup quán tối, tiếp khách, báo cáo cuối ca
"""
        },
        {
            "title": "✅ 2. Checksheet vệ sinh hằng ngày",
            "content": """# CHECKSHEET VỆ SINH HẰNG NGÀY

## Ca sáng (8:00 - 16:00):
☐ Hút bụi sàn, bàn bida
☐ Lau toàn bộ bàn bida (lau khô, không để sót bụi phấn)
☐ Lau & chùi gác cơ
☐ Lau bàn, ghế khu vực chơi
☐ Vệ sinh bồn rửa, bồn cầu
☐ Check kho (nước, thực phẩm)
☐ Xịt tinh dầu thơm không gian
☐ Vệ sinh khu vực trước quán

## Ca chiều (16:00 - 24:00):
☐ Lau dọn khu vực rửa ly, bếp
☐ Lau dọn khu vực toilet
☐ Lau dọn quầy, tủ lạnh
☐ Check nước rửa tay, giấy vệ sinh
☐ Vệ sinh cửa kính, cửa sổ

**Quy định:** Chụp hình gửi Zalo sau khi hoàn thành"""
        },
        {
            "title": "📜 3. Nội quy & Văn hóa 5S",
            "content": """# NỘI QUY & VĂN HÓA LÀM VIỆC

## Tinh thần 5S:
- **Sạch**: Không gian sạch – đầu óc sạch
- **Sáng**: Biết nghĩ – chủ động – tự học  
- **Sắc**: Giao tiếp rõ – thái độ chuyên nghiệp
- **Sẵn**: Luôn trong tư thế phục vụ
- **Sống**: Làm việc như người sống cùng thương hiệu

## Quy định:
⏰ Có mặt trước ca 10 phút
🧥 Mặc đồng phục gọn gàng
📵 Không dùng điện thoại trong giờ làm
💬 Lịch sự, không nói tục
🔄 Nghỉ phép báo trước 24h"""
        },
        {
            "title": "🔄 4. SOP Mở - Đóng ca",
            "content": """# SOP MỞ – ĐÓNG CA

## 🟢 MỞ CA (30 phút trước giờ):
1. Xả phòng, bật quạt, mở cửa khử mùi
2. Thực hiện vệ sinh theo checklist
3. Kiểm tra tình trạng bàn giao ca tối
4. Kiểm tra tiền mặt, kho, đối chiếu sổ
5. Chụp ảnh & gửi Zalo

## 🔴 ĐÓNG CA:
1. Lau lại bàn chơi + dọn rác
2. Tắt thiết bị: đèn, quạt, máy lạnh, loa
3. Kiểm tra kho
4. Vệ sinh quầy, bồn rửa, bếp
5. Đếm tiền – đối chiếu doanh thu
6. Gửi báo cáo & ảnh về Zalo (trước 24h)
7. Đóng tất cả cửa cẩn thận"""
        },
        {
            "title": "👋 5. Tiếp khách & Xử lý sự cố",
            "content": """# HƯỚNG DẪN TIẾP KHÁCH

## Tiếp khách chuẩn:
- Khách mới: "SABO xin chào anh/chị, mời mình vào bàn"
- Khách chưa biết luật: Hướng dẫn ngắn gọn, đưa cơ
- Khách quen: Nhận diện – hỏi thăm – ưu tiên bàn tốt
- Khách hỏi giá: Đưa bảng giá, giải thích minh bạch

## Xử lý sự cố:
⚠️ Khách nóng giận → Mời ra nói riêng, giữ bình tĩnh, gọi quản lý
⚠️ Khách phản ánh → Ghi nhận, xin lỗi, báo quản lý"""
        },
        {
            "title": "📈 6. KPI Nhân sự hằng tuần",
            "content": """# KPI NHÂN SỰ

| Tiêu chí | Trọng số | Mức đánh giá |
|----------|----------|--------------|
| Vệ sinh đúng checklist | 30% | Hoàn thành đủ, không sai sót |
| Đúng giờ – có mặt đầy đủ | 20% | Không trễ, không vắng |
| Giao tiếp – thái độ | 20% | Lịch sự, cởi mở, có tâm |
| Báo cáo – hình ảnh | 20% | Gửi đầy đủ cuối ca |
| Đề xuất cải tiến | 10% | Góp ý thật, ý tưởng hay |

**Thưởng:**
✅ Đạt KPI vệ sinh liên tục → +100K/tháng
✅ Khách feedback tốt → Thưởng nóng
✅ Góp ý cải tiến → Ghi nhận, tăng lương"""
        },
        {
            "title": "🗂️ 7. Quản lý Chương trình & Sự kiện",
            "content": """# HỆ THỐNG CHƯƠNG TRÌNH

## Phân loại:
- **KM**: Khuyến mãi giá giờ chơi
- **HV**: Hội viên  
- **DV**: Dịch vụ bổ sung
- **SK**: Sự kiện – giải đấu
- **QC**: Quảng cáo – truyền thông

## Chương trình hiện tại:
1. **KM001** - Giảm giá 18K/h đầu tiên (T2-T6, 8-18h)
2. **HV001** - Gói hội viên 99K (sáng 35K, chiều 45K, tối 55K)
3. **SK001** - Giải 9 Pool WTA Open (150K/slot, 16 người)
4. **DV001** - Dịch vụ nước đóng chai
5. **QC001** - Mini clip review TikTok (1 clip/tuần)"""
        },
        {
            "title": "💼 8. Phân công nhiệm vụ chi tiết",
            "content": """# PHÂN CÔNG NHIỆM VỤ

## 🧑‍💼 Quản lý tổng:
- Mở/đóng quán, kiểm tra thiết bị
- Phân ca, lập lịch nhân viên
- Quản lý tài chính, đối chiếu thu chi
- Đào tạo nhân viên mới
- Báo cáo chủ quán (tuần/tháng)

## 👕 Nhân viên phục vụ A (Ca sáng):
- Vệ sinh mở quán
- Tiếp khách, order nước
- Quản lý khu bàn, bấm giờ
- Bàn giao ca tối

## 👕 Nhân viên phục vụ B (Ca tối):  
- Vệ sinh đầu ca
- Setup quán buổi tối (đèn, ánh sáng)
- Giao tiếp, chăm sóc khách
- Báo cáo cuối ca, chụp ảnh"""
        }
    ]
    
    print(f"\n📄 Adding {len(docs)} documents...")
    
    for idx, doc in enumerate(docs, 1):
        try:
            result = supabase.table('ai_uploaded_files').insert({
                "assistant_id": assistant_id,
                "company_id": company_id,
                "file_name": f"{doc['title']}.md",
                "file_type": "text",
                "file_size": len(doc["content"]),
                "file_url": f"/documents/{company_id}/{idx}.md",
                "extracted_text": doc["content"],
                "status": "analyzed"
            }).execute()
            
            print(f"  ✅ {idx}. {doc['title']}")
        except Exception as e:
            print(f"  ❌ {idx}. Error: {e}")
    
    print("\n🎉 Done!")

if __name__ == "__main__":
    add_documents()
