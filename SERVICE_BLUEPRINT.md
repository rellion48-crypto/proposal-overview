# RFP 맞춤형 분석 & 제안서 작성 가이드 자동화 서비스 블루프린트 (Architecture Blueprint)

> **문서 버전**: v1.0  
> **기반 프로젝트**: Proposal-overview  
> **최종 목적**: RFP PDF 분석, 발주처 성향/맹점 수집, 기업 강점 매핑 기반의 1~2페이지 요약 및 제안 가이드 자동 생성·이메일 전달 시스템 구축  

---

## 1. 프로젝트 개요 (Executive Summary)

본 서비스는 입찰 및 정부지원사업에 참여하는 기업(스타트업 및 중소기업)을 위해 **RFP(제안요청서) PDF**를 분석하여 다음 핵심 산출물을 자동 생성하고 이메일로 전송하는 B2B 인텔리전스 자동화 솔루션이다.

1. **1차 산출물 (RFP 요약 & 발주 기관 인텔리전스 보고서)**:
   - RFP 핵심 요건, 정량적 제약 조건(예산, 일정, 자격).
   - 심사 배점표 분석 및 핵심 평가 포인트 도출.
   - 외부 웹 검색을 결합한 발주 기관의 중점 과제 및 탈락 방지 맹점(Trap) 분석.
   - 최적화된 표준 제안서 목차 구조 제안 (1~2페이지 분량 요약).
2. **2차 산출물 (맞춤형 제안서 작성 가이드)**:
   - 사용자가 입력한 회사 정보(핵심 역량, 기술 스택, 유사 실적 등)와 RFP 요구사항 1:1 매핑.
   - 섹션별 작성 전략 및 승리 전략(Winning Point) 제시.
   - 피해야 할 실수 및 차별화 포인트 가이드.

---

## 2. 전체 시스템 아키텍처 (System Architecture)

서버리스 환경의 실행 시간 제약(Timeout)과 대용량 PDF 처리 병목을 원천 차단하기 위해 **비동기 이벤트 기반 아키텍처(Asynchronous Event-Driven Architecture)**를 채택한다.

```
[사용자 브라우저 (Next.js App)]
        │
        ├─ 1. RFP PDF 업로드 + 회사 정보 입력
        ▼
[API Gateway (Next.js API Routes)]
        │
        ├─ 2. PDF 파일 저장 ───────────────▶ [Supabase Storage / AWS S3]
        ├─ 3. 분석 요청 레코드 생성 (PENDING) ─▶ [Supabase PostgreSQL]
        ├─ 4. 비동기 작업 발행 ─────────────▶ [Inngest / Upstash QStash]
        │
        ▼ (202 Accepted 즉시 반환)
[백그라운드 워커 파이프라인 (Worker Engine)] ◀── 작업 트리거
        │
        ├─ [Step 1: Ingestion & Parsing]
        │     └─ PyMuPDF / pdfjs-dist (텍스트, 표, 공고 메타데이터 추출)
        │     └─ Fallback: LlamaParse / Vision LLM
        │
        ├─ [Step 2: Agency Intelligence Gathering]
        │     └─ Tavily / SerpAPI (발주처 성향, 중점 과제, 과거 유사 사업 검색)
        │
        ├─ [Step 3: Dual LLM Chaining]
        │     ├─ Chain A (RFP 분석): 1차 요약, 배점 분석, 기관 맹점, 표준 목차
        │     └─ Chain B (전략 수립): 회사 정보 × RFP 매칭, 섹션별 작성 가이드
        │
        ├─ [Step 4: Persistence & Templating]
        │     ├─ Supabase DB에 상태(COMPLETED) 및 구조화 JSON 저장
        │     └─ React-Email / MJML 기반 반응형 HTML 렌더링
        │
        ▼
[트랜잭셔널 이메일 발송 엔진 (Resend / SendGrid)]
        │
        └─ 5. 사용자 이메일로 1차 요약 + 2차 작성 가이드 리포트 전송
```

---

## 3. 데이터 처리 및 AI 파이프라인 상세

```
[RFP PDF] ──▶ [텍스트/표 정제] ──▶ [기관 메타데이터] ──▶ [웹 인텔리전스 검색] ──┐
                                                                           ├─▶ [LLM 1차 분석] ──▶ 1차 요약 보고서
[회사 정보] ──────────────────────────────────────────────────────────────┴─▶ [LLM 2차 분석] ──▶ 2차 제안 가이드
                                                                                                    │
                                                                                                    ▼
                                                                                              [이메일 통합 발송]
```

