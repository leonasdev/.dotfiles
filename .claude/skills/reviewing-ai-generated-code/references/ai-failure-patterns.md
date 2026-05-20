# AI Agent 常見失敗模式：具體例子與驗證方法

這個檔案展開 SKILL.md 中列的 10 種失敗模式，每個給出：
- **長相**：實際看起來會是什麽樣
- **怎麽辨識**：在 diff 裏掃描時的線索
- **怎麽驗證**：具體要做什麽動作確認
- **常見修法 / review comment 的講法**

在你開始逐行 review 之前先讀一遍。實際 review 時看到 diff 起疑了再回來對照。

---

## 1. Hallucinated APIs / symbols

### 長相

```python
# AI 寫的
from openai import RateLimitError
client = openai.AsyncClient()  # 也許這個 class 不存在
result = await client.chat.completions.create_async(...)  # 也可能沒有 create_async
```

```typescript
// AI 寫的
import { useQueryClient } from "@tanstack/react-query";
const client = useQueryClient();
client.invalidateAllQueries();  // 真實 API 是 invalidateQueries()
```

```rust
// AI 寫的
let result = vec.iter()
    .filter_map_ok(|x| x.parse())  // itertools 不一定有這個方法，或不是這個簽名
    .collect()?;
```

### 怎麽辨識

- **罕見 method 名**——`create_async`、`invalidateAllQueries`、`get_or_insert_default_with`
  這類「聽起來合理但不是標準名」的 method 特別可疑。
- **混合風格**——同一段 code 中混了多個 library 的命名習慣（snake_case + camelCase）。
- **AI 對 library 版本沒明說**——dependency 鎖在 X 版，但 AI 用了 Y 版才有的 API。
- **import 多但用不到 / import 少卻用了的東西**——常常是 AI 想呼叫某個 method 但連 import
  都沒處理對。

### 怎麽驗證

- **直接 grep 該 symbol**：`rg "create_async\b"` 在 library source / `node_modules` /
  `site-packages`。沒有就是 hallucination。
- **讀 library docs**（用 context7 MCP 或 fetch 官方 docs）查 method 簽名。
- **跑 import test**：`python -c "from foo import bar"`、`tsc --noEmit`、`cargo check`——
  最低限度確認 symbol 存在。

### Review 講法

> `<file>:<line>` — `client.invalidateAllQueries()` 在 `@tanstack/react-query` v5 不存在，
> 應是 `invalidateQueries()`（無參數即全部失效）或 `invalidateQueries({queryKey: [...]})`。
> 跑 `tsc --noEmit` 會立刻爆掉。

---

## 2. 看似合理但跑不到的 control flow

### 長相

```python
# 「忘了 await」
async def get_user(id):
    user = db.fetch_user(id)  # 缺 await，user 是 coroutine
    if user.name == "admin":  # AttributeError on coroutine
        ...
```

```python
# 永遠 false 的 guard
def cleanup(items):
    if items is None or len(items) == 0:
        return
    if not items:  # 上面已 return，這條永遠不會跑
        log.warn("empty after filter")
```

```typescript
// 副作用後 return 順序錯
function save(x: T): Result {
    return validate(x);   // bug: 永遠不 save，因爲 return 在 save 之前
    db.save(x);
}
```

```python
# 早期 return 把後段 unreachable
def process(events):
    for e in events:
        if e.type == "x":
            return handle_x(e)
        elif e.type == "y":
            return handle_y(e)
    # 多個 event 的情況：只處理了第一個就 return
```

### 怎麽辨識

- **async function 沒有 await 任何呼叫**——可疑。
- **if 鏈巢狀後突然多一條「補一個 check」**——常是上面已蓋過的條件。
- **return 後還有有副作用的 statement**——dead code。
- **for / while loop body 第一個 statement 就是 return**——可能本來要 collect，但寫成只處理
  第一個。

### 怎麽驗證

- **靜態分析工具**：mypy、pyright、ts-strict、clippy；async 漏 await 的 lint 規則特別有用。
- **手動 trace**：拿一兩個代表性輸入在腦中跑一遍。
- **故意觸發**：寫一個小 repro，用 debugger / print 看實際走到哪。

### Review 講法

> `<file>:<line>` — `db.fetch_user` 是 async，這裏沒 await，`user` 是 coroutine 不是 dict，
> 下一行 `.name` 會 AttributeError。應寫 `user = await db.fetch_user(id)`。

---

## 3. Silent fallback / 過度寬鬆的 exception handling

### 長相

```python
def parse_config(path):
    try:
        return json.load(open(path))
    except Exception:
        return {}   # 任何錯誤（FileNotFound、JSONDecodeError、PermissionError…）都被吞掉
```

