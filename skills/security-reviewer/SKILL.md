---
name: security-reviewer
description: 安全漏洞檢測與修復專家。在撰寫處理用戶輸入、認證、API 端點、敏感資料或 AI agent/MCP 工具的程式碼後主動使用。檢測機密資料外洩、SSRF、注入攻擊、不安全加密，對照 OWASP Top 10:2025 與 OWASP Top 10 for Agentic Applications 2026。
source: everything-claude-code (MIT License)
original_author: affaan-m
updated: 2026-09-09
---

# Security Reviewer (安全審查)

## When to Use

在以下情況**主動**使用此 Skill：
- 實作認證或授權功能
- 處理用戶輸入或檔案上傳
- 建立新的 API 端點
- 處理機密資料或憑證
- 實作支付功能
- 整合第三方 API
- 處理金融/交易相關程式碼

## 安全檢查清單 (10 大類別)

### 1. 機密資料管理 (CRITICAL)

```typescript
// 禁止: 硬編碼機密資料
const apiKey = "sk-proj-xxxxx"  // 絕對禁止
const password = "admin123"     // 絕對禁止

// 正確: 使用環境變數
const apiKey = process.env.OPENAI_API_KEY
if (!apiKey) {
  throw new Error('OPENAI_API_KEY 未設定')
}
```

**檢查項目:**
- [ ] 無硬編碼 API keys、tokens、密碼
- [ ] 所有機密資料使用環境變數
- [ ] `.env.local` 已加入 .gitignore
- [ ] Git 歷史中無機密資料
- [ ] 生產環境機密存放於 Vercel/Render

### 2. 輸入驗證

```typescript
import { z } from 'zod'

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150)
})

export async function createUser(input: unknown) {
  const validated = CreateUserSchema.parse(input)
  return await db.users.create(validated)
}
```

**檢查項目:**
- [ ] 所有用戶輸入使用 Zod 驗證
- [ ] 檔案上傳限制 (大小、類型、副檔名)
- [ ] 錯誤訊息不洩露敏感資訊

### 3. SQL 注入防護 (CRITICAL)

```typescript
// 禁止: 字串串接 SQL
const query = `SELECT * FROM users WHERE email = '${userEmail}'`

// 正確: 參數化查詢
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('email', userEmail)
```

**檢查項目:**
- [ ] 所有資料庫查詢使用參數化查詢
- [ ] 無字串串接 SQL
- [ ] ORM/Query Builder 正確使用

### 4. 認證與授權

```typescript
// 正確: JWT Token 使用 httpOnly cookies
res.setHeader('Set-Cookie',
  `token=${token}; HttpOnly; Secure; SameSite=Strict; Max-Age=3600`)

// 正確: 授權檢查
export async function deleteUser(userId: string, requesterId: string) {
  const requester = await db.users.findUnique({ where: { id: requesterId } })
  if (requester.role !== 'admin') {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })
  }
  await db.users.delete({ where: { id: userId } })
}
```

**檢查項目:**
- [ ] Tokens 存放於 httpOnly cookies (非 localStorage)
- [ ] 敏感操作前驗證授權
- [ ] Supabase 啟用 Row Level Security
- [ ] 實作 RBAC

### 5. XSS 防護

```typescript
import DOMPurify from 'isomorphic-dompurify'

function renderUserContent(html: string) {
  const clean = DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'p'],
    ALLOWED_ATTR: []
  })
  return <div dangerouslySetInnerHTML={{ __html: clean }} />
}
```

**檢查項目:**
- [ ] 用戶提供的 HTML 已清理
- [ ] 設定 CSP 標頭
- [ ] 使用 React 內建的 XSS 防護

### 6. CSRF 防護

```typescript
// SameSite Cookies
res.setHeader('Set-Cookie',
  `session=${sessionId}; HttpOnly; Secure; SameSite=Strict`)
```

**檢查項目:**
- [ ] 狀態變更操作使用 CSRF tokens
- [ ] 所有 cookies 設定 SameSite=Strict

### 7. 速率限制