### 3.1. Phase 1: PDF 수집 및 구조화 파싱 (Ingestion & Preprocessing)
* **메타데이터 자동 추출**: 정규식 및 경량 파서로 사업명, 공고번호, 발주기관명, 총 사업예산, 제안서 제출 마감일을 선별 추출.
* **본문 및 표 파싱**: `pdfjs-dist`를 활용하여 목차, 제안서 작성 지침, 평가 기준표 텍스트 추출.
* **문서 정제 & 필터링**: 무의미한 서식/행정 양식 제거, 본문 청킹(Chunking)을 통해 LLM 컨텍스트 크기 최적화.

### 3.2. Phase 2: 발주 기관 인텔리전스 검색 (Intelligence Gathering)
* **검색 쿼리 자동 생성**:
  - `"{발주기관명} {사업명} 과업 추진 배경"`
  - `"{발주기관명} 올해 주요 역점 사업 과제"`
  - `"{발주기관명} 입찰 제안서 평가 중점 착안사항"`
* **검색 API 연동**: Tavily API 또는 SerpAPI를 통해 신뢰도 높은 최신 보도자료 및 공공기관 공시 자료 상위 3~5건 추출.
* **컨텍스트 융합**: RFP 원문과 검색된 기관 동향 데이터를 결합하여 프롬프트에 주입.

### 3.3. Phase 3: 2단계 LLM 프롬프트 체이닝 (Prompt Chaining)

#### [Chain A] RFP 구조화 요약 및 맹점 도출
* **입력**: RFP 정제 텍스트 + 추출된 평가표 + 기관 검색 결과
* **역할**: 15년 경력 공공/민간 입찰 전문 수석 컨설턴트
* **산출물**:
  1. 사업 개요 및 핵심 요구사항 압축
  2. 평가 배점표 분석 및 정량/정성 집중 관리 항목
  3. 발주 기관 관점에서의 숨은 의도 및 실패하기 쉬운 치명적 맹점(Trap) 3가지
  4. 본 공고 맞춤형 제안서 표준 목차(TOC)

#### [Chain B] 맞춤형 제안서 작성 전략 가이드 수립
* **입력**: Chain A의 분석 결과 + 사용자가 입력한 회사 정보(회사명, 핵심 기술, 실적, 인력 풀)
* **역할**: 수주 전략 기획 전문가 (Bid Strategist)
* **산출물**:
  1. RFP 요구사항 vs 회사 강점 매핑 매트릭스 (1:1 Fit Analysis)
  2. 목차별 세부 작성 가이드라인 (스토리라인 구성법)
  3. 심사위원의 의구심을 해소할 증빙/실적 배치 전략
  4. 탈락 방지를 위한 주의사항 및 차별화 포인트

### 3.4. Phase 4: 이메일 템플릿 렌더링 및 발송
* React-Email을 사용하여 모바일 및 데스크톱 모두에서 가독성이 뛰어난 2페이지 분량의 반응형 HTML 템플릿 생성.
* 요약 보고서와 작성 가이드를 일목요연하게 섹션화하여 Resend API를 통해 전송.

---

## 4. 데이터베이스 스키마 설계 (PostgreSQL / Supabase)

```sql
-- 1. 분석 요청 마스터 테이블
CREATE TABLE analysis_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR(255) NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    company_info JSONB NOT NULL, 
    -- company_info 구조:
    -- {
    --   "established_year": 2021,
    --   "industry": "AI / SaaS",
    --   "core_competencies": ["LLM 파이프라인 구축", "실시간 데이터 처리"],
    --   "past_projects": ["공공기관 데이터 시각화", "금융권 문서 자동화"],
    --   "team_size": 12
    -- }
    rfp_file_url TEXT NOT NULL,
    rfp_file_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING', -- PENDING, PROCESSING, COMPLETED, FAILED
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 분석 결과 테이블
CREATE TABLE analysis_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES analysis_requests(id) ON DELETE CASCADE,
    parsed_metadata JSONB,   -- { client_org, budget, deadline, evaluation_table }
    external_intel JSONB,    -- { search_queries, gathered_insights }
    summary_report JSONB,    -- 1차 산출물: 핵심 요약, 평가 맹점, 표준 목차
    proposal_guide JSONB,    -- 2차 산출물: 기업 강점 매핑, 목차별 작성 전략
    email_sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_analysis_requests_status ON analysis_requests(status);
CREATE INDEX idx_analysis_requests_user_email ON analysis_requests(user_email);
CREATE INDEX idx_analysis_results_request_id ON analysis_results(request_id);
```

