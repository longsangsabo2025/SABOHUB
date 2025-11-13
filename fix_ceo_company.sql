-- TẠO COMPANY VÀ GÁN CHO CEO longsangsabo1@gmail.com

-- 1. Tạo company mới
INSERT INTO companies (id, name, business_type, address, phone, created_at)
VALUES (
  gen_random_uuid(),
  'Nhà hàng Sabo',
  'RESTAURANT',
  '123 Nguyễn Huệ, Quận 1, TP.HCM',
  '0901234567',
  NOW()
)
RETURNING id;

-- 2. Gán company_id cho CEO (copy ID từ bước 1 vào đây)
-- Thay <COMPANY_ID_VỪA_TẠO> bằng ID được trả về từ câu lệnh INSERT phía trên
UPDATE users 
SET company_id = '<COMPANY_ID_VỪA_TẠO>'
WHERE email = 'longsangsabo1@gmail.com';

-- Kiểm tra kết quả
SELECT id, email, company_id, role FROM users WHERE email = 'longsangsabo1@gmail.com';
