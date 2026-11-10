---
name: fastapi-patterns
description: FastAPI + SQLModel + Neon PostgreSQL 後端開發最佳實踐。適用於 Render 或 Vercel 部署的 API 服務。涵蓋路由設計、資料庫操作、錯誤處理、認證授權與兩種部署方式。
source: custom
updated: 2026-11-09
---

# FastAPI + SQLModel 後端開發規範

## 適用場景

- Render 或 Vercel 部署的 API 服務
- 搭配 Neon PostgreSQL
- RESTful API 設計
- MES/ERP 後端服務

## 專案結構

```
project/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI 應用入口
│   ├── config.py            # 環境設定
│   ├── database.py          # 資料庫連線
│   ├── dependencies.py      # 共用依賴
│   ├── models/              # SQLModel 資料模型
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── work_order.py
│   │   └── user.py
│   ├── schemas/             # Pydantic 請求/回應 schema
│   │   ├── __init__.py
│   │   ├── base.py
│   │   └── work_order.py
│   ├── routers/             # API 路由
│   │   ├── __init__.py
│   │   ├── work_orders.py
│   │   └── users.py
│   ├── services/            # 業務邏輯
│   │   ├── __init__.py
│   │   └── work_order_service.py
│   └── utils/               # 工具函數
│       ├── __init__.py
│       └── audit.py
├── requirements.txt
├── render.yaml
└── .env.example
```

## 核心設定

### config.py

```python
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # 資料庫
    database_url: str

    # API
    api_prefix: str = "/api"
    debug: bool = False

    # 認證（Logto 簽發的 access token，用 JWKS 公鑰驗證，後端不保管簽章密鑰）
    logto_endpoint: str        # 例：https://your-tenant.logto.app
    logto_api_resource: str    # 在 Logto Console 註冊的 API resource indicator，對應 token 的 aud
    # 只列非對稱演算法。Logto 預設用 EC 金鑰（ES384），可在 Console 換成 RSA（RS256）
    jwt_algorithms: list[str] = ["ES384", "RS256"]

    # CORS：明列前端來源，沒有預設值，漏設就啟動失敗
    # 環境變數寫 JSON 陣列：CORS_ORIGINS='["https://app.example.com"]'
    cors_origins: list[str]

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

### database.py

```python
from sqlmodel import SQLModel, create_engine, Session
from app.config import get_settings

settings = get_settings()

# Neon PostgreSQL 連線
engine = create_engine(
    settings.database_url,
    echo=settings.debug,
    pool_pre_ping=True,  # 連線健康檢查
    pool_recycle=300,    # 5 分鐘回收連線
)


def init_db():
    """建立所有資料表"""
    SQLModel.metadata.create_all(engine)


def get_session():
    """取得資料庫 session（依賴注入用）"""
    with Session(engine) as session:
        yield session
```

### main.py

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.config import get_settings
from app.database import init_db
from app.routers import work_orders, users

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 啟動時
    init_db()
    yield
    # 關閉時（清理資源）


app = FastAPI(
    title="MES API",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,  # 明列來源，不用 ["*"]
    allow_credentials=False,              # token 走 Authorization header，不需要跨站帶 cookie
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

# 路由
app.include_router(work_orders.router, prefix=f"{settings.api_prefix}/work-orders", tags=["工單"])
app.include_router(users.router, prefix=f"{settings.api_prefix}/users", tags=["使用者"])


@app.get("/health")
def health_check():
    """健康檢查（Render 用）"""
    return {"status": "ok"}
```

## 資料模型 (SQLModel)

### models/base.py

```python
from sqlmodel import SQLModel, Field
from datetime import datetime
from typing import Optional
import uuid


class BaseModel(SQLModel):
    """基礎模型"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default=None)

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
```

### models/work_order.py

```python
from sqlmodel import Field, Relationship
from typing import Optional, List
from datetime import datetime
from enum import Enum

from app.models.base import BaseModel


class WorkOrderStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class WorkOrder(BaseModel, table=True):
    """工單資料表"""
    __tablename__ = "work_orders"

    order_number: str = Field(unique=True, index=True)
    customer_id: str = Field(foreign_key="customers.id", index=True)
    product_model: str
    quantity: int = Field(ge=1)
    status: WorkOrderStatus = Field(default=WorkOrderStatus.PENDING, index=True)
    priority: int = Field(default=5, ge=1, le=10)
    due_date: Optional[datetime] = None
    note: Optional[str] = None

    # 關聯
    dispatches: List["Dispatch"] = Relationship(back_populates="work_order")
```

## 請求/回應 Schema

### schemas/base.py

