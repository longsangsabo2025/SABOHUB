# 🚀 Hướng dẫn Deploy Toàn Diện (Render + Vercel)

Hệ thống của bạn gồm 2 phần:
1.  **Web App (Frontend)**: Chạy trên **Vercel**.
2.  **Telegram Bot (Backend)**: Chạy trên **Render**.

Code đã được đẩy lên GitHub. Bây giờ hãy thực hiện các bước sau:

## Phần 1: Deploy Bot lên Render (Backend)
*Dùng để chạy Bot Telegram 24/7*

1.  Vào [Render Dashboard](https://dashboard.render.com/).
2.  Chọn **New +** -> **Blueprints**.
3.  Kết nối với repo `sabohub-nexus`.
4.  Nhấn **Apply**.
5.  Vào phần **Environment** của service mới tạo, điền các biến môi trường từ file `.env`.

## Phần 2: Deploy Web App lên Vercel (Frontend)
*Dùng để chạy trang quản trị SABO Hub*

1.  Vào [Vercel Dashboard](https://vercel.com/dashboard).
2.  Chọn **Add New...** -> **Project**.
3.  Import repo `sabohub-nexus`.
4.  Trong phần **Environment Variables**, thêm các biến:
    - `VITE_SUPABASE_URL`
    - `VITE_SUPABASE_ANON_KEY`
5.  Nhấn **Deploy**.

---
**Lưu ý:**
- Bot trên Render sẽ tự động "ping" chính nó để không bị ngủ (nhờ cơ chế Health Check chúng ta đã thêm).
- Web App trên Vercel sẽ tự động cập nhật mỗi khi bạn push code lên GitHub.
