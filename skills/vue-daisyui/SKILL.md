---
name: vue-daisyui
description: Vue 3 CDN + DaisyUI 快速原型開發模式。適用於 POC、Demo、內部工具等需要快速交付的場景。零建置、單檔部署、改完直接 git push。
source: custom
updated: 2025-01-16
---

# Vue 3 CDN + DaisyUI 快速原型開發

## 適用場景

- POC 概念驗證
- Demo 展示
- 內部工具
- 單人維護專案
- 需要快速迭代的場景

## 核心原則

**夠用就好，不過度工程化**

## 基礎模板

```html
<!DOCTYPE html>
<html lang="zh-TW" data-theme="light">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>專案名稱</title>

  <!-- Tailwind CSS + DaisyUI -->
  <script src="https://cdn.tailwindcss.com"></script>
  <link href="https://cdn.jsdelivr.net/npm/daisyui@4/dist/full.min.css" rel="stylesheet">

  <!-- Vue 3 -->
  <script src="https://unpkg.com/vue@3/dist/vue.global.prod.js"></script>

  <!-- Lucide Icons -->
  <script src="https://unpkg.com/lucide@latest"></script>
</head>
<body>
  <div id="app">
    <!-- 內容 -->
  </div>

  <script>
    const { createApp, ref, computed, onMounted, watch } = Vue

    createApp({
      setup() {
        // 狀態
        const items = ref([])
        const isLoading = ref(false)

        // 方法
        const fetchData = async () => {
          isLoading.value = true
          try {
            const res = await fetch('/api/items')
            const data = await res.json()
            if (data.success) {
              items.value = data.data
            }
          } catch (err) {
            console.error('載入失敗:', err)
          } finally {
            isLoading.value = false
          }
        }

        onMounted(() => {
          fetchData()
          lucide.createIcons()
        })

        return {
          items,
          isLoading,
          fetchData
        }
      }
    }).mount('#app')
  </script>
</body>
</html>
```

## DaisyUI 元件速查

### 按鈕

```html
<!-- 基本按鈕 -->
<button class="btn">按鈕</button>
<button class="btn btn-primary">主要</button>
<button class="btn btn-secondary">次要</button>
<button class="btn btn-accent">強調</button>
<button class="btn btn-ghost">透明</button>
<button class="btn btn-link">連結</button>

<!-- 尺寸 -->
<button class="btn btn-xs">超小</button>
<button class="btn btn-sm">小</button>
<button class="btn btn-md">中</button>
<button class="btn btn-lg">大</button>

<!-- 帶圖示 -->
<button class="btn btn-primary">
  <i data-lucide="save" class="w-4 h-4"></i>
  儲存
</button>

<!-- 載入中 -->
<button class="btn btn-primary" :disabled="isLoading">
  <span v-if="isLoading" class="loading loading-spinner loading-sm"></span>
  {{ isLoading ? '處理中...' : '送出' }}
</button>
```

### 表單輸入

```html
<!-- 文字輸入 -->
<input type="text" v-model="form.name" class="input input-bordered w-full" placeholder="請輸入名稱">

<!-- 帶標籤 -->
<label class="form-control w-full">
  <div class="label">
    <span class="label-text">名稱</span>
    <span class="label-text-alt text-error">*必填</span>
  </div>
  <input type="text" v-model="form.name" class="input input-bordered w-full">
</label>

<!-- 下拉選單 -->
<select v-model="form.status" class="select select-bordered w-full">
  <option value="">請選擇</option>
  <option v-for="opt in options" :key="opt.value" :value="opt.value">
    {{ opt.label }}
  </option>
</select>

<!-- Textarea -->
<textarea v-model="form.note" class="textarea textarea-bordered w-full" rows="3" placeholder="備註"></textarea>

<!-- Checkbox -->
<label class="label cursor-pointer">
  <span class="label-text">啟用</span>
  <input type="checkbox" v-model="form.isActive" class="checkbox checkbox-primary">
</label>
```

### 表格