```python
from pydantic import BaseModel
from typing import TypeVar, Generic, Optional, List

T = TypeVar("T")


class ApiResponse(BaseModel, Generic[T]):
    """統一回應格式"""
    success: bool
    data: Optional[T] = None
    error: Optional[dict] = None
    message: Optional[str] = None


class PaginatedResponse(ApiResponse[List[T]], Generic[T]):
    """分頁回應"""
    pagination: Optional[dict] = None


def success_response(data: T, message: str = "成功") -> ApiResponse[T]:
    return ApiResponse(success=True, data=data, message=message)


def error_response(code: str, message: str) -> ApiResponse:
    return ApiResponse(success=False, error={"code": code, "message": message})
```

### schemas/work_order.py

```python
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

from app.models.work_order import WorkOrderStatus


class WorkOrderCreate(BaseModel):
    """新增工單請求"""
    order_number: str = Field(..., min_length=1, max_length=50)
    customer_id: str
    product_model: str
    quantity: int = Field(..., ge=1)
    priority: int = Field(default=5, ge=1, le=10)
    due_date: Optional[datetime] = None
    note: Optional[str] = None


class WorkOrderUpdate(BaseModel):
    """更新工單請求"""
    product_model: Optional[str] = None
    quantity: Optional[int] = Field(default=None, ge=1)
    status: Optional[WorkOrderStatus] = None
    priority: Optional[int] = Field(default=None, ge=1, le=10)
    due_date: Optional[datetime] = None
    note: Optional[str] = None


class WorkOrderResponse(BaseModel):
    """工單回應"""
    id: str
    order_number: str
    customer_id: str
    product_model: str
    quantity: int
    status: WorkOrderStatus
    priority: int
    due_date: Optional[datetime]
    note: Optional[str]
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
```

## 路由設計

### routers/work_orders.py

```python
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select
from typing import List, Optional
from datetime import datetime

from app.database import get_session
from app.models.work_order import WorkOrder, WorkOrderStatus
from app.schemas.base import ApiResponse, PaginatedResponse, success_response, error_response
from app.schemas.work_order import WorkOrderCreate, WorkOrderUpdate, WorkOrderResponse
from app.dependencies import get_current_user
from app.utils.audit import log_audit

router = APIRouter()


@router.get("", response_model=PaginatedResponse[WorkOrderResponse])
def list_work_orders(
    status: Optional[WorkOrderStatus] = None,
    customer_id: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    session: Session = Depends(get_session),
):
    """取得工單列表"""
    query = select(WorkOrder)

    # 篩選條件
    if status:
        query = query.where(WorkOrder.status == status)
    if customer_id:
        query = query.where(WorkOrder.customer_id == customer_id)

    # 分頁
    total = session.exec(select(func.count()).select_from(query.subquery())).one()
    offset = (page - 1) * limit
    query = query.offset(offset).limit(limit).order_by(WorkOrder.created_at.desc())

    items = session.exec(query).all()

    return PaginatedResponse(
        success=True,
        data=[WorkOrderResponse.from_orm(item) for item in items],
        pagination={"total": total, "page": page, "limit": limit}
    )


@router.get("/{work_order_id}", response_model=ApiResponse[WorkOrderResponse])
def get_work_order(
    work_order_id: str,
    session: Session = Depends(get_session),
):
    """取得單一工單"""
    work_order = session.get(WorkOrder, work_order_id)
    if not work_order:
        raise HTTPException(status_code=404, detail="工單不存在")
    return success_response(WorkOrderResponse.from_orm(work_order))


@router.post("", response_model=ApiResponse[WorkOrderResponse])
def create_work_order(
    data: WorkOrderCreate,
    session: Session = Depends(get_session),
    current_user: dict = Depends(get_current_user),
):
    """新增工單"""
    # 檢查工單編號是否重複
    existing = session.exec(
        select(WorkOrder).where(WorkOrder.order_number == data.order_number)
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="工單編號已存在")

    work_order = WorkOrder(**data.model_dump())
    session.add(work_order)
    session.commit()
    session.refresh(work_order)

    # 稽核紀錄
    log_audit(
        session=session,
        user_id=current_user["id"],
        action="CREATE",
        resource_type="work_order",
        resource_id=work_order.id,
        details=data.model_dump()
    )

    return success_response(WorkOrderResponse.from_orm(work_order), "工單建立成功")


@router.put("/{work_order_id}", response_model=ApiResponse[WorkOrderResponse])
def update_work_order(
    work_order_id: str,
    data: WorkOrderUpdate,
    session: Session = Depends(get_session),
    current_user: dict = Depends(get_current_user),
):
    """更新工單"""
    work_order = session.get(WorkOrder, work_order_id)
    if not work_order:
        raise HTTPException(status_code=404, detail="工單不存在")

    # 更新欄位
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(work_order, key, value)
    work_order.updated_at = datetime.utcnow()

    session.add(work_order)
    session.commit()
    session.refresh(work_order)

    # 稽核紀錄
    log_audit(
        session=session,
        user_id=current_user["id"],
        action="UPDATE",
        resource_type="work_order",
        resource_id=work_order.id,
        details=update_data
    )

    return success_response(WorkOrderResponse.from_orm(work_order), "工單更新成功")


@router.delete("/{work_order_id}", response_model=ApiResponse)
def delete_work_order(
    work_order_id: str,
    session: Session = Depends(get_session),
    current_user: dict = Depends(get_current_user),
):
    """刪除工單"""
    work_order = session.get(WorkOrder, work_order_id)
    if not work_order:
        raise HTTPException(status_code=404, detail="工單不存在")

    session.delete(work_order)
    session.commit()

    # 稽核紀錄
    log_audit(
        session=session,
        user_id=current_user["id"],
        action="DELETE",
        resource_type="work_order",
        resource_id=work_order_id,
    )

    return success_response(None, "工單刪除成功")
```