```python
def get_user_id(req):
    try:
        return req.headers["X-User-Id"]
    except:  # bare except
        return None  # caller 拿到 None 完全分不出是「沒登入」「header 拼錯」「上游 bug」
```

```typescript
async function fetchData(url: string) {
    try {
        return await fetch(url).then(r => r.json());
    } catch {
        return [];  // 網路斷、JSON parse 錯、500 都被當成「沒資料」
    }
}
```

### 怎麽辨識

- **`except Exception` / `except:` / `catch (e)` 後 return 一個 default 值**——99% 該 flag。
- **catch block 裏沒 log、沒 re-raise、沒 typed re-throw**。
- **task spec 提到「應該回報錯誤」但 diff 把錯誤吞了**。

### 怎麽驗證

- **看 caller 怎麽用 return 值**：caller 能分辨「正常結果」vs「失敗 fallback」嗎？分不出就是
  silent failure。
- **trace failure path**：故意製造一個錯誤條件，看系統有沒有 propagate。
- **對照 task spec**：spec 有沒有說「失敗時要做什麽」？有的話比對是否做到。

### Review 講法

> `<file>:<line>` — `except Exception: return {}` 會把 `FileNotFoundError`、
> `JSONDecodeError`、`PermissionError` 都吞成「空 config」。caller 拿不到失敗訊號，
> 啓動時 config 壞掉會以「全 default」狀態繼續跑下去。應該至少 log + 區分 missing-file
> 與 corrupt-file，視 task 要求決定要 raise 還是回 typed error。

---

## 4. Mock 偽裝成 real

### 長相

```python
def get_recent_signups(days: int) -> list[User]:
    """Query the database for users who signed up in the last N days."""
    # 整個 body 是寫死的 demo data
    return [User(id=1, name="alice"), User(id=2, name="bob")]
```

```typescript
async function chargeCustomer(customerId: string, amount: number): Promise<TxResult> {
    // TODO: integrate with Stripe
    return { success: true, txId: "stub-tx-id" };
}
```

```python
class EmailSender:
    def send(self, to: str, body: str):
        pass  # 「實現」了 interface，但啥都沒做
```

### 怎麽辨識

- **docstring 說 X，body 顯然沒在做 X**。
- **`TODO`、`FIXME`、`stub`、`mock`、`placeholder` 字樣**。
- **return 寫死的字串 / 數值**（特別是測試用 ID 格式如 `"test-..."`、`"stub-..."`）。
- **`pass`、`...`、`raise NotImplementedError` 在號稱完成的實作裏**。
- **AI 對話中曾說「我會留個 stub 等你接」但最終沒接**。

### 怎麽驗證

- **grep TODO / stub / placeholder**：`rg -i "todo|stub|placeholder|not implemented|fixme"`。
- **追實際依賴**：函數聲稱用 X service，去看有沒有 import X、有沒有初始化 X client。
- **跑一次真實 flow**：放真實 input、看真實 output，不要依賴 unit test。

### Review 講法

> `<file>:<line>` — `chargeCustomer` 沒實作，只回寫死的 `{success: true, txId: "stub-tx-id"}`，
> 但函數 signature 跟 caller 都當它是 real charge。Task spec 要求「串 Stripe payment」，
> 這份變更**沒做到**。需要實作 Stripe charges.create 呼叫並處理失敗 case。

---

## 5. Testing theater（測試裝樣子）

### 長相

```python
def test_handles_empty_list():
    result = process([])
    assert result is not None   # 任何非 None return 都 pass，跟 empty 沒關係
```

```python
def test_user_created_with_email():
    user = create_user("alice@example.com")
    assert user                 # truthy check; 沒檢查 email 真的存到 user.email
```

```typescript
// mock 把要測的東西也 mock 掉
it("computes total correctly", () => {
    jest.spyOn(cart, "computeTotal").mockReturnValue(100);  // 把要測的函數 mock 掉
    expect(cart.computeTotal()).toBe(100);                  // 廢話 test
});
```

```python
# test 名稱說 X，body 在做 Y
def test_validates_negative_amount():
    result = charge(amount=100)   # 沒測 negative
    assert result.ok
```

### 怎麽辨識

- **`assert X is not None` / `assert X` / `assert truthy`** 而 X 是函數結果。
- **mock 的對象就是 test 名稱在說要測的東西**。
- **test 名稱跟 body 的 input/邏輯不匹配**——讀 test 名後再讀 body，覺得「啊？」就是線索。
- **大量 mock，幾乎沒有真實計算**——等於在 test mock 本身。
- **不同 test 用幾乎一樣的 fixture / assertion**——可能是 AI 複製貼上、形式上補 test 數量。

