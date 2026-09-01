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

---

## 🔄 진행 중인 작업 (In Progress)

- (없음)

---

## 📋 다음 작업 (Next)

- [ ] **[Phase 1]** Next.js / API 백엔드 환경 및 프로젝트 셋업
- [ ] **[Phase 2]** 실제 PDF 업로드 & 파싱 모듈 개발 (`pdf-parse`)
- [ ] **[Phase 2]** Gemini AI API (`GEMINI_API_KEY`) 연동 (1차 요약 프롬프트 적용)
- [ ] **[Phase 2]** 프롬프트 엔지니어링 (rfp-summary, proposal-guide)
- [ ] **[Phase 3]** 제안서 작성 가이드 생성 로직 & 이메일 발송 연동 (Resend)

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