```typescript
import rateLimit from 'express-rate-limit'

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 分鐘
  max: 100, // 每視窗 100 請求
  message: '請求過多，請稍後再試'
})

app.use('/api/', limiter)
```

**檢查項目:**
- [ ] 所有 API 端點啟用速率限制
- [ ] 昂貴操作有更嚴格的限制

### 8. 敏感資料外洩

```typescript
// 禁止: 記錄敏感資料
console.log('User login:', { email, password })

// 正確: 清理日誌
console.log('User login:', {
  email: email.replace(/(?<=.).(?=.*@)/g, '*'),
  passwordProvided: !!password
})
```

**檢查項目:**
- [ ] 日誌中無密碼、tokens、機密資料
- [ ] 錯誤訊息對用戶是通用的
- [ ] 詳細錯誤僅在伺服器日誌

### 9. 區塊鏈安全 (Solana)

```typescript
// 驗證錢包簽名
import { verify } from '@solana/web3.js'

async function verifyWalletOwnership(publicKey: string, signature: string, message: string) {
  return verify(
    Buffer.from(message),
    Buffer.from(signature, 'base64'),
    Buffer.from(publicKey, 'base64')
  )
}
```

**檢查項目:**
- [ ] 錢包簽名已驗證
- [ ] 交易細節已驗證
- [ ] 交易前餘額檢查
- [ ] 無盲簽交易

### 10. 依賴安全

```bash
# 檢查漏洞
npm audit

# 自動修復
npm audit fix

# 更新依賴
npm update
```

**檢查項目:**
- [ ] 依賴保持最新
- [ ] npm audit 無已知漏洞
- [ ] lock 檔案已提交
- [ ] GitHub Dependabot 已啟用

## OWASP 對照

### OWASP Top 10:2025（最新正式版，2026-01 定稿）

相對 2021 版：SSRF 併入 A01；新增 A03 軟體供應鏈失效、A10 例外狀況處理不當；A02 設定錯誤升至第二。

| 代碼 | 分類 | 對應本清單 | 審查重點 |
|------|------|-----------|----------|
| A01 | Broken Access Control（含 SSRF） | 4 認證與授權、6 CSRF | 每個端點都有物件層授權；伺服器端發出的 URL 必須白名單 |
| A02 | Security Misconfiguration | 部署前檢查清單 | 安全標頭、CSP、預設帳密、除錯模式、CORS 範圍 |
| A03 | Software Supply Chain Failures | 10 依賴安全 | lockfile 提交、依賴來源可信、CI 動作版本 pinning |
| A04 | Cryptographic Failures | 1 機密資料管理、8 敏感資料外洩 | 演算法與金鑰長度、傳輸與靜態加密、勿自製加密 |
| A05 | Injection | 2 輸入驗證、3 SQL 注入、5 XSS | 參數化查詢、輸出編碼、命令列與模板注入 |
| A06 | Insecure Design | （設計階段） | 威脅建模、信任邊界、業務邏輯濫用情境 |
| A07 | Authentication Failures | 4 認證與授權、7 速率限制 | token 驗證完整（iss/aud/exp/alg）、暴力破解防護、session 固定 |
| A08 | Software or Data Integrity Failures | 10 依賴安全 | 反序列化來源、未簽章更新、CI/CD 產物完整性 |
| A09 | Security Logging and Alerting Failures | 緊急應變 | 關鍵事件有紀錄且可告警；log 不含機密 |
| A10 | Mishandling of Exceptional Conditions | 2 輸入驗證 | 錯誤路徑 fail-closed、例外不洩漏內部資訊、資源釋放 |

### OWASP Top 10 for Agentic Applications 2026（ASI，2025-12 發布）

審查 AI agent、MCP server、tool-calling、自動化 routine 相關程式碼時，額外對照本表。
來源：OWASP GenAI Security Project。

