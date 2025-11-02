-- Marketing & Content Creator Schema

-- Media Library
CREATE TABLE IF NOT EXISTS media_library (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES users(id),
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL CHECK (file_type IN ('image', 'video')),
  file_size BIGINT NOT NULL,
  mime_type TEXT NOT NULL,
  folder TEXT DEFAULT 'general',
  width INTEGER,
  height INTEGER,
  duration INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_media_library_store ON media_library(store_id);
CREATE INDEX idx_media_library_folder ON media_library(store_id, folder);
CREATE INDEX idx_media_library_type ON media_library(store_id, file_type);

-- Post Templates
CREATE TABLE IF NOT EXISTS post_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  content TEXT NOT NULL,
  thumbnail_url TEXT,
  is_system BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_post_templates_store ON post_templates(store_id);
CREATE INDEX idx_post_templates_category ON post_templates(category);

-- Posts
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected', 'published', 'scheduled')),
  channels TEXT[] DEFAULT '{}',
  scheduled_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMPTZ,
  rejected_reason TEXT,
  template_id UUID REFERENCES post_templates(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_posts_store ON posts(store_id);
CREATE INDEX idx_posts_status ON posts(store_id, status);
CREATE INDEX idx_posts_created_by ON posts(created_by);
CREATE INDEX idx_posts_scheduled ON posts(scheduled_at) WHERE status = 'scheduled';

-- Post Media (junction table)
CREATE TABLE IF NOT EXISTS post_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  media_id UUID NOT NULL REFERENCES media_library(id) ON DELETE CASCADE,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_post_media_post ON post_media(post_id);
CREATE INDEX idx_post_media_media ON post_media(media_id);

-- Published Posts Log
CREATE TABLE IF NOT EXISTS published_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  channel TEXT NOT NULL,
  external_id TEXT,
  external_url TEXT,
  status TEXT NOT NULL CHECK (status IN ('success', 'failed')),
  error_message TEXT,
  published_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_published_posts_post ON published_posts(post_id);
CREATE INDEX idx_published_posts_channel ON published_posts(channel);

-- Social Media Accounts
CREATE TABLE IF NOT EXISTS social_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('facebook', 'instagram', 'sabo_arena')),
  account_name TEXT NOT NULL,
  account_id TEXT,
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, platform)
);

CREATE INDEX idx_social_accounts_store ON social_accounts(store_id);
CREATE INDEX idx_social_accounts_platform ON social_accounts(platform);