### 怎麽驗證

- **設想一個 regression**：「如果我把 `process` 永遠回 `[1]`，這個 test 還會 pass 嗎？」
  會的話 test 是裝飾品。
- **倒過來突變測試**：暫時改 production code 讓邏輯壞掉，run test，看會不會抓到。
- **檢查 mock**：每個 mock 對應的真實邏輯有沒有被其他 test 覆蓋？

### Review 講法

> `<file>:<line>` — `test_handles_empty_list` 的 assertion 只檢查 `result is not None`，
> 對 empty input 而言任何 return 都 pass（包括 bug 把整個 list 丟掉的版本）。應 assert
> 具體的回傳結構，例 `assert result == {"items": [], "total": 0}`。

---

## 6. Spec drift（規格漂移）

### 長相

- Task 要求「對 `/api/v2/orders` 加 rate limit 100 req/min」，diff 改的是 `/api/v1/orders`
  並設 60/min。
- Task 要求「批次處理時失敗一個不影響其他」，diff 在 first failure 就 raise 並中止整個 batch。
- 跟 AI 多輪後使用者說「不要 cache 這個 endpoint」，但 final diff 仍有 cache layer。
- Task 要求「only when env=prod」，diff 寫的是 `if env != "dev"`（staging 也會跑到）。

### 怎麽辨識

- **逐項對照 task spec 的需求列表 vs diff 中的 implementation**。
- **AI 對話中曾出現使用者糾正 / 補需求的訊息**——這些是最容易丟失的需求。
- **diff 的 commit message / 描述跟 task 用詞略有差異**——可能是 AI 自己 paraphrase 後失真。

### 怎麽驗證

- **把 task spec 條列**，diff 中每一條對到具體 commit / hunk。
- **對話紀錄裏的「對，但是…」「不對，應該…」要回去確認**最終實作 follow 了哪邊。

### Review 講法

> 整體 — task 要求對 `/api/v2/orders` 加 100 req/min rate limit，但 diff 改的是
> `/api/v1/orders` 且設 60 req/min。請確認是不是 spec 看錯，否則需要改 endpoint 與 quota。
> 另外原始 task 沒提到 IP-based limiting，diff 卻加了，這部分需要使用者確認是否要保留。

---

## 7. Over-engineering

### 長相

```python
# 一個 caller、一個 implementation 的 abstract base class
class PaymentProcessor(ABC):
    @abstractmethod
    def charge(self, amount: int) -> Result: ...

class StripePaymentProcessor(PaymentProcessor):  # 唯一實作
    def charge(self, amount): ...

# caller 只有一處：
processor = StripePaymentProcessor()
processor.charge(100)
```

```typescript
// 只 return 一種具體型別的 factory
class NotifierFactory {
    static create(type: "email"): EmailNotifier {  // type 永遠是 "email"
        return new EmailNotifier();
    }
}
```

```python
# 只有一個分支的 feature flag
if config.use_new_path:
    return new_implementation()
# 沒有 else，舊路徑直接刪掉了——這就只是 dead config
```

### 怎麽辨識

- **抽象 / interface 只有一個具體實作**。
- **factory / strategy / visitor pattern 只處理一種 case**。
- **新加的 hook / extension point 沒有真實 caller**。
- **「爲了未來可擴展性」這類措辭的 comment**。

### 怎麽驗證

- **grep 找實作 / caller**：`rg "class.*PaymentProcessor"`、`rg "create\(.*\)"`，確認只有一處。
- **問 task 有沒有要求**：task 沒要求 plugin / extension / multi-backend，加抽象就是 over。

### Review 講法

> `<file>:<line>` — `PaymentProcessor` 抽象目前只有 `StripePaymentProcessor` 一個實作，且
> task 沒提到要支援多個 payment provider。建議移除 ABC，直接用 `StripePaymentProcessor`
> 並重命名爲 `PaymentProcessor`，需要多 provider 時再抽。

---

## 8. Comment-as-implementation / 多餘 comment

### 長相

```python
# Iterate over each user
for user in users:
    # Get the user's email
    email = user.email
    # Send the email
    send(email)
```

```typescript
// removed: oldFunction()  ← 屍體標記
// TODO: handle this properly later  ← 沒 owner、沒日期
// This is a helper function to compute the sum of two numbers
function add(a: number, b: number): number { return a + b; }
```

```python
def process_orders(orders):
    """
    This function processes orders.

    It takes a list of orders and processes them.

    Args:
        orders: A list of orders to process.

    Returns:
        The processed orders.
    """
    return [process(o) for o in orders]
```

