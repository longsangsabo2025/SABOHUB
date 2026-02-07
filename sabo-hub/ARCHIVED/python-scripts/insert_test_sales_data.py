"""
Insert TEST data for Sales Features
All test data has '[TEST]' prefix for easy identification and cleanup
"""
import os
import psycopg2
from datetime import datetime, timedelta
from dotenv import load_dotenv
from pathlib import Path
import json
import uuid

# Load env from sabohub-automation folder
env_path = Path(__file__).parent / "sabohub-automation" / ".env"
load_dotenv(env_path)

DATABASE_URL = os.getenv("DATABASE_URL")
print(f"Database URL: {DATABASE_URL[:50]}..." if DATABASE_URL else "Database URL not found")

def get_connection():
    return psycopg2.connect(DATABASE_URL)

def get_test_context():
    """Get company_id and employee_id for testing"""
    conn = get_connection()
    cur = conn.cursor()
    
    # Get first company
    cur.execute("SELECT id, name FROM companies LIMIT 1")
    company = cur.fetchone()
    if not company:
        print("❌ No companies found")
        cur.close()
        conn.close()
        return None, None
    company_id, company_name = company
    print(f"✅ Using company: {company_name}")
    
    # Get an employee from this company (sales role preferred)
    cur.execute("""
        SELECT id, full_name, role FROM employees 
        WHERE company_id = %s 
        ORDER BY CASE WHEN role = 'sales' THEN 0 ELSE 1 END
        LIMIT 1
    """, (company_id,))
    employee = cur.fetchone()
    if not employee:
        print("❌ No employees found")
        cur.close()
        conn.close()
        return str(company_id), None
    employee_id, emp_name, role = employee
    print(f"✅ Using employee: {emp_name} (role: {role})")
    
    cur.close()
    conn.close()
    return str(company_id), str(employee_id)

def insert_test_sales_targets(company_id, employee_id):
    """Insert test KPI targets"""
    print("\n📊 Inserting TEST sales_targets...")
    
    conn = get_connection()
    cur = conn.cursor()
    
    now = datetime.now()
    start_of_month = datetime(now.year, now.month, 1).date()
    if now.month == 12:
        end_of_month = (datetime(now.year + 1, 1, 1) - timedelta(days=1)).date()
    else:
        end_of_month = (datetime(now.year, now.month + 1, 1) - timedelta(days=1)).date()
    
    target_id = str(uuid.uuid4())
    
    cur.execute("""
        INSERT INTO sales_targets 
        (id, company_id, employee_id, period_type, period_start, period_end, 
         target_revenue, target_orders, target_visits, target_new_customers,
         actual_revenue, actual_orders, actual_visits, actual_new_customers, 
         status, notes, created_by)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id
    """, (
        target_id, company_id, employee_id, 'monthly', start_of_month, end_of_month,
        50000000, 30, 60, 5,  # targets
        32500000, 18, 42, 3,  # actuals (65% achieved)
        'active', '[TEST] Auto-generated test KPI for demo', employee_id
    ))
    
    result = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()
    
    if result:
        print(f"  ✅ Created sales target: {result[0]}")
        return result[0]
    return None

