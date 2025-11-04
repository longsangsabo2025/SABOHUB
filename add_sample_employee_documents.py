#!/usr/bin/env python3
"""
Script to add sample employee documents for testing
"""

import psycopg2
from datetime import datetime, timedelta
import uuid

# Database connection
DB_CONNECTION = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def add_sample_employee_documents():
    """Add sample employee documents and labor contracts"""
    
    conn = psycopg2.connect(DB_CONNECTION)
    cur = conn.cursor()
    
    try:
        print("🚀 Adding sample employee documents...")
        
        # Get first company
        cur.execute("SELECT id FROM companies LIMIT 1;")
        company_result = cur.fetchone()
        if not company_result:
            print("❌ No companies found!")
            return
        
        company_id = company_result[0]
        
        # Get employees from this company (any user in company)
        cur.execute("""
            SELECT id, full_name FROM users 
            WHERE company_id = %s
            LIMIT 3;
        """, (company_id,))
        employees = cur.fetchall()
        
        if not employees:
            print("❌ No users found in company!")
            return
        
        print(f"✅ Found {len(employees)} employees")
        
        # Get uploader (any user from company)
        cur.execute("SELECT id FROM users WHERE company_id = %s LIMIT 1;", (company_id,))
        uploader_id = cur.fetchone()[0]
        
        doc_count = 0
        contract_count = 0
        
        # Add documents for each employee
        for emp_id, emp_name in employees:
            print(f"\n📝 Adding documents for: {emp_name}")
            
            # Sample employee documents
            documents = [
                {
                    'type': 'identityCard',
                    'title': f'CCCD của {emp_name}',
                    'issue_date': '2022-01-15',
                    'expiry_date': (datetime.now() + timedelta(days=3650)).strftime('%Y-%m-%d'),  # 10 năm
                },
                {
                    'type': 'diploma',
                    'title': f'Bằng đại học của {emp_name}',
                    'issue_date': '2020-07-01',
                    'expiry_date': None,
                },
                {
                    'type': 'healthCertificate',
                    'title': f'Giấy khám sức khỏe {emp_name}',
                    'issue_date': '2024-01-10',
                    'expiry_date': (datetime.now() + timedelta(days=180)).strftime('%Y-%m-%d'),  # 6 tháng
                },
                {
                    'type': 'socialInsuranceBook',
                    'title': f'Sổ BHXH của {emp_name}',
                    'issue_date': '2023-03-01',
                    'expiry_date': None,
                },
            ]
            
            for doc in documents:
                doc_id = str(uuid.uuid4())
                cur.execute("""
                    INSERT INTO employee_documents (
                        id, employee_id, company_id, type, title,
                        issue_date, expiry_date, uploaded_by,
                        is_verified, status, created_at, updated_at
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW()
                    )
                """, (
                    doc_id, emp_id, company_id, doc['type'], doc['title'],
                    doc['issue_date'], doc['expiry_date'], uploader_id,
                    True, 'active'
                ))
                doc_count += 1
                print(f"  ✅ {doc['title']}")
            
            # Add labor contract
            contract_id = str(uuid.uuid4())
            cur.execute("""
                INSERT INTO labor_contracts (
                    id, employee_id, company_id, contract_type, contract_number,
                    position, department, start_date, end_date,
                    basic_salary, status, created_by, created_at, updated_at
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW()
                )
            """, (
                contract_id, emp_id, company_id, 'definite',
                f'HĐLĐ-2024-{str(uuid.uuid4())[:8].upper()}',
                'Nhân viên', 'Kinh doanh',
                '2024-01-01',
                (datetime.now() + timedelta(days=365)).strftime('%Y-%m-%d'),  # 1 năm
                15000000.00, 'active', uploader_id
            ))
            contract_count += 1
            print(f"  ✅ Hợp đồng lao động")
        
        conn.commit()
        
        print(f"\n✅ Successfully added:")
        print(f"   - {doc_count} employee documents")
        print(f"   - {contract_count} labor contracts")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error: {e}")
        raise
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    add_sample_employee_documents()