### 怎麽辨識

- **comment 在重述行爲**而非解釋「爲什麽」「不顯眼的限制」「歷史 incident」。
- **trivial helper 的長 docstring**。
- **`// removed`、`// old code`、`# was: foo()` 等屍體標記**。
- **無 owner / 無日期的 TODO**。

### 怎麽驗證

- 直接讀。

### Review 講法

> `<file>:<line>` — comments 重述了下一行程式碼在做什麽（變數名已經夠清楚），建議刪掉。
> 真的需要寫 comment 時，請解釋 *爲什麽* 這樣做（例如某個 edge case、上游限制），而不是
> *做了什麽*。

---

## 9. 未經請求的 backward compat / dead code

### 長相

```python
# task: rename old_func to new_func
def new_func(x):
    return x * 2

def old_func(x):  # 沒被任何人 call 了
    """Deprecated, use new_func instead."""
    return new_func(x)
```

```typescript
// task: 把 status 從 enum 改成 union type
export type Status = "active" | "inactive";
// 順便保留舊 enum 「以防萬一」
export enum StatusEnum {
    Active = "active",
    Inactive = "inactive",
}
```

```python
# task: 刪掉 unused parameter
def fetch(url, _legacy_timeout=None):  # 沒被用，但被「保留」
    ...
```

### 怎麽辨識

- **task 是 refactor / rename / cleanup，但 diff 同時新增了相容層**。
- **`@deprecated`、`_legacy_*`、`Old*`、`*V1` 命名**。
- **沒被 call 的新公開 API**（grep usage 找不到）。

### 怎麽驗證

- `rg <symbol>` 看新增 / 保留的東西有沒有被 call。
- 對照 task 看是否要求保留 backward compat。沒要求就移除。

### Review 講法

> `<file>:<line>` — `old_func` 已經沒 caller（`rg "old_func\b"` 只剩這個定義），task 也沒
> 要求保留 backward compat。建議直接刪掉，未來真的需要時用 git 找回來。

---

## 10. Build / type check pass ≠ 行爲正確

### 長相

- TypeScript：`as any` / `as Foo` cast 蒙混過 type check，runtime crash。
- Rust：`unwrap()` 處處塞，cargo build 過了，特定 input 一跑 panic。
- LLVM IR pass：build 跟測試小 case 都過，但 instrumentation 沒實際插到目標 BB（attribute
  寫到錯的 metadata key、Module-level vs Function-level 弄錯）。
- Migration：schema 改完 `migrate` 指令成功，但 backfill 沒做 / 沒做完，runtime 失敗。

### 怎麽辨識

- **大量 cast / unwrap / `!` non-null assertion**。
- **改了 framework 配置卻沒驗證 runtime 反映**。
- **改了 instrumentation / pass / codegen 卻只跑 unit test 沒 dump 中間產物**。

### 怎麽驗證

- 對應**層級**驗證：
  - LLVM pass：`opt -S` dump 出 IR，grep 你應該插入的指令在不在；用 `llvm-dis`、`opt -print-after`
    對照 before/after。
  - Type system：除了 `tsc --noEmit`，再跑實際 unit test 把 cast 後的物件用一下。
  - Migration：跑 forward + rollback + 真實資料 backfill 驗證；不要只信 `migrate ok`。
  - Fuzzing instrumentation：把 instrumented binary 對小 corpus 跑一輪，看 coverage map /
    aflgo distance 等是否如預期變化。

### Review 講法

> `<file>:<line>` — LLVM pass 看起來插入了 instrumentation call，但沒看到 IR-level 驗證。
> 建議跑 `opt -S -load ... -my-pass < input.ll` dump 出來，confirm `@__instrument_bb` call
> 真的出現在每個 target BB 開頭。型別過 / 編譯過不代表 pass 真的有作用。

---

## 通用：「太乾淨」本身是個 flag

人類寫的 bug-free code 通常有「妥協痕跡」——一個迴避 edge case 的 if、一段「之前踩過坑」的
comment、一個看起來怪但有原因的順序。AI agent 寫的 code 經常**過於整齊**，所有 case 都被一個
elegant pattern 完美處理。

當你在 review 時覺得「哇好乾淨，沒什麽好挑的」，**這是一個訊號**——回頭問：

- 它真的處理了 task 提到的所有 edge case 嗎？
- 它在 production 真實流量下會 fail 在哪裏？
- 它對 codebase 的其他部分有沒有隱含假設（譬如假設某個 service 永遠在線、某個 cache key
  從不衝突）？

整齊不是 bug，但**整齊到沒摩擦力**值得多看兩眼。