def insert_test_surveys(company_id, employee_id):
    """Insert test surveys with different question types"""
    print("\n📝 Inserting TEST surveys...")
    
    conn = get_connection()
    cur = conn.cursor()
    
    surveys = [
        {
            "title": "[TEST] Khảo sát chất lượng sản phẩm",
            "description": "Khảo sát mức độ hài lòng về sản phẩm",
            "survey_type": "customer_satisfaction",
            "questions": [
                {"id": "q1", "question": "Bạn đánh giá chất lượng sản phẩm như thế nào?", "type": "rating", "max_rating": 5, "required": True},
                {"id": "q2", "question": "Sản phẩm nào bạn thích nhất?", "type": "single_choice", "options": ["Nước ngọt", "Sữa", "Snack", "Bánh"], "required": True},
                {"id": "q3", "question": "Bạn đã từng gặp vấn đề với sản phẩm chưa?", "type": "yes_no", "required": False},
                {"id": "q4", "question": "Góp ý thêm", "type": "text", "multiline": True, "required": False}
            ],
            "target_responses": 50,
            "current_responses": 12
        },
        {
            "title": "[TEST] Khảo sát dịch vụ giao hàng",
            "description": "Đánh giá chất lượng giao hàng",
            "survey_type": "delivery_feedback",
            "questions": [
                {"id": "q1", "question": "Thời gian giao hàng có đúng hẹn không?", "type": "yes_no", "required": True},
                {"id": "q2", "question": "Đánh giá thái độ shipper", "type": "rating", "max_rating": 5, "required": True},
                {"id": "q3", "question": "Tình trạng hàng khi nhận", "type": "single_choice", "options": ["Tốt", "Bình thường", "Hư hỏng nhẹ", "Hư hỏng nặng"], "required": True}
            ],
            "target_responses": 30,
            "current_responses": 8
        }
    ]
    
    created_ids = []
    for survey in surveys:
        survey_id = str(uuid.uuid4())
        cur.execute("""
            INSERT INTO surveys 
            (id, company_id, title, description, survey_type, questions, 
             target_responses, current_responses, start_date, end_date, is_active, created_by)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            survey_id, company_id, survey['title'], survey['description'],
            survey['survey_type'], json.dumps(survey['questions']), 
            survey['target_responses'], survey['current_responses'],
            datetime.now().date(), (datetime.now() + timedelta(days=30)).date(), 
            True, employee_id
        ))
        result = cur.fetchone()
        if result:
            print(f"  ✅ Created survey: {survey['title']}")
            created_ids.append(result[0])
    
    conn.commit()
    cur.close()
    conn.close()
    
    return created_ids

def insert_test_competitor_reports(company_id, employee_id):
    """Insert test competitor reports"""
    print("\n🎯 Inserting TEST competitor_reports...")
    
    conn = get_connection()
    cur = conn.cursor()
    
    # Get a customer for the report
    cur.execute("SELECT id, name FROM customers WHERE company_id = %s LIMIT 1", (company_id,))
    customer = cur.fetchone()
    customer_id = str(customer[0]) if customer else None
    
    reports = [
        {
            "competitor_name": "[TEST] Coca-Cola",
            "competitor_brand": "Coca-Cola",
            "activity_type": "promotion",
            "estimated_impact": "high",
            "description": "[TEST] Đối thủ đang chạy KM mua 2 tặng 1 cho sản phẩm nước ngọt"
        },
        {
            "competitor_name": "[TEST] Pepsi",
            "competitor_brand": "Pepsi",
            "activity_type": "pricing",
            "estimated_impact": "medium",
            "description": "[TEST] Đối thủ giảm giá 10% cho đơn hàng trên 1 triệu"
        }
    ]
    
    for report in reports:
        report_id = str(uuid.uuid4())
        cur.execute("""
            INSERT INTO competitor_reports 
            (id, company_id, customer_id, reported_by, competitor_name, 
             competitor_brand, activity_type, estimated_impact, description, photos)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            report_id, company_id, customer_id, employee_id,
            report['competitor_name'], report['competitor_brand'], report['activity_type'],
            report['estimated_impact'], report['description'], []
        ))
        print(f"  ✅ Created competitor report: {report['competitor_name']}")
    
    conn.commit()
    cur.close()
    conn.close()

