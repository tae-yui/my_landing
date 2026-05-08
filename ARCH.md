# ARCH.md — 굿즈 쇼핑몰 아키텍처

## 전체 구성

```
브라우저 (GitHub Pages)
  └── shop/*.html  ──[Supabase JS SDK]──▶  Supabase
                                              ├── Auth (회원가입/로그인)
                                              ├── Database (products, orders, order_items)
                                              └── Edge Function (confirm-payment)
                                                        └──[TOSS_SECRET_KEY]──▶ 토스페이먼츠 API
```

---

## Supabase 프로젝트

| 항목 | 값 |
|------|-----|
| Project Ref | `bnkibfbpzdbccnqrysub` |
| Region | ap-northeast-1 (Tokyo) |
| URL | `https://bnkibfbpzdbccnqrysub.supabase.co` |
| 이메일 인증 | 비활성화 (mailer_autoconfirm: true) |
| 관리자 계정 | admin@admin.com / superadmin |

---

## DB 스키마

### products
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | 자동 생성 |
| name | TEXT | 상품명 |
| description | TEXT | 상품 설명 |
| price | INT | 가격 (원) |
| image_emoji | TEXT | 상품 대표 이모지 |
| stock | INT | 재고 (0 = 품절) |
| created_at | TIMESTAMPTZ | 등록일 |

### orders
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | 자동 생성 |
| user_id | UUID FK | auth.users 참조 |
| toss_payment_key | TEXT | 토스 paymentKey |
| toss_order_id | TEXT UNIQUE | 토스 orderId (중복 방지) |
| amount | INT | 결제 금액 |
| status | TEXT | paid / failed / cancelled |
| created_at | TIMESTAMPTZ | 주문 일시 |

### order_items
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | 자동 생성 |
| order_id | UUID FK | orders 참조 |
| product_id | UUID FK | products 참조 |
| quantity | INT | 수량 |
| unit_price | INT | 결제 시점 단가 |

---

## RLS (Row Level Security) 정책

### products
- `products_public_read`: 누구나 SELECT 가능

### orders
- `orders_read`: `auth.uid() = user_id` OR `auth.email() = 'admin@admin.com'`
- `orders_insert`: `auth.uid() = user_id`

### order_items
- `order_items_read`: 연결된 order의 소유자 OR admin
- `order_items_insert`: 연결된 order의 소유자

---

## 결제 플로우 (시퀀스)

```
사용자                 shop/index.html           Toss Payments          Edge Function (Supabase)
  │                          │                        │                          │
  ├─ 장바구니 담기 ──────────▶│                        │                          │
  ├─ "결제하기" 클릭 ─────────▶│                        │                          │
  │                          ├─ sessionStorage 저장    │                          │
  │                          ├─ orderId 생성           │                          │
  │                          ├─ requestPayment() ─────▶│                          │
  │                          │                        ├─ 결제창 표시              │
  │◀─ 결제 진행 ─────────────▶│                        │                          │
  │                          │                        ├─ success.html redirect   │
  │                  success.html                     │                          │
  │                          ├─ URL 파라미터 파싱      │                          │
  │                          ├─ POST /confirm-payment ─────────────────────────▶│
  │                          │                        │                          ├─ JWT 검증
  │                          │                        │                          ├─ Toss API confirm
  │                          │                        │                          ├─ DB INSERT orders
  │                          │                        │                          ├─ DB INSERT order_items
  │                          │◀─ {success: true} ──────────────────────────────│
  │                          ├─ cart 삭제              │                          │
  │◀─ 완료 UI ───────────────│                        │                          │
```

---

## Edge Function: confirm-payment

**경로**: `supabase/functions/confirm-payment/index.ts`

**요청 형식**:
```
POST https://bnkibfbpzdbccnqrysub.supabase.co/functions/v1/confirm-payment
Authorization: Bearer <supabase_jwt>
Content-Type: application/json

{
  "paymentKey": "...",
  "orderId": "...",
  "amount": 15000,
  "items": [
    { "product_id": "uuid", "quantity": 2, "unit_price": 5000 }
  ]
}
```

**응답**:
```json
{ "success": true, "orderId": "uuid" }
```

**환경변수**:
| 변수 | 설명 | 설정 방법 |
|------|------|-----------|
| `SUPABASE_URL` | 자동 주입 | - |
| `SUPABASE_ANON_KEY` | 자동 주입 | - |
| `SUPABASE_SERVICE_ROLE_KEY` | 자동 주입 | - |
| `TOSS_SECRET_KEY` | 토스 시크릿 키 | `supabase secrets set TOSS_SECRET_KEY=test_sk_...` |

---

## 페이지 URL 구조

| 페이지 | 로컬 URL | 배포 URL |
|--------|----------|----------|
| 상품 목록 | `localhost:8080/shop/` | `tae-yui.github.io/my_landing/shop/` |
| 로그인 | `localhost:8080/shop/auth.html` | `.../shop/auth.html` |
| 내 주문 | `localhost:8080/shop/orders.html` | `.../shop/orders.html` |
| 관리자 | `localhost:8080/shop/admin.html` | `.../shop/admin.html` |
| 결제 성공 | `localhost:8080/shop/success.html` | `.../shop/success.html` |
| 결제 실패 | `localhost:8080/shop/fail.html` | `.../shop/fail.html` |

---

## 로컬 개발 세팅

```bash
# 1. 로컬 서버 실행
python -m http.server 8080

# 2. 브라우저에서 접속
# http://localhost:8080/shop/

# 3. 상품 데이터 확인 (Supabase Dashboard)
# https://supabase.com/dashboard/project/bnkibfbpzdbccnqrysub/editor

# 4. Edge Function 배포 (코드 변경 시)
supabase functions deploy confirm-payment --no-verify-jwt

# 5. 토스 시크릿 키 설정
supabase secrets set TOSS_SECRET_KEY=test_sk_...
```

---

## 보안 고려사항

- **토스 시크릿 키**: Edge Function secrets에만 저장. 클라이언트 코드에 절대 노출 금지.
- **서비스 롤 키**: Edge Function 내부에서만 사용 (자동 주입). HTML에 포함 금지.
- **Anon 키**: 공개 가능. HTML에 포함해도 무방. RLS가 데이터 접근을 제어함.
- **RLS**: 모든 테이블에 활성화. admin 접근은 `auth.email() = 'admin@admin.com'` 조건으로 제어.
- **관리자 프론트 보호**: `session.user.email !== 'admin@admin.com'` 시 리다이렉트.
  → 실제 데이터 보호는 RLS가 담당 (프론트 우회 시에도 DB 접근 불가).
