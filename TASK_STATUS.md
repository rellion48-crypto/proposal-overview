# TASK_STATUS — 작업 현황

> 마지막 업데이트: 2026-09-01

---

## ✅ 완료된 작업 (Done)

- [x] AGENTS.md 프로젝트 총괄 지침서 작성 — 2026-09-01
- [x] .gitignore 및 .env.example 기본 셋업 — 2026-09-01
- [x] README.md 작성 및 GitHub 원격 저장소 연동 (첫 커밋) — 2026-09-01
- [x] 기본 메인화면 index.html 생성 (Hello World) — 2026-09-01
- [x] Vercel 배포 환경 연동 및 URL 등록 — 2026-09-01
- [x] 메인 인터페이스 index.html 구현 (RFP PDF 업로드존 + 회사 정보 및 문장형 역량 입력 폼 + 실시간 분석 프로그레스 + 1·2차 산출물 뷰어) — 2026-09-01
- [x] Supabase Google OAuth 연동 & 구글 로그인 시에만 메인 페이지 접근 가능하도록 인증 게이트웨이 구현 (미로그인 시 구글 로그인/회원가입 카드 표출) — 2026-09-01
- [x] Supabase 데이터베이스 (profiles, rfp_analyses) 및 Storage (rfp-documents) SQL 스키마 설계 및 파일 구성 — 2026-09-01
- [x] Gemini AI API 및 PDF.js 연동 (안전한 Vercel Serverless Function `/api/analyze` 기반 1·2차 산출물 실시간 AI 생성 및 Supabase DB 저장) — 2026-09-01
- [x] 작성자 성별, 직책 입력 필드 추가 및 회사 정보 전량 데이터베이스 수집 구현 — 2026-09-01
- [x] 분석 실행 전 개인정보 및 기업정보 수집·이용 동의 확인 절차 및 동의 이력(동의 여부, 동의 시각) 데이터 수집 구현 — 2026-09-01

---

## 🔄 진행 중인 작업 (In Progress)

- (없음)

---

## 📋 다음 작업 (Next)

- [ ] **[Phase 3]** 산출물 이메일 발송 자동화 (Resend / SendGrid 연동)
- [ ] **[Phase 3]** 결과물 PDF 다운로드 / 인쇄 포맷팅 지원
- [ ] **[Phase 4]** 분석 이력(내 제안서 목록) 조회 패널 구현

---

## 🐛 이슈 & 블로커 (Issues)

- **[해결 가이드] Google OAuth 400 에러 (`redirect_uri_mismatch`)**
  - **원인**: Google Cloud Console의 OAuth 클라이언트 ID 설정에 Supabase 콜백 URL(`https://skoyvgyutsdwcnwqpdnl.supabase.co/auth/v1/callback`)이 미등록됨.
  - **조치**: Google Cloud Console > 사용자 인증 정보 > 클라이언트 ID에서 '승인된 리디렉션 URI' 및 '승인된 자바스크립트 원본' 추가 필요.

---

## 📝 메모 (Notes)

- GitHub 원격 저장소: `https://github.com/rellion48-crypto/proposal-overview.git`
- **Vercel 배포 주소**: `https://proposal-overview-ruby.vercel.app/`
- **커밋 메시지 규칙**: 모든 커밋 메시지는 **한국어**로 작성할 것.
- 기본 `index.html` 파일 작성 완료. 향후 프레임워크(Next.js 등) 전환 여부 검토 가능.
