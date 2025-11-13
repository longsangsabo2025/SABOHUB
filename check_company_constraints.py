#!/usr/bin/env python3
"""
Check foreign key constraints that might prevent company deletion
"""

import os
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables
load_dotenv()

# Initialize Supabase client
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

def check_company_relationships():
    """Check all relationships that might prevent company deletion"""
    
    print("=" * 60)
    print("CHECKING COMPANY RELATIONSHIPS")
    print("=" * 60)
    
    # Get all companies
    companies_response = supabase.table('companies').select('*').execute()
    companies = companies_response.data
    
    print(f"\n✅ Found {len(companies)} companies:")
    for company in companies:
        print(f"\n📦 Company: {company['name']} (ID: {company['id']})")
        company_id = company['id']
        
        # Check employees (users table)
        users_response = supabase.table('users')\
            .select('id, full_name, email, role')\
            .eq('company_id', company_id)\
            .execute()
        print(f"   👥 Users: {len(users_response.data)}")
        for user in users_response.data:
            print(f"      - {user.get('full_name', 'NULL')} ({user.get('role', 'NULL')})")
        
        # Check employees table
        employees_response = supabase.table('employees')\
            .select('id, full_name, username, role')\
            .eq('company_id', company_id)\
            .execute()
        print(f"   👤 Employees: {len(employees_response.data)}")
        for emp in employees_response.data:
            print(f"      - {emp.get('full_name', 'NULL')} ({emp.get('role', 'NULL')})")
        
        # Check branches
        branches_response = supabase.table('branches')\
            .select('id, name')\
            .eq('company_id', company_id)\
            .execute()
        print(f"   🏢 Branches: {len(branches_response.data)}")
        for branch in branches_response.data:
            print(f"      - {branch.get('name', 'NULL')}")
        
        # Check tasks
        tasks_response = supabase.table('tasks')\
            .select('id, title')\
            .eq('company_id', company_id)\
            .execute()
        print(f"   📋 Tasks: {len(tasks_response.data)}")
        
        # Check business_documents
        docs_response = supabase.table('business_documents')\
            .select('id, document_number')\
            .eq('company_id', company_id)\
            .execute()
        print(f"   📄 Business Documents: {len(docs_response.data)}")
        
        # Check employee_documents
        emp_docs_response = supabase.table('employee_documents')\
            .select('id, document_number')\
            .eq('company_id', company_id)\
            .execute()
        print(f"   📝 Employee Documents: {len(emp_docs_response.data)}")
        
        # Check labor_contracts
        contracts_response = supabase.table('labor_contracts')\
            .select('id, contract_type')\
            .eq('company_id', company_id)\
            .execute()
        print(f"   📜 Labor Contracts: {len(contracts_response.data)}")
        
        print(f"\n    Total related records: {len(users_response.data) + len(employees_response.data) + len(branches_response.data) + len(tasks_response.data) + len(docs_response.data) + len(emp_docs_response.data) + len(contracts_response.data)}")

if __name__ == "__main__":
    check_company_relationships()
