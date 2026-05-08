-- ============================================================
-- 굿즈 쇼핑몰 초기 스키마
-- ============================================================

-- 상품 테이블
CREATE TABLE IF NOT EXISTS products (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  description TEXT,
  price       INT NOT NULL,
  image_emoji TEXT DEFAULT '🎁',
  stock       INT DEFAULT 99,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 주문 테이블
CREATE TABLE IF NOT EXISTS orders (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  toss_payment_key TEXT,
  toss_order_id    TEXT UNIQUE NOT NULL,
  amount           INT NOT NULL,
  status           TEXT DEFAULT 'paid',
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- 주문 상품 테이블
CREATE TABLE IF NOT EXISTS order_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id  UUID REFERENCES products(id),
  quantity    INT NOT NULL,
  unit_price  INT NOT NULL
);

-- ============================================================
-- RLS (Row Level Security)
-- ============================================================

-- products: 누구나 읽기 가능
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "products_public_read" ON products
  FOR SELECT USING (true);

-- orders: 본인 주문만 OR admin@admin.com
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "orders_read" ON orders
  FOR SELECT USING (auth.uid() = user_id OR auth.email() = 'admin@admin.com');
CREATE POLICY "orders_insert" ON orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- order_items: 연결된 order 소유자 OR admin
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "order_items_read" ON order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND (orders.user_id = auth.uid() OR auth.email() = 'admin@admin.com')
    )
  );
CREATE POLICY "order_items_insert" ON order_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- ============================================================
-- 샘플 상품 데이터
-- ============================================================
INSERT INTO products (name, description, price, image_emoji, stock) VALUES
  ('스티커 팩', '귀여운 캐릭터 스티커 10종 세트. 노트북, 다이어리에 딱!', 5000, '🎨', 100),
  ('에코백', '튼튼한 면 소재 에코백. 어깨에 편하게 멜 수 있어요.', 15000, '👜', 50),
  ('머그컵', '350ml 도자기 머그컵. 따뜻한 커피 한 잔과 함께.', 12000, '☕', 80),
  ('후드티', '따뜻하고 편안한 기모 후드티. S~XXL 사이즈 선택 가능.', 35000, '👕', 30);