## 認證授權

### dependencies.py

access token 由 Logto 簽發，後端用 Logto 的 JWKS 公鑰驗證簽章，並檢查 issuer、audience 與過期時間。不要用共用密鑰（HS256）自己簽 token。

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
from jwt import PyJWKClient

from app.config import get_settings

settings = get_settings()
security = HTTPBearer()

ISSUER = f"{settings.logto_endpoint}/oidc"
# PyJWKClient 會快取 JWKS，模組層級建立一次；金鑰輪替時依 token 的 kid 自動重抓
jwks_client = PyJWKClient(f"{ISSUER}/jwks")


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> dict:
    """驗證 Logto 簽發的 access token 並取得當前使用者"""
    token = credentials.credentials

    try:
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=settings.jwt_algorithms,
            issuer=ISSUER,
            audience=settings.logto_api_resource,
            options={"require": ["exp", "iat", "sub"]},
        )
    except jwt.PyJWKClientConnectionError:
        # 拿不到 JWKS 是後端依賴故障，不是使用者的 token 有問題
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="認證服務暫時無法使用"
        )
    except jwt.PyJWTError:
        # 簽章錯、過期、issuer 或 audience 不符、找不到對應金鑰都走這裡
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="無效的 Token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return {
        "id": payload["sub"],
        "scopes": payload.get("scope", "").split(),
        "organization_id": payload.get("organization_id"),
    }


def require_scopes(*required: str):
    """權限檢查：Logto 的 RBAC 把權限放在 access token 的 scope（空白分隔）"""
    def scope_checker(current_user: dict = Depends(get_current_user)):
        if not set(required).issubset(current_user["scopes"]):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="權限不足"
            )
        return current_user
    return scope_checker
```

用法：`Depends(require_scopes("work-orders:write"))`。過期時間由 `jwt.decode` 檢查，不需要自己比對 `exp`。

## 稽核紀錄 (ISO 27001)

### utils/audit.py

```python
from sqlmodel import Session
from datetime import datetime
from typing import Optional
import json

from app.models.audit import AuditLog


def log_audit(
    session: Session,
    user_id: str,
    action: str,
    resource_type: str,
    resource_id: str,
    details: Optional[dict] = None,
    ip_address: Optional[str] = None,
):
    """記錄稽核日誌"""
    audit_log = AuditLog(
        user_id=user_id,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        details=json.dumps(details) if details else None,
        ip_address=ip_address,
        timestamp=datetime.utcnow(),
    )
    session.add(audit_log)
    session.commit()
```

## 錯誤處理

### 全域例外處理

```python
from fastapi import Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": {
                "code": str(exc.status_code),
                "message": exc.detail
            }
        }
    )


@app.exception_handler(IntegrityError)
async def integrity_error_handler(request: Request, exc: IntegrityError):
    return JSONResponse(
        status_code=400,
        content={
            "success": False,
            "error": {
                "code": "INTEGRITY_ERROR",
                "message": "資料完整性錯誤，可能是重複的資料"
            }
        }
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    # 記錄錯誤
    print(f"Unhandled error: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "伺服器內部錯誤"
            }
        }
    )
```

## Render 部署

### render.yaml

```yaml
services:
  - type: web
    name: mes-api
    runtime: python
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn app.main:app --host 0.0.0.0 --port $PORT
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: mes-db
          property: connectionString
      - key: LOGTO_ENDPOINT
        sync: false
      - key: LOGTO_API_RESOURCE
        sync: false
      - key: CORS_ORIGINS
        sync: false
    healthCheckPath: /health
    autoDeploy: true

databases:
  - name: mes-db
    plan: free
    databaseName: mes
    user: mes_user
