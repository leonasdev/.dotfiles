# Review Report 範例

幾個不同情境下的 review report，看實際長度與語氣怎麽拿捏。**模板是 SKILL.md 裏那個，這些是
怎麽塡的示範**。

---

## 範例 1：小範圍 bugfix，發現 silent fallback

**情境**：同事用 Cursor 修了 `parse_user_config`，宣稱「處理 invalid JSON」。Diff 約 30 行。

```markdown
## Review 概要
不要直接 merge。Task 要求「invalid JSON 時回報 user-friendly error」，但 diff 改成 invalid
JSON 時 silently return 空 config，caller 拿不到失敗訊號。Test 也只 assert return 非 None，
沒覆蓋到該 case。整體實作方向正確但執行偏離 spec。

## 已驗證項目
- `pytest tests/config/test_parser.py` — pass（但 test 不夠強，見下方）
- 手動跑 `python -c "from app.config import parse_user_config; print(parse_user_config('/tmp/bad.json'))"`
  with malformed JSON — 返回 `{}` 而非預期的 `ConfigParseError`
- 沒驗證：integration 流程，因爲 staging 環境不在手邊

## Critical issues
- **app/config/parser.py:42 — invalid JSON 被吞成空 config**
  ```python
  try:
      return json.load(f)
  except Exception:
      return {}
  ```
  Task spec 要求「invalid JSON 時 raise `ConfigParseError(msg)` 給 caller 顯示」，這裏直接吞掉。
  Caller (`app/main.py:88`) 拿到空 dict 後會用全 default 啓動，使用者完全感覺不到 config 壞了。
  建議改成：
  ```python
  try:
      return json.load(f)
  except json.JSONDecodeError as e:
      raise ConfigParseError(f"Invalid config at {path}: {e}") from e
  ```

## Concerns
- **tests/config/test_parser.py:25 — test_handles_invalid_json 沒測到 invalid JSON 的處理**
  body 只 `assert parse_user_config(bad_path) is not None`，把上面的 silent return 也判 pass。
  改成 `with pytest.raises(ConfigParseError): parse_user_config(bad_path)`。

## Nits
- app/config/parser.py:15 — 多餘 docstring 重述 function name，可刪。

## 還不錯的地方
- 邊界檔（空檔、僅 BOM）的處理有想到，那兩條 path 看起來正確。
```

---

## 範例 2：中型 PR，主要是 over-engineering 與 spec drift

**情境**：同事用 Copilot Agent 加了 webhook delivery，task 是「支援一個 Slack webhook」。
Diff 約 400 行，引入了 plugin architecture。

```markdown
## Review 概要
不建議 merge。功能本身能 work（Slack webhook 可以送出），但 task 只要求「一個 Slack webhook」，
diff 卻引入了 5 個檔案的 plugin / dispatcher / registry 架構，僅有一個具體實作。同時 retry
邏輯偏離 spec（spec 說「失敗丟 DLQ」，diff 寫的是「重試 3 次後 silently drop」）。建議拆掉
抽象、修正 retry。

## 已驗證項目
- `pytest tests/webhooks/` — 12/12 pass
- 手動跑 `bin/send-webhook --target slack --payload '{"text":"test"}'` — 收到，正常
- 注入 500 response 模擬失敗 — 確認進入「silently drop」分支，與 spec 不符
- 沒驗證：production Slack workspace（沒 token）

## Critical issues
- **app/webhooks/dispatcher.py:78 — retry 用盡後 silently drop，不是 DLQ**
  ```python
  except RequestException:
      log.warning("webhook failed after 3 retries")
      return  # spec 要求丟到 DLQ 等手動 replay
  ```
  Task spec 第 3 點明確說「失敗訊息要進 DLQ 供後續 replay」。建議：
  ```python
  except RequestException:
      log.warning("webhook failed after 3 retries; queueing to DLQ")
      dlq.enqueue(WebhookPayload(target=target, payload=payload, last_error=str(e)))
      return
  ```

## Concerns
- **app/webhooks/registry.py 整檔 — plugin registry over-engineering**
  目前只有 `SlackPlugin` 一個註冊項。`WebhookPlugin` ABC + `WebhookRegistry` + `PluginLoader`
  三層抽象，task 沒要求支援多種 webhook。建議刪掉 ABC / registry，把 `slack.py` 直接 expose
  `send_to_slack(payload)`，未來真的要加 Discord 等再抽。
- **app/webhooks/slack.py:55 — timeout 寫死 5s**
  Spec 沒指定但這個值應該可以 config，不然 production 不好調。

## Nits
- 多檔案的 module docstring 都是 AI 生成的「This module ...」樣板，沒實質內容，可移除。
- `app/webhooks/types.py:12` — `WebhookPayloadV1` 命名暗示有 V2，但沒有。改 `WebhookPayload`。

## 還不錯的地方
- HMAC signature 驗證的測試覆蓋齊全，包含篡改與 replay。
- 對 Slack rate limit (429) 的 backoff 處理正確。
```

