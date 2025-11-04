#!/usr/bin/env python3
"""
Script to add sample business documents for testing
"""

import psycopg2
from datetime import datetime, timedelta
import uuid

# Database connection
DB_CONNECTION = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def add_sample_documents():
    """Add sample business documents to database"""
    
    conn = psycopg2.connect(DB_CONNECTION)
    cur = conn.cursor()
    
    try:
        print("🚀 Adding sample business documents...")
        
        # Get first company
        cur.execute("SELECT id FROM companies LIMIT 1;")
        company_result = cur.fetchone()
        if not company_result:
            print("❌ No companies found! Please create a company first.")
            return
        
        company_id = company_result[0]
        print(f"✅ Using company: {company_id}")
        
        # Get first user as uploader
        cur.execute("SELECT id FROM users WHERE company_id = %s LIMIT 1;", (company_id,))
        user_result = cur.fetchone()
        if not user_result:
            print("❌ No users found! Please create a user first.")
            return
        
        user_id = user_result[0]
        print(f"✅ Using user: {user_id}")
        
        # Sample documents based on Vietnamese business law
        sample_docs = [
            {
                'type': 'businessLicense',
                'title': 'Giấy chứng nhận đăng ký kinh doanh',
                'document_number': 'GCNĐKKD-0123456789',
                'description': 'Giấy phép kinh doanh chính của công ty',
                'issue_date': '2023-01-15',
                'issued_by': 'Sở Kế hoạch và Đầu tư TP.HCM',
                'expiry_date': None,  # Vô thời hạn
                'is_verified': True,
                'status': 'active',
            },
            {
                'type': 'taxCode',
                'title': 'Giấy chứng nhận mã số thuế',
                'document_number': 'MST-0123456789',
                'description': 'Mã số thuế doanh nghiệp',
                'issue_date': '2023-01-20',
                'issued_by': 'Cục Thuế TP.HCM',
                'expiry_date': None,
                'is_verified': True,
                'status': 'active',
            },
            {
                'type': 'companyCharter',
                'title': 'Điều lệ công ty',
                'document_number': 'ĐL-2023-001',
                'description': 'Điều lệ công ty được phê duyệt',
                'issue_date': '2023-01-10',
                'issued_by': 'Đại hội cổ đông',
                'expiry_date': None,
                'is_verified': True,
                'status': 'active',
            },
            {
                'type': 'fireSafety',
                'title': 'Giấy chứng nhận PCCC',
                'document_number': 'PCCC-2024-HCM-12345',
                'description': 'Chứng nhận đủ điều kiện về phòng cháy chữa cháy',
                'issue_date': '2024-03-01',
                'issued_by': 'Cảnh sát PCCC TP.HCM',
                'expiry_date': (datetime.now() + timedelta(days=180)).strftime('%Y-%m-%d'),  # 6 tháng nữa
                'is_verified': True,
                'status': 'active',
            },
            {
                'type': 'foodSafety',
                'title': 'Giấy chứng nhận ATTP',
                'document_number': 'ATTP-HCM-2024-5678',
                'description': 'Giấy chứng nhận vệ sinh an toàn thực phẩm',
                'issue_date': '2024-01-15',
                'issued_by': 'Sở Y tế TP.HCM',
                'expiry_date': (datetime.now() + timedelta(days=45)).strftime('%Y-%m-%d'),  # Sắp hết hạn
                'is_verified': True,
                'status': 'active',
            },
            {
                'type': 'leaseContract',
                'title': 'Hợp đồng thuê mặt bằng văn phòng',
                'document_number': 'HĐTMB-2023-001',
                'description': 'Hợp đồng thuê văn phòng tầng 5, tòa nhà ABC',
                'issue_date': '2023-06-01',
                'issued_by': 'Công ty Bất động sản XYZ',
                'expiry_date': '2025-05-31',
                'is_verified': True,
                'status': 'active',
            },
            {
                'type': 'laborRegulation',
                'title': 'Nội quy lao động công ty',
                'document_number': 'NQLĐ-2023',
                'description': 'Nội quy lao động ban hành năm 2023',
                'issue_date': '2023-02-01',
                'issued_by': 'Ban Giám đốc',
                'expiry_date': None,
                'is_verified': True,
                'status': 'active',
            },
            {
                'type': 'salaryRegulation',
                'title': 'Quy chế trả lương và thưởng',
                'document_number': 'QCTL-2024',
                'description': 'Quy chế lương thưởng áp dụng từ 2024',
                'issue_date': '2024-01-01',
                'issued_by': 'Ban Giám đốc',
                'expiry_date': None,
                'is_verified': True,
                'status': 'active',
            },
            {
                'type': 'socialInsuranceRegistration',
                'title': 'Giấy đăng ký tham gia BHXH',
                'document_number': 'BHXH-HCM-123456',
                'description': 'Đăng ký tham gia bảo hiểm xã hội',
                'issue_date': '2023-02-01',
                'issued_by': 'BHXH TP.HCM',
                'expiry_date': None,
                'is_verified': True,
                'status': 'active',
            },
            {
                'type': 'environmentalLicense',
                'title': 'Giấy phép môi trường',
                'document_number': 'GPMT-2023-HCM-789',
                'description': 'Giấy phép bảo vệ môi trường',
                'issue_date': '2023-03-15',
                'issued_by': 'Sở Tài nguyên và Môi trường',
                'expiry_date': (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d'),  # Đã hết hạn
                'is_verified': True,
                'status': 'expired',
            },
        ]
        
        # Insert documents
        inserted_count = 0
        for doc in sample_docs:
            doc_id = str(uuid.uuid4())
            cur.execute("""
                INSERT INTO business_documents (
                    id, company_id, type, title, document_number,
                    description, issue_date, issued_by, expiry_date,
                    uploaded_by, is_verified, status, created_at, updated_at
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW()
                )
            """, (
                doc_id,
                company_id,
                doc['type'],
                doc['title'],
                doc['document_number'],
                doc['description'],
                doc['issue_date'],
                doc['issued_by'],
                doc['expiry_date'],
                user_id,
                doc['is_verified'],
                doc['status'],
            ))
            inserted_count += 1
            print(f"  ✅ Added: {doc['title']}")
        
        conn.commit()
        
        print(f"\n✅ Successfully added {inserted_count} business documents!")
        print(f"📊 Summary:")
        print(f"   - Tài liệu bắt buộc: 9 (Business license, Tax code, Charter, Fire safety, etc.)")
        print(f"   - Tài liệu hợp lệ: {inserted_count - 1}")
        print(f"   - Tài liệu hết hạn: 1 (Giấy phép môi trường)")
        print(f"   - Tài liệu sắp hết hạn: 1 (ATTP - còn 45 ngày)")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error: {e}")
        raise
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    add_sample_documents()