def insert_test_promotions(company_id, employee_id):
    """Insert test promotions"""
    print("\n🎁 Inserting TEST promotions...")
    
    conn = get_connection()
    cur = conn.cursor()
    
    # Get a user_id for created_by (FK references users table)
    cur.execute("SELECT id FROM users LIMIT 1")
    user = cur.fetchone()
    user_id = str(user[0]) if user else None
    
    if not user_id:
        print("  ⚠️ No users found, skipping promotions")
        cur.close()
        conn.close()
        return
    
    try:
        promo_id = str(uuid.uuid4())
        conditions = {"min_quantity": 10, "applicable_products": []}
        benefits = {"free_items": 1, "description": "Tặng 1 thùng cùng loại"}
        
        cur.execute("""
            INSERT INTO distributor_promotions 
            (id, company_id, code, name, description, promotion_type, 
             start_date, end_date, is_active, conditions, benefits, 
             max_uses, current_uses, created_by)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            promo_id, company_id, "TEST-BUY10GET1", "[TEST] Mua 10 tặng 1",
            "[TEST] Mua 10 thùng bất kỳ tặng 1 thùng cùng loại",
            "buy_x_get_y",
            datetime.now(), datetime.now() + timedelta(days=30), True,
            json.dumps(conditions), json.dumps(benefits), 100, 0, user_id
        ))
        print(f"  ✅ Created promotion: [TEST] Mua 10 tặng 1")
        
        # Second promotion
        promo_id2 = str(uuid.uuid4())
        conditions2 = {"min_order_value": 2000000}
        benefits2 = {"discount_percent": 5, "description": "Giảm 5% tổng đơn"}
        
        cur.execute("""
            INSERT INTO distributor_promotions 
            (id, company_id, code, name, description, promotion_type, 
             start_date, end_date, is_active, conditions, benefits, 
             max_uses, current_uses, created_by)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            promo_id2, company_id, "TEST-5OFF", "[TEST] Giảm 5% đơn trên 2 triệu",
            "[TEST] Giảm 5% cho đơn hàng từ 2 triệu trở lên",
            "order_discount",
            datetime.now(), datetime.now() + timedelta(days=15), True,
            json.dumps(conditions2), json.dumps(benefits2), 50, 5, user_id
        ))
        print(f"  ✅ Created promotion: [TEST] Giảm 5% đơn trên 2 triệu")
        
        conn.commit()
    except Exception as e:
        print(f"  ⚠️ Could not insert promotion: {e}")
        conn.rollback()
    
    cur.close()
    conn.close()

def clear_test_data():
    """Clear all test data with [TEST] prefix"""
    print("\n🧹 Clearing existing TEST data...")
    
    conn = get_connection()
    cur = conn.cursor()
    
    try:
        cur.execute("DELETE FROM sales_targets WHERE notes ILIKE '%[TEST]%'")
        print(f"  ✅ Cleared sales_targets: {cur.rowcount} rows")
    except Exception as e:
        print(f"  ⚠️ Error clearing sales_targets: {e}")
    
    try:
        cur.execute("DELETE FROM surveys WHERE title ILIKE '%[TEST]%'")
        print(f"  ✅ Cleared surveys: {cur.rowcount} rows")
    except Exception as e:
        print(f"  ⚠️ Error clearing surveys: {e}")
    
    try:
        cur.execute("DELETE FROM competitor_reports WHERE competitor_name ILIKE '%[TEST]%'")
        print(f"  ✅ Cleared competitor_reports: {cur.rowcount} rows")
    except Exception as e:
        print(f"  ⚠️ Error clearing competitor_reports: {e}")
    
    try:
        cur.execute("DELETE FROM distributor_promotions WHERE name ILIKE '%[TEST]%'")
        print(f"  ✅ Cleared distributor_promotions: {cur.rowcount} rows")
    except Exception as e:
        print(f"  ⚠️ Error clearing distributor_promotions: {e}")
    
    conn.commit()
    cur.close()
    conn.close()

if __name__ == "__main__":
    print("=" * 60)
    print("🧪 SALES FEATURES TEST DATA GENERATOR")
    print("=" * 60)
    
    company_id, employee_id = get_test_context()
    if not company_id or not employee_id:
        print("❌ Cannot proceed without company and employee")
        exit(1)
    
    # Clear old test data first
    clear_test_data()
    
    # Insert new test data
    insert_test_sales_targets(company_id, employee_id)
    insert_test_surveys(company_id, employee_id)
    insert_test_competitor_reports(company_id, employee_id)
    insert_test_promotions(company_id, employee_id)
    
    print("\n" + "=" * 60)
    print("✅ TEST DATA CREATED SUCCESSFULLY")
    print("=" * 60)
    print("\n📌 All test data has '[TEST]' prefix for easy cleanup")
    print("   Run this script again to refresh test data")
