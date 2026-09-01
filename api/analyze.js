// Vercel Serverless Function: /api/analyze
// Gemini API를 서버사이드에서 안전하게 호출하여 RFP 분석 및 제안서 가이드 생성

export default async function handler(req, res) {
  // CORS 헤더 설정
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { rfpText, companyInfo } = req.body || {};

    if (!rfpText || !companyInfo) {
      return res.status(400).json({ error: 'RFP 텍스트와 회사 정보가 필요합니다.' });
    }

    const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
    if (!GEMINI_API_KEY) {
      return res.status(500).json({ 
        error: '서버 환경변수에 GEMINI_API_KEY가 설정되지 않았습니다. Vercel 환경변수를 확인해주세요.' 
      });
    }

    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`;

    const prompt = `당신은 10년 경력의 공공입찰 및 정부지원사업 전문 제안서 수석 컨설턴트입니다.
아래 제공된 [RFP 원문 텍스트]와 [신청 기업 정보]를 정밀하게 분석하여 다음 2가지 산출물을 반드시 지정된 JSON 구조로 생성해주세요.

[신청 기업 정보]
- 회사명: ${companyInfo.name || ''}
- 주요 분야: ${companyInfo.domain || ''}
- 기업 핵심 역량 및 강점: ${companyInfo.narrative || ''}

[RFP 원문 텍스트 요약본]
${rfpText.substring(0, 25000)}

--------------------------------------------------
[응답 형식 규칙]
반드시 유효한 JSON 문자열만 응답하세요. 백틱(\`\`\`json)이나 추가 설명 없이 순수 JSON만 출력해야 합니다:
{
  "summaryReport": {
    "projectTitle": "공고/사업명",
    "overview": "사업 목표 및 핵심 요구사항 (3~5문장으로 요약)",
    "budgetAndPeriod": "총 사업 예산 및 수행 기간",
    "evaluationCriteria": [
      {
        "category": "평가 항목명 (예: 기술성 및 개발 역량)",
        "score": "40점",
        "keyPoints": "주요 평가 착안점 및 핵심 심사 기준 요약"
      }
    ],
    "deadlinesAndRequirements": [
      "제출 마감일 및 필수 제출 서류 목록",
      "필수 참여 자격 요건"
    ]
  },
  "proposalGuide": {
    "strategyOverview": "귀사 강점과 RFP 평가 배점을 매핑한 제안 전략 총평 (2~3문장)",
    "tableOfContents": [
      {
        "section": "제안서 목차 (예: I. 제안 개요 및 배경)",
        "mappingScore": "RFP 배점 매핑 (예: 기술성 40점 ★핵심)",
        "actionStrategy": "이 목차에서 귀사의 강점(보유기술, 핵심인력, 실적 등)을 어떻게 소구해야 하는지 구체적 가이드"
      }
    ],
    "consultantTip": "심사위원을 사로잡기 위한 원포인트 차별화 전략 조언"
  }
}`;

    const requestBody = {
      contents: [
        {
          role: 'user',
          parts: [{ text: prompt }]
        }
      ],
      generationConfig: {
        temperature: 0.2,
        topP: 0.95
      }
    };

    const aiRes = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody)
    });

    if (!aiRes.ok) {
      const errText = await aiRes.text();
      return res.status(aiRes.status).json({ error: `Gemini API 호출 실패: ${errText}` });
    }

    const aiData = await aiRes.json();
    const rawContent = aiData.candidates?.[0]?.content?.parts?.[0]?.text || '';
    const cleanJson = rawContent.replace(/```json/g, '').replace(/```/g, '').trim();
    const parsedData = JSON.parse(cleanJson);

    return res.status(200).json({ success: true, data: parsedData });

  } catch (error) {
    console.error('Serverless Function Error:', error);
    return res.status(500).json({ error: error.message || '서버 분석 처리 중 오류가 발생했습니다.' });
  }
}