| 代碼 | 分類 | 審查重點 |
|------|------|----------|
| ASI01 | Agent Goal Hijack | 外部內容（網頁、文件、issue、commit message）視為資料而非指令；prompt injection 防線與工具輸出隔離 |
| ASI02 | Tool Misuse & Exploitation | 每個 tool 有明確參數 schema 與範圍限制；破壞性操作需確認；工具描述不可被外部內容改寫 |
| ASI03 | Identity & Privilege Abuse | agent 憑證最小權限、短效、可撤銷；勿把人類的長效 token 直接交給 agent；操作可歸因到觸發者 |
| ASI04 | Agentic Supply Chain Vulnerabilities | MCP server、plugin、skill、模型來源可信且 pinning；第三方 skill 進 repo 前掃描（本 repo 的 SkillSpector） |
| ASI05 | Unexpected Code Execution (RCE) | agent 產生的程式碼在沙箱執行；shell / eval / 檔案寫入範圍限制；禁止把模型輸出直接餵給直譯器 |
| ASI06 | Memory & Context Poisoning | 長期記憶與 RAG 來源有寫入控管；快照 / 狀態檔的內容視為不可信資料；記憶可清除與稽核 |
| ASI07 | Insecure Inter-Agent Communication | agent 之間訊息需驗證來源與完整性；不因訊息「來自另一個 agent」就提升信任 |
| ASI08 | Cascading Failures | 單一 agent 出錯不應連鎖擴散；有熔斷、重試上限、預算上限（token / 次數 / 費用） |
| ASI09 | Human-Agent Trust Exploitation | agent 輸出不得偽裝成人類決定或系統訊息；高風險動作留人類確認點 |
| ASI10 | Rogue Agents | 排程 / 常駐 agent 有停止開關、行為監控與異常告警；權限與範圍可隨時收回 |

**檢查項目（agent 程式碼）:**
- [ ] 外部輸入（工具結果、抓取內容、通知）標示為不可信並隔離
- [ ] 每個 tool 有 schema、範圍與破壞性操作確認
- [ ] agent 憑證最小權限且可撤銷；操作可追溯到觸發者
- [ ] 第三方 skill / MCP / plugin 來源可信並掃描
- [ ] 程式碼執行沙箱化；預算與重試上限；有緊急停止開關

## 安全審查報告格式

```markdown
# 安全審查報告

**檔案:** [path/to/file.ts]
**審查日期:** YYYY-MM-DD
**審查者:** security-reviewer

## 摘要

- **嚴重問題:** X
- **高風險問題:** Y
- **中風險問題:** Z
- **風險等級:** 高 / 中 / 低

## 嚴重問題 (立即修復)

### 1. [問題標題]
**嚴重程度:** CRITICAL
**類別:** SQL 注入 / XSS / 認證 / 等
**位置:** `file.ts:123`

**問題描述:**
[漏洞描述]

**影響:**
[被利用時的後果]

**修復方案:**
[安全實作範例]
```

## 部署前安全檢查清單

- [ ] **機密資料**: 無硬編碼，全部使用環境變數
- [ ] **輸入驗證**: 所有用戶輸入已驗證
- [ ] **SQL 注入**: 所有查詢已參數化
- [ ] **XSS**: 用戶內容已清理
- [ ] **CSRF**: 防護已啟用
- [ ] **認證**: 正確的 token 處理
- [ ] **授權**: 角色檢查已就位
- [ ] **速率限制**: 所有端點已啟用
- [ ] **HTTPS**: 生產環境強制
- [ ] **安全標頭**: CSP、X-Frame-Options 已設定
- [ ] **依賴**: 最新且無漏洞

## 緊急應變

發現 CRITICAL 漏洞時：

1. **記錄** - 建立詳細報告
2. **通知** - 立即警告專案負責人
3. **建議修復** - 提供安全程式碼範例
4. **測試修復** - 驗證修復有效
5. **輪換機密** - 如有外洩則更換

## 相關資源

- [OWASP Top 10:2025](https://owasp.org/Top10/2025/)
- [OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/)
- [OWASP Top 10 for LLM Applications 2025](https://genai.owasp.org/llm-top-10/)
- [Next.js 安全指南](https://nextjs.org/docs/security)
- [Supabase 安全指南](https://supabase.com/docs/guides/auth)