```html
<div class="overflow-x-auto">
  <table class="table table-zebra">
    <thead>
      <tr>
        <th>編號</th>
        <th>名稱</th>
        <th>狀態</th>
        <th>操作</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="item in items" :key="item.id">
        <td>{{ item.id }}</td>
        <td>{{ item.name }}</td>
        <td>
          <span class="badge" :class="getStatusClass(item.status)">
            {{ item.statusText }}
          </span>
        </td>
        <td>
          <button class="btn btn-ghost btn-xs" @click="edit(item)">
            <i data-lucide="pencil" class="w-4 h-4"></i>
          </button>
          <button class="btn btn-ghost btn-xs text-error" @click="confirmDelete(item)">
            <i data-lucide="trash-2" class="w-4 h-4"></i>
          </button>
        </td>
      </tr>
      <tr v-if="items.length === 0">
        <td colspan="4" class="text-center text-base-content/50">無資料</td>
      </tr>
    </tbody>
  </table>
</div>
```

### Modal 對話框

```html
<!-- 觸發按鈕 -->
<button class="btn" onclick="my_modal.showModal()">開啟</button>

<!-- Modal -->
<dialog id="my_modal" class="modal">
  <div class="modal-box">
    <h3 class="font-bold text-lg">標題</h3>
    <p class="py-4">內容</p>
    <div class="modal-action">
      <form method="dialog">
        <button class="btn">關閉</button>
      </form>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop">
    <button>close</button>
  </form>
</dialog>

<!-- Vue 控制版本 -->
<dialog ref="modalRef" class="modal">
  <div class="modal-box">
    <h3 class="font-bold text-lg">{{ modalTitle }}</h3>
    <div class="py-4">
      <!-- 表單內容 -->
    </div>
    <div class="modal-action">
      <button class="btn" @click="closeModal">取消</button>
      <button class="btn btn-primary" @click="saveForm">儲存</button>
    </div>
  </div>
</dialog>

<script>
// setup() 內
const modalRef = ref(null)
const openModal = () => modalRef.value.showModal()
const closeModal = () => modalRef.value.close()
</script>
```

### Drawer 側邊欄

```html
<div class="drawer drawer-end">
  <input id="my-drawer" type="checkbox" class="drawer-toggle" v-model="drawerOpen">

  <!-- 主內容 -->
  <div class="drawer-content">
    <button class="btn btn-primary" @click="drawerOpen = true">
      開啟側邊欄
    </button>
  </div>

  <!-- 側邊欄 -->
  <div class="drawer-side z-50">
    <label for="my-drawer" class="drawer-overlay"></label>
    <div class="p-4 w-80 min-h-full bg-base-100">
      <h2 class="text-lg font-bold mb-4">編輯</h2>
      <!-- 表單內容 -->
      <div class="mt-4 flex gap-2">
        <button class="btn btn-ghost" @click="drawerOpen = false">取消</button>
        <button class="btn btn-primary" @click="save">儲存</button>
      </div>
    </div>
  </div>
</div>
```

### Badge 徽章

```html
<span class="badge">預設</span>
<span class="badge badge-primary">主要</span>
<span class="badge badge-secondary">次要</span>
<span class="badge badge-success">成功</span>
<span class="badge badge-warning">警告</span>
<span class="badge badge-error">錯誤</span>
<span class="badge badge-info">資訊</span>
<span class="badge badge-outline">外框</span>
```

### Alert 提示

```html
<div class="alert alert-info">
  <i data-lucide="info" class="w-5 h-5"></i>
  <span>資訊提示</span>
</div>

<div class="alert alert-success">
  <i data-lucide="check-circle" class="w-5 h-5"></i>
  <span>操作成功</span>
</div>

<div class="alert alert-warning">
  <i data-lucide="alert-triangle" class="w-5 h-5"></i>
  <span>警告訊息</span>
</div>

<div class="alert alert-error">
  <i data-lucide="x-circle" class="w-5 h-5"></i>
  <span>錯誤訊息</span>
</div>
```

### Loading 載入

