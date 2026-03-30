import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123',
    sslmode='require'
)
cur = conn.cursor()

print('=== DAILY_WORK_REPORTS ===')
cur.execute('SELECT COUNT(*) FROM daily_work_reports')
print('Total reports:', cur.fetchone()[0])

cur.execute('''SELECT id, employee_id, branch_id, company_id, report_date, employee_name 
               FROM daily_work_reports 
               ORDER BY report_date DESC LIMIT 10''')
rows = cur.fetchall()
for r in rows:
    bid = str(r[2])[:8] if r[2] else 'None'
    cid = str(r[3])[:8] if r[3] else 'None'
    print(f'  {r[5]} | branch: {bid}... | company: {cid}... | date: {r[4]}')

print()
print('=== SABO COMPANY ===')
cur.execute("SELECT id, name FROM companies WHERE LOWER(name) LIKE '%sabo%' LIMIT 5")
rows = cur.fetchall()
sabo_company_ids = []
for r in rows:
    sabo_company_ids.append(r[0])
    print(f'  {r[1]} - {r[0]}')

print()
print('=== SABO EMPLOYEES ===')
if sabo_company_ids:
    cur.execute('''SELECT e.id, e.full_name, e.role, e.branch_id, e.company_id 
                   FROM employees e 
                   WHERE e.company_id = %s 
                   ORDER BY e.role, e.full_name
                   LIMIT 15''', (sabo_company_ids[0],))
    rows = cur.fetchall()
    for r in rows:
        bid = str(r[3])[:8] if r[3] else 'None'
        print(f'  [{r[2]}] {r[1]} | branch: {bid}...')

print()
print('=== SABO REPORTS ===')
if sabo_company_ids:
    cur.execute('''SELECT id, employee_name, branch_id, company_id, report_date 
                   FROM daily_work_reports 
                   WHERE company_id = %s 
                   ORDER BY report_date DESC
                   LIMIT 10''', (sabo_company_ids[0],))
    rows = cur.fetchall()
    if rows:
        for r in rows:
            bid = str(r[2])[:8] if r[2] else 'None'
            print(f'  {r[1]} | branch: {bid}... | date: {r[4]}')
    else:
        print('  No reports found for SABO company')

conn.close()