---

## 範例 3：宣稱「fix 完且測試通過」但實際沒做到 task

**情境**：使用者貼了一段跟 Gemini 的對話，最後一輪 Gemini 說「I've implemented the
caching layer and all tests pass」。Diff 只改了 `cache.py` 一處。

```markdown
## Review 概要
Gemini 聲稱「實作了 caching layer 且 tests pass」，但 diff 實際上**沒實作 caching**——只
把現有的 `get_user` 加了 `@lru_cache(maxsize=128)` 裝飾器。task spec 要求 Redis-backed
distributed cache with TTL，這份 diff 完全沒有 Redis、沒有 TTL、沒有 invalidation 機制。
請 Gemini 重做。

## 已驗證項目
- `pytest tests/` — pass，但 test suite 裏沒有任何 test exercise Redis 或 multi-process
  invalidation（grep `redis` 無結果）。
- `rg -i "redis|cache_invalidate|ttl"` 在 diff 中 — 0 matches。
- 跟 Gemini 的對話：在第 4 輪它說「I'll use Redis as the backend」，但 final code 沒做到。

## Critical issues
- **整份 diff — 沒實作 spec 要求的 distributed cache**
  ```python
  # 目前 diff 的全部變更：
  @lru_cache(maxsize=128)
  def get_user(user_id: str) -> User:
      ...
  ```
  `functools.lru_cache` 是 process-local in-memory cache，不是 distributed，不支援 TTL，
  不能 invalidate。Task 要求：
  - Redis backend ✗
  - per-key TTL ✗
  - invalidate-on-update ✗
  - 多 worker 一致 ✗
  目前的實作在多 worker 環境會出現嚴重一致性問題（每個 worker 各 cache 一份）。**沒做到 task**。

## Concerns
- 不適用——根本問題是沒實作。

## Nits
- 不適用。

## 還不錯的地方
- 不適用。建議讓 Gemini 從 Redis client 設置 + cache wrapper interface 重新開始；如果它再次
  「宣稱完成」，請貼回對話 + final diff，我再 review。
```

---

## 範例 4：使用者沒提供 task spec

**情境**：使用者只說「同事推了個 branch，幫我看一下」。

```markdown
## Review 概要
我需要更多 context 才能 review 得有意義。看 diff 是把 `db/migrations/` 下加了一個新 migration
（add user_settings table）並改了 `models/user.py` 與 `api/users.py`。代碼**本身**沒明顯
問題，但**我沒辦法判斷它是不是做到了該做的事**——沒看到原始 task / issue / spec。

請給以下其中之一：
1. 原始 issue / spec / 想做的事的描述
2. 跟 AI 的對話紀錄
3. PR 描述（如果有）

在這之前，以下是基於 diff 本身的觀察：

## 已驗證項目
- `pytest tests/api/test_users.py` — pass
- `alembic upgrade head` on local dev db — 成功
- 沒驗證：rollback path、production-like data 上的 migration 時間

## Critical issues
- 不確定，因爲沒有 spec 對照。但有兩個點請先確認是否符合預期：
  - **db/migrations/20251204_add_user_settings.py:30** — migration 沒有 `downgrade()` 內容
    （`pass`）。Rollback 會 silently 不做事，schema 會卡住。如果是有意爲之請註解說明；通常
    應該寫對應的 `DROP TABLE`。
  - **api/users.py:124** — `settings` endpoint 沒有 auth 檢查，任何人帶任何 `user_id`
    都能讀別人的 settings。如果這個 endpoint 是 internal-only 請加 middleware，否則需要
    rate-limit + ownership check。

## Concerns / Nits
- 待 spec 補上後再評。
```

---

## 共通模式

- **整體 verdict 放最上面**，不要讓使用者讀完才知道結論。
- **「已驗證項目」要具體**，列實際跑過的指令、看過的 output。沒驗證的也要明說，這比含糊更有用。
- **每個 finding 帶 `file:line`** 讓使用者點得進去；附 code block 比文字描述快理解。
- **建議的修法寫具體**（patch-like），但不要喧賓奪主搶 task。
- **真的好的點要列**，全部 negative 的 report 容易讓使用者抗拒、漏掉重點 critical。

不要爲了「看起來細」而塞太多 nit，**critical 與 concerns 才是重點**。