---

## 5. AI 인터페이스 스키마 (Structured Outputs)

LLM 응답의 파싱 오류를 방지하기 위해 OpenAI / Claude의 JSON Schema 강제 출력 기능을 적용한다.

### 5.1. 1차 분석 출력 스키마 (RFP Summary & Intel)
```json
{
  "project_overview": {
    "title": "공공 데이터 기반 지능형 플랫폼 구축 사업",
    "organization": "한국지능정보사회진흥원",
    "budget": "500,000,000원",
    "deadline": "2026-10-15 17:00"
  },
  "key_requirements": [
    "이기종 데이터 수집 및 정제 파이프라인 개발",
    "LLM 기반 질의응답 엔진 탑재",
    "공공 클라우드 보안 가이드라인 준수"
  ],
  "evaluation_criteria": [
    {
      "category": "기술 및 기능 능력",
      "weight": 60,
      "focus_point": "실시간 데이터 처리 엔진의 안정성 및 확장성 검증"
    },
    {
      "category": "사업 관리 및 지원",
      "weight": 20,
      "focus_point": "유지보수 체계 및 보안 침해 대응 프로세스"
    }
  ],
  "blind_spots_and_traps": [
    {
      "issue": "공공 클라우드 보안 인증(CSAP) 미충족 시 감점 위험",
      "cause": "발주처의 보안 컴플라이언스 엄격 적용 기조",
      "recommendation": "제안서 초반에 보안 인증 획득 현황 또는 파트너십 확약 명시 필수"
    }
  ],
  "recommended_toc": [
    {
      "chapter": "1. 제안 개요 및 사업 이해도",
      "subsections": ["1.1 추진 배경 및 목적", "1.2 발주처 정책 부합성 분석"]
    },
    {
      "chapter": "2. 기술 및 시스템 아키텍처",
      "subsections": ["2.1 파이프라인 구조도", "2.2 데이터 무결성 검증 방안"]
    }
  ]
}
```

### 5.2. 2차 분석 출력 스키마 (Proposal Strategy Guide)
```json
{
  "executive_summary": "당사의 실시간 데이터 처리 특화 역량을 전면에 배치하고, CSAP 인증 인프라 파트너십을 강조하여 발주처의 기술적 우려를 해소하는 수주 전략을 제안합니다.",
  "company_strength_mapping": [
    {
      "rfp_need": "대규모 실시간 데이터 정제 요구",
      "company_advantage": "금융권 유사 프로젝트 수행 이력 및 특허 파이프라인 보유",
      "proof_point": "A금융사 초당 1만 건 트랜잭션 처리 레퍼런스 제시"
    }
  ],
  "section_guides": [
    {
      "section_title": "1.2 발주처 정책 부합성 분석",
      "key_message": "발주 기관의 최근 3개년 중점 과제와 본 솔루션의 직접적 연계성 입증",
      "action_items": [
        "기관의 최신 보도자료 인용",
        "타사 대비 인프라 도입 비용 절감 수치 제시"
      ],
      "pitfalls_to_avoid": "단순 제품 소개로 흐르지 말고 발주처 KPI 달성 관점으로 서술할 것"
    }
  ],
  "differentiation_strategy": [
    "초기 구축 후 1년간 무상 모니터링 대시보드 지원 확약",
    "공공 레퍼런스 기반 정량적 성능 지표 전면 부각"
  ]
}
```

---

## 6. 비판적 기술 분석 및 리스크 대응 방안 (Critical Engineering Analysis)

