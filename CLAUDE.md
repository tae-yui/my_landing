# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

순수 정적 HTML/CSS/JS 프로젝트. 빌드 도구, 패키지 매니저, 프레임워크 없음. 모든 스타일과 스크립트는 각 HTML 파일 내 `<style>` / `<script>` 태그에 인라인으로 작성한다.

## Deployment

GitHub Pages로 배포됨.

- **Live URL**: https://tae-yui.github.io/my_landing/
- **Repository**: https://github.com/tae-yui/my_landing
- **배포 브랜치**: `main` 루트(`/`)
- push하면 자동 반영 (1~2분 소요)

로컬 미리보기는 브라우저에서 HTML 파일을 직접 열거나, 다음 명령으로 간이 서버 실행:

```bash
# Python이 있을 경우
python -m http.server 8080
```

## File Structure

```
vibecoding_web/
├── index.html              # 클로드코드 입문 강의 소개 페이지 (GitHub Pages 진입점)
├── landing.html            # 잔재미코딩 서베이 이벤트 랜딩페이지 (다크 네이비 테마)
├── ARCH.md                 # 쇼핑몰 세부 아키텍처 문서
├── shop/                   # 굿즈 쇼핑몰 (다크 모던 테마)
│   ├── index.html          # 상품 목록 + 장바구니
│   ├── auth.html           # 회원가입/로그인
│   ├── orders.html         # 내 결제 내역
│   ├── admin.html          # 관리자 전체 주문 내역
│   ├── success.html        # 결제 성공 처리
│   └── fail.html           # 결제 실패 처리
├── supabase/
│   ├── migrations/001_init.sql   # DB 스키마 + RLS
│   └── functions/confirm-payment/index.ts  # 토스 결제 확인 Edge Function
└── claude-landing-*/
    └── claude-landing/
        ├── event.html      # 잔재미코딩 이벤트 페이지 (라이트 오렌지 테마)
        └── ...
```

## Shop (쇼핑몰) 설정

**Supabase 프로젝트**: `bnkibfbpzdbccnqrysub` (ap-northeast-1 Tokyo)
- URL: `https://bnkibfbpzdbccnqrysub.supabase.co`
- 이메일 인증: 비활성화 (자동 확인)
- 관리자 계정: `admin@admin.com`

**토스페이먼츠**: 테스트 모드
- `shop/index.html`의 `TOSS_CLIENT_KEY` 변수에 `test_ck_...` 키 입력 필요
- Edge Function secret: `supabase secrets set TOSS_SECRET_KEY=test_sk_...`

**쇼핑몰 URL**: `https://tae-yui.github.io/my_landing/shop/`

## Design System

각 페이지는 독립적인 CSS 변수 세트를 가진다.

| 파일 | 테마 | 주요 컬러 |
|---|---|---|
| `index.html` | 라이트 퍼플 | `--brand: #7c3aed`, `--accent: #f59e0b` |
| `landing.html` | 다크 네이비 | `--navy: #0b1120`, `--orange: #f97316` |
| `event.html` | 라이트 오렌지 | `--brand: #f97316` |
| `shop/*.html` | 다크 모던 | `--primary: #6366f1`, `--success: #22c55e` |

**공통 패턴:**
- `--radius: 14px` (border-radius 기준값)
- `font-family: 'Segoe UI', system-ui, sans-serif`
- `clamp()` 함수로 반응형 폰트 크기
- `.reveal` 클래스 + `IntersectionObserver`로 스크롤 애니메이션 구현
- 모든 CTA 버튼은 페이지별 주 컬러로 통일