-- Insert default templates
INSERT INTO post_templates (name, description, category, content, is_system) VALUES
('Happy Hour', 'Khuyến mãi giờ vàng', 'promotion', '🎉 HAPPY HOUR - GIẢM GIÁ ĐẶC BIỆT! 🎉

⏰ Thời gian: [Thời gian]
💰 Ưu đãi: [Mô tả ưu đãi]
📍 Địa điểm: [Tên quán]

Nhanh tay đặt bàn ngay! ☎️ [SĐT]', TRUE),

('Sinh nhật', 'Khuyến mãi sinh nhật', 'promotion', '🎂 CHƯƠNG TRÌNH ƯU ĐÃI SINH NHẬT! 🎂

🎁 Giảm [X]% cho khách có sinh nhật trong tháng
🎈 Tặng kèm [Quà tặng]
📅 Áp dụng: [Thời gian]

Mang theo CMND để nhận ưu đãi nhé! 🎉', TRUE),

('Giải đấu', 'Thông báo giải đấu', 'event', '🏆 GIẢI ĐẤU BI-A [TÊN GIẢI] 🏆

📅 Thời gian: [Ngày giờ]
💰 Giải thưởng: [Giá trị giải]
👥 Số lượng: [Số người]
💵 Lệ phí: [Phí tham gia]

Đăng ký ngay: [Link/SĐT] 🎱', TRUE),

('Khai trương', 'Thông báo khai trương', 'event', '🎊 KHAI TRƯƠNG CHI NHÁNH MỚI! 🎊

📍 Địa chỉ: [Địa chỉ]
📅 Ngày: [Ngày khai trương]
🎁 Ưu đãi: [Khuyến mãi khai trương]

Hân hạnh được phục vụ quý khách! 🙏', TRUE),

('Bảo trì', 'Thông báo bảo trì', 'announcement', '⚠️ THÔNG BÁO BẢO TRÌ ⚠️

🔧 Nội dung: [Mô tả bảo trì]
⏰ Thời gian: [Thời gian bảo trì]
📍 Khu vực: [Khu vực ảnh hưởng]

Xin lỗi quý khách vì sự bất tiện này! 🙏', TRUE),

('Tuyển dụng', 'Thông báo tuyển dụng', 'recruitment', '💼 TUYỂN DỤNG NHÂN VIÊN 💼

📋 Vị trí: [Vị trí tuyển dụng]
👥 Số lượng: [Số lượng]
💰 Lương: [Mức lương]
📍 Làm việc tại: [Địa điểm]

Yêu cầu:
- [Yêu cầu 1]
- [Yêu cầu 2]

Liên hệ: [SĐT/Email] 📞', TRUE),

('Combo đặc biệt', 'Giới thiệu combo', 'promotion', '🍻 COMBO ĐẶC BIỆT - SIÊU TIẾT KIỆM! 🍻

📦 Combo bao gồm:
- [Item 1]
- [Item 2]
- [Item 3]

💰 Giá chỉ: [Giá] (Tiết kiệm [X]%)
⏰ Áp dụng: [Thời gian]

Đặt ngay kẻo lỡ! 🎯', TRUE),

('Thông báo nghỉ lễ', 'Thông báo lịch nghỉ lễ', 'announcement', '📢 THÔNG BÁO LỊCH LÀM VIỆC LỄ 📢

🎊 Dịp: [Tên lễ]
📅 Thời gian: [Thời gian nghỉ/làm việc]

Quán [Đóng cửa/Mở cửa] vào [Thời gian]

Chúc quý khách một kỳ nghỉ vui vẻ! 🎉', TRUE),

('Khách hàng thân thiết', 'Chương trình khách hàng thân thiết', 'promotion', '⭐ CHƯƠNG TRÌNH KHÁCH HÀNG THÂN THIẾT ⭐

🎁 Ưu đãi:
- Tích điểm mỗi lần chơi
- Đổi quà hấp dẫn
- Giảm giá đặc biệt

📱 Đăng ký ngay: [Link/SĐT]

Tri ân khách hàng - Ưu đãi bất tận! 💝', TRUE),

('Giới thiệu bàn mới', 'Giới thiệu bàn bi-a mới', 'announcement', '✨ RA MẮT BÀN BI-A MỚI! ✨

🎱 Loại bàn: [Loại bàn]
🌟 Đặc điểm: [Mô tả đặc điểm]
💰 Giá: [Giá chơi]

Trải nghiệm ngay hôm nay! 🎯', TRUE);

-- Enable RLS
ALTER TABLE media_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE published_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_accounts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for media_library
CREATE POLICY "Users can view media from their store"
  ON media_library FOR SELECT
  USING (store_id IN (SELECT store_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can upload media to their store"
  ON media_library FOR INSERT
  WITH CHECK (
    store_id IN (SELECT store_id FROM users WHERE id = auth.uid())
    AND uploaded_by = auth.uid()
  );

CREATE POLICY "Users can delete their own media"
  ON media_library FOR DELETE
  USING (uploaded_by = auth.uid());

-- RLS Policies for post_templates
CREATE POLICY "Users can view templates"
  ON post_templates FOR SELECT
  USING (is_system = TRUE OR store_id IN (SELECT store_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Managers can create templates"
  ON post_templates FOR INSERT
  WITH CHECK (
    store_id IN (
      SELECT u.store_id FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name IN ('CEO', 'Quản lý tổng', 'Trưởng ca')
    )
  );

-- RLS Policies for posts
CREATE POLICY "Users can view posts from their store"
  ON posts FOR SELECT
  USING (store_id IN (SELECT store_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can create posts"
  ON posts FOR INSERT
  WITH CHECK (
    store_id IN (SELECT store_id FROM users WHERE id = auth.uid())
    AND created_by = auth.uid()
  );

CREATE POLICY "Users can update their own posts"
  ON posts FOR UPDATE
  USING (created_by = auth.uid() OR store_id IN (
    SELECT u.store_id FROM users u
    JOIN roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name IN ('CEO', 'Quản lý tổng')
  ));

-- RLS Policies for post_media
CREATE POLICY "Users can view post media"
  ON post_media FOR SELECT
  USING (post_id IN (SELECT id FROM posts WHERE store_id IN (SELECT store_id FROM users WHERE id = auth.uid())));

CREATE POLICY "Users can manage post media"
  ON post_media FOR ALL
  USING (post_id IN (SELECT id FROM posts WHERE created_by = auth.uid()));

-- RLS Policies for published_posts
CREATE POLICY "Users can view published posts from their store"
  ON published_posts FOR SELECT
  USING (post_id IN (SELECT id FROM posts WHERE store_id IN (SELECT store_id FROM users WHERE id = auth.uid())));

-- RLS Policies for social_accounts
CREATE POLICY "Users can view social accounts from their store"
  ON social_accounts FOR SELECT
  USING (store_id IN (SELECT store_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Managers can manage social accounts"
  ON social_accounts FOR ALL
  USING (store_id IN (
    SELECT u.store_id FROM users u
    JOIN roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name IN ('CEO', 'Quản lý tổng')
  ));