```html
<!-- Spinner -->
<span class="loading loading-spinner loading-xs"></span>
<span class="loading loading-spinner loading-sm"></span>
<span class="loading loading-spinner loading-md"></span>
<span class="loading loading-spinner loading-lg"></span>

<!-- Dots -->
<span class="loading loading-dots loading-md"></span>

<!-- 全頁載入 -->
<div v-if="isLoading" class="fixed inset-0 bg-base-100/80 flex items-center justify-center z-50">
  <span class="loading loading-spinner loading-lg"></span>
</div>
```

### Toast 通知

```html
<!-- 固定在右下角 -->
<div class="toast toast-end">
  <div v-if="toast.show" class="alert" :class="'alert-' + toast.type">
    <span>{{ toast.message }}</span>
  </div>
</div>

<script>
// setup() 內
const toast = ref({ show: false, type: 'info', message: '' })

const showToast = (message, type = 'info', duration = 3000) => {
  toast.value = { show: true, type, message }
  setTimeout(() => {
    toast.value.show = false
  }, duration)
}

// 使用
showToast('儲存成功', 'success')
showToast('發生錯誤', 'error')
</script>
```

## API 呼叫模式

```javascript
// 基本 GET
const fetchItems = async () => {
  isLoading.value = true
  try {
    const res = await fetch(`${API_BASE}/items`)
    const data = await res.json()
    if (data.success) {
      items.value = data.data
    } else {
      showToast(data.error?.message || '載入失敗', 'error')
    }
  } catch (err) {
    showToast('網路錯誤', 'error')
  } finally {
    isLoading.value = false
  }
}

// POST
const createItem = async (payload) => {
  try {
    const res = await fetch(`${API_BASE}/items`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })
    const data = await res.json()
    if (data.success) {
      showToast('新增成功', 'success')
      await fetchItems()
      return true
    } else {
      showToast(data.error?.message || '新增失敗', 'error')
      return false
    }
  } catch (err) {
    showToast('網路錯誤', 'error')
    return false
  }
}

// PUT
const updateItem = async (id, payload) => {
  try {
    const res = await fetch(`${API_BASE}/items/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })
    const data = await res.json()
    if (data.success) {
      showToast('更新成功', 'success')
      await fetchItems()
      return true
    }
    showToast(data.error?.message || '更新失敗', 'error')
    return false
  } catch (err) {
    showToast('網路錯誤', 'error')
    return false
  }
}

// DELETE
const deleteItem = async (id) => {
  try {
    const res = await fetch(`${API_BASE}/items/${id}`, { method: 'DELETE' })
    const data = await res.json()
    if (data.success) {
      showToast('刪除成功', 'success')
      await fetchItems()
    } else {
      showToast(data.error?.message || '刪除失敗', 'error')
    }
  } catch (err) {
    showToast('網路錯誤', 'error')
  }
}
```

## localStorage 快取

```javascript
// 儲存
const saveToCache = (key, data) => {
  localStorage.setItem(key, JSON.stringify({
    data,
    timestamp: Date.now()
  }))
}

// 讀取（含過期檢查）
const loadFromCache = (key, maxAge = 5 * 60 * 1000) => {
  const cached = localStorage.getItem(key)
  if (!cached) return null

  const { data, timestamp } = JSON.parse(cached)
  if (Date.now() - timestamp > maxAge) {
    localStorage.removeItem(key)
    return null
  }
  return data
}

// 使用
onMounted(async () => {
  // 先載入快取
  const cached = loadFromCache('items_cache')
  if (cached) {
    items.value = cached
  }

  // 再從 API 更新
  await fetchItems()
  saveToCache('items_cache', items.value)
})
```

## 禁止事項

1. **禁止 Fallback Mock 資料** - API 失敗應顯示錯誤
2. **禁止 Emoji** - 程式碼、註解、UI 都不使用
3. **禁止簡體字** - 全程使用正體中文
4. **禁止過度工程化** - 快速原型不需要完美架構

## 效能標準

| 指標 | 目標 |
|------|------|
| Lighthouse Performance | >= 70 |
| 首屏載入 | < 5 秒 |
| API 回應 | < 500ms |

**記住：快速原型的目標是「夠用」，不是「完美」**

## 部署

```bash
# 改完直接推
git add -A && git commit -m "feat: 功能描述" && git push
# Vercel 自動部署
```
