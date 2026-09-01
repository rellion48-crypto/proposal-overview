-- ==============================================================================
-- Proposal-overview : Supabase Database & Storage Setup Schema
-- 
-- 기능:
-- 1. 사용자 프로필(profiles) 테이블 및 구글 회원가입 시 자동 연동 트리거
-- 2. RFP 분석 및 제안서 가이드(rfp_analyses) 테이블
-- 3. Row Level Security (RLS) 보안 정책 (본인 데이터만 조회/수정/삭제)
-- 4. RFP PDF 파일 저장을 위한 Supabase Storage 버킷 생성 및 권한 설정
-- ==============================================================================

-- 1. 확장 기능 활성화 (UUID 생성 등)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. 사용자 프로필 테이블 (profiles)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    company_name TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- RLS 활성화
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles RLS 정책: 본인 프로필만 조회 및 수정 가능
CREATE POLICY "Users can view own profile" 
    ON public.profiles FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
    ON public.profiles FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
    ON public.profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- 구글 로그인(OAuth)으로 auth.users에 신규 가입 시 public.profiles에 자동 삽입 트리거
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', '')
    )
    ON CONFLICT (id) DO UPDATE
    SET 
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
        avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 트리거 바인딩 (auth.users)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ==============================================================================
-- 3. RFP 분석 및 제안서 가이드 요청 테이블 (rfp_analyses)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.rfp_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- 파일 정보
    file_name TEXT NOT NULL,
    file_url TEXT,
    file_size BIGINT,
    
    -- 사용자 및 기업 입력 정보
    company_name TEXT NOT NULL,
    user_email TEXT NOT NULL,
    company_domain TEXT DEFAULT 'it_saas',
    company_narrative TEXT NOT NULL,
    
    -- AI 분석 및 산출물 데이터 (JSONB 구조화)
    parsed_text TEXT,                       -- PDF 추출 원문 텍스트
    summary_report JSONB,                   -- 1차 산출물: 1~2페이지 요약, 평가기준, 배점 등
    proposal_guide JSONB,                   -- 2차 산출물: 맞춤형 제안서 목차 및 전략
    
    -- 처리 상태 및 이메일 발송 여부
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'parsing', 'analyzing', 'completed', 'failed')),
    error_message TEXT,
    email_sent BOOLEAN DEFAULT false,
    email_sent_at TIMESTAMPTZ,
    
    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- RLS 활성화
ALTER TABLE public.rfp_analyses ENABLE ROW LEVEL SECURITY;

-- rfp_analyses RLS 정책: 본인이 등록한 분석 요청만 조회/추가/수정/삭제 가능
CREATE POLICY "Users can view own rfp_analyses" 
    ON public.rfp_analyses FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own rfp_analyses" 
    ON public.rfp_analyses FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own rfp_analyses" 
    ON public.rfp_analyses FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own rfp_analyses" 
    ON public.rfp_analyses FOR DELETE 
    USING (auth.uid() = user_id);

-- 인덱스 추가 (조회 성능 최적화)
CREATE INDEX IF NOT EXISTS idx_rfp_analyses_user_id ON public.rfp_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_rfp_analyses_created_at ON public.rfp_analyses(created_at DESC);


-- ==============================================================================
-- 4. Supabase Storage 버킷 생성 및 RLS 정책 (rfp-documents)
-- ==============================================================================
-- 버킷 생성 (존재하지 않을 경우)
INSERT INTO storage.buckets (id, name, public)
VALUES ('rfp-documents', 'rfp-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Storage 버킷 RLS 정책: 로그인된 사용자가 자신의 폴더({user_id}/*)에만 업로드/조회/삭제 가능
CREATE POLICY "Users can upload own RFP documents"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'rfp-documents' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can view own RFP documents"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'rfp-documents' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can delete own RFP documents"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'rfp-documents' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