| 영역 | 예상되는 병목 및 리스크 | 실무적 해결 방안 (Hardening) |
| :--- | :--- | :--- |
| **1. 서버리스 타임아웃** | Vercel 기본 Serverless Function 타임아웃(15초~60초) 내에서 PDF 파싱 + 웹 검색 + LLM 2회 순차 호출 시 100% 타임아웃 실패 발생. | **비동기 큐 도입**: 웹 요청 단계에서는 파일 업로드 및 DB `PENDING` 적재 후 `202 Accepted` 반환. 백그라운드 워커(Inngest 또는 Upstash QStash)에서 전체 파이프라인 비동기 실행. |
| **2. 비표준 공공기관 PDF 파싱 깨짐** | 국내 공공기관 RFP는 한글(HWP)에서 변환된 비표준 PDF가 많아 표 깨짐, 텍스트 누락, 인코딩 오류 빈번. | 1차 텍스트 파서 실패 또는 텍스트 밀도 부족 시 **LlamaParse API** 또는 **Vision LLM(PDF 페이지 이미지 렌더링 후 OCR)**으로 자동 Fallback. |
| **3. 토큰 폭증 및 Context Lost** | 100페이지가 넘는 RFP 전체를 프롬프트에 통째로 주입할 경우 토큰 비용 급증 및 핵심 요구사항 누락 발생. | **스마트 청킹 전처리**: 목차 탐색 정규식으로 '사업 개요', '과업 내용', '평가 기준' 섹션만 우선 슬라이싱하여 프롬프트에 주입. |
| **4. 이메일 스팸함 분류 및 렌더링 깨짐** | 복잡한 서식의 HTML 메일이 스팸으로 분류되거나 메일 클라이언트(아웃룩, 지메일 등)별로 스타일 깨짐 발생. | 도메인 SPF/DKIM/DMARC 설정 필수. 메일 본문은 핵심 요약만 담은 반응형 카드 UI로 구성하고, 전체 보고서는 웹 대시보드 링크 또는 첨부 PDF로 전달. |

---

## 7. 추천 기술 스택 (Production Stack)

| 레이어 | 선정 기술 | 선정 사유 |
| :--- | :--- | :--- |
| **Frontend** | Next.js 14 (App Router), Tailwind CSS, shadcn/ui | 빠른 UI 구축 및 반응형 대시보드 컴포넌트 생태계 |
| **Backend / API** | Next.js Route Handlers, TypeScript | 타입 안전성 및 프론트엔드-백엔드 스키마 공유 |
| **Async Worker / Queue** | Inngest / Upstash QStash | 서버리스 환경 최적화 비동기 백그라운드 큐 및 재시도(Retry) 보장 |
| **PDF Processing** | pdfjs-dist, PyMuPDF, LlamaParse | 비표준 PDF 파싱 대응 및 표 구조 보존 |
| **Web Search API** | Tavily API / SerpAPI | 발주 기관 성향 및 사업 배경 실시간 인텔리전스 수집 |
| **AI LLM API** | OpenAI GPT-4o / Claude 3.5 Sonnet | Structured Outputs 지원 및 복잡한 B2B 제안서 추론 역량 |
| **Database & Storage** | Supabase (PostgreSQL, Supabase Storage) | 완전 관리형 관계형 DB, RLS 보안, 파일 스토리지 통합 |
| **Email Service** | Resend + React-Email | 컴포넌트 기반 반응형 이메일 작성 및 높은 수신율 보장 |

---

## 8. 단계별 구현 로드맵 (Actionable Roadmap)

### Phase 1: 비동기 인프라 & PDF 파서 구축 (Week 1)
- [ ] Next.js 기반 업로드 및 회사 정보 입력 UI 구현
- [ ] Supabase DB 및 Storage 테이블/버킷 셋업
- [ ] Inngest / QStash 비동기 작업 큐 연결 및 202 Accepted 반환 파이프라인 구성
- [ ] PDF 텍스트 및 표 파싱 유틸리티 구현 (표 깨짐 방지 Fallback 로직 포함)

### Phase 2: 기관 검색 연동 & AI 프롬프트 체이닝 (Week 2)
- [ ] 발주 기관명/사업명 기반 Tavily 웹 검색 모듈 연동
- [ ] 1차 산출물(RFP 요약 & 맹점 도출) 프롬프트 작성 및 Structured Outputs 검증
- [ ] 2차 산출물(회사 강점 매핑 제안 가이드) 프롬프트 체이닝 구축
- [ ] 토큰 최적화 및 스마트 청킹 로직 고도화

### Phase 3: 이메일 템플릿 & 전달 시스템 (Week 3)
- [ ] React-Email 기반 반응형 1~2페이지 요약 리포트 템플릿 개발
- [ ] Resend API 연동 및 발송 성공/실패 로깅/재시도 체계 구축
- [ ] 웹 대시보드 결과 뷰어 페이지 구현

### Phase 4: 엔드투엔드 통합 & 프로덕션 배포 (Week 4)
- [ ] 50페이지 이상 실제 공공/민간 RFP 테스트 및 예외 처리 검증
- [ ] 도메인 이메일 인증(SPF, DKIM, DMARC) 설정
- [ ] Vercel 프로덕션 배포 및 모니터링 연동