```

### requirements.txt

```
fastapi>=0.109.0
uvicorn[standard]>=0.27.0
sqlmodel>=0.0.14
pydantic-settings>=2.1.0
PyJWT[crypto]>=2.15.0
psycopg2-binary>=2.9.9
```

## Vercel 部署

Vercel 把 FastAPI 當成一個 Vercel Function 執行，不需要 uvicorn 啟動指令，也沒有常駐程序。以下依 Vercel 官方文件（[FastAPI](https://vercel.com/docs/frameworks/backend/fastapi)、[Python runtime](https://vercel.com/docs/functions/runtimes/python)）整理，2026-11 查證。

### 入口與相依

- 入口檔：Vercel 會在 `app.py`、`index.py`、`server.py`、`main.py`、`wsgi.py`、`asgi.py`（或 `src/`、`app/` 底下同名檔）找名為 `app` 的 FastAPI 實例。上面的專案結構 `app/main.py` 可直接被偵測到。
- 入口不在預設位置時，在 `pyproject.toml` 指定：

```toml
[tool.vercel]
entrypoint = "backend.server:app"
```

- 相依用 `requirements.txt`、`pyproject.toml` 或 `Pipfile` 擇一宣告。
- Python 版本寫在 `.python-version`（例如 `3.13`）；沒寫時預設 3.12。

### vercel.json

`functions` 的 key 是實際入口檔路徑：

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "regions": ["sin1"],
  "functions": {
    "app/main.py": {
      "maxDuration": 60,
      "excludeFiles": "{tests/**,**/test_*.py,fixtures/**,static/**}"
    }
  }
}
```

- `regions`：Hobby 方案可選一個區域，預設 `iad1`。設成離 Neon 資料庫最近的區域，例如 Neon 在 `aws-ap-southeast-1`（新加坡）就用 `sin1`，否則每次查詢都要跨洋。
- `maxDuration`：上限依方案而定，以 [duration 文件](https://vercel.com/docs/functions/configuring-functions/duration) 為準；長任務不要塞進 request，改用 Queue 或排程。
- `excludeFiles`：Python bundle 上限 500 MB，測試、範例資料、靜態檔都排除。

### 跟 Render 不同的地方

| 項目 | Render | Vercel |
|------|--------|--------|
| 啟動 | `uvicorn` 常駐 | 依請求啟動 Function，不需啟動指令 |
| `lifespan` | 啟動一次 | 每個新實例都會跑；關閉時的清理只有 SIGTERM 後 500 ms |
| 建表 | 可在啟動時 `init_db()` | 不要在 `lifespan` 跑 `create_all`，改在部署前執行 migration |
| 靜態檔 | 自己 mount | 放專案根目錄 `public/` 由 CDN 提供，不要 `app.mount("/", ...)` 掛 `public/` |
| 健康檢查 | `/health` 給 Render 用 | 不需要，保留也無害 |

### 資料庫連線

Function 會隨流量開出多個實例，每個實例各自建連線池，Neon 的連線數很快就會滿：

- 用 Neon 的 pooled 連線字串（主機名含 `-pooler`）。
- 每個實例的池子開小，或直接不池化：

```python
from sqlalchemy.pool import NullPool
from sqlmodel import create_engine

# Vercel：每個 request 用完即還，由 Neon 的 pooler 負責共用連線
engine = create_engine(settings.database_url, poolclass=NullPool, pool_pre_ping=True)
```

### 本機與部署

```bash
vercel dev       # 本機模擬（CLI >= 48.1.8）
vercel deploy    # 或接 Git 自動部署
```

成本與效能審查用外部收錄的 `vercel-optimize`（Vercel 官方）。

## 禁止事項

1. **禁止 Fallback Mock 資料** - 資料庫連線失敗應回傳 503
2. **禁止 Emoji** - 程式碼、註解都不使用
3. **禁止簡體字** - 錯誤訊息使用正體中文
4. **禁止硬編碼機敏資料** - 使用環境變數
5. **禁止 CORS 萬用來源** - `allow_origins` 明列前端網域，不用 `["*"]`
6. **禁止用共用密鑰驗 token** - 一律用 Logto JWKS 公鑰驗證，演算法清單只列非對稱演算法

## 效能標準

| 指標 | 目標 |
|------|------|
| API 回應時間 | < 500ms |
| 資料庫查詢 | < 100ms |
| 啟動時間 | < 30s |

## 參考資源

- [FastAPI 官方文件](https://fastapi.tiangolo.com/)
- [SQLModel 官方文件](https://sqlmodel.tiangolo.com/)
- [Neon PostgreSQL](https://neon.tech/docs)
- [Render 部署指南](https://render.com/docs)
- [Vercel FastAPI 部署](https://vercel.com/docs/frameworks/backend/fastapi)
