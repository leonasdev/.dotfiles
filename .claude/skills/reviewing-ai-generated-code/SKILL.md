---
name: reviewing-ai-generated-code
description: >
  深度 review 另一個 AI agent (Cursor, Copilot Agent, Gemini CLI, ChatGPT, 其他 Claude session 等)
  或 AI-輔助同事完成的 code 變更，從 reviewer 角度驗證實作正確、能 work、品質達標。
  觸發情境包含使用者說「同事用 AI 寫了 X，幫我 review」「另一個 AI 完成的，pull 下來看一下」
  「幫我詳細 review 這個 branch / PR / commit」「我同事推了 code，幫我看」
  「這是 Cursor / Copilot Agent 做的，幫我審查」「幫我 code review」、提到拉取一個分支或 PR
  並要求審查、或附上與其他 AI 的對話紀錄、task spec 並要求驗證實作的場景。
  重點是 AI agent 寫的 code 有特定失敗模式 (hallucinated APIs、silent fallback、表面合理但實際錯誤、
  testing theater、spec drift、over-engineering)，這些跟人類寫的 code 不一樣，要用對應的方法檢查。
  這個 skill 是 *reviewer 視角*——不是請別人 review 自己的 code (那是 requesting-code-review)，
  也不是處理收到的 review (receiving-code-review)。
  Leon 收到同事 push 上來的 AI-輔助 commit / PR 並請你 review 時，請主動使用此 skill，即使他沒
  明確要求。
---

# Reviewing AI-Generated Code

這個 skill 處理一個越來越常見的情境：使用者的同事（或他自己另一個 session）讓某個 AI agent
——Cursor、Copilot Agent、Gemini CLI、ChatGPT、另一個 Claude——寫或改了 code，現在這份變更
擺在你面前要你 review。你的工作是確認**這份變更實際上做到了它聲稱做到的事**，能在 production
跑，而且品質可以接受。

## 為什麽需要這個 skill

AI 寫出來的 code 跟人類寫的有不同的失敗分布。資深工程師寫出來的 code 可能醜但會 work；AI agent
寫出來的 code 經常**長得很漂亮但不 work**——命名好、結構乾淨、註解齊全、testing 完整，仔細看
才發現呼叫了不存在的 API、或測試其實沒測到該測的東西、或實作只覆蓋了一半 case。

所以**不能用美感、命名、test 通過就相信變更是好的**，必須驗證行爲。這個 skill 把對 AI-generated
code 該怎麽 review 的流程系統化，並列出 AI 特有的失敗模式，讓你不會漏掉。

## 心態：diff 是「待驗證的聲明」

把每一塊 diff 當成是「**作者聲稱**他做了 X」的 claim，你的工作是驗證這個 claim 是否屬實。
這跟 review 人類同事的 code 有本質差別——人類同事大致知道自己在改什麽，AI agent 經常不知道
自己 hallucinate 了東西、不知道測試是不是真的有測、不知道某個 branch 是否會跑到。

具體來說，不要假設：
- 「commit message 說修了 bug X」⇒ bug X 真的被修了
- 「tests pass」⇒ code 是對的（只代表 AI 寫的 test 通過了 AI 寫的 code）
- 「import 了 `foo.bar`」⇒ `foo.bar` 真的存在
- 「有 try/except」⇒ 錯誤處理是對的（很可能是吞掉錯誤）
- 「看起來像同類 PR 在 codebase 的其他地方那樣寫」⇒ 邏輯正確

## AI agent 常見的失敗模式

以下是要特別注意的模式。詳細範例與識別方法見 `references/ai-failure-patterns.md`，
**在你開始逐行檢查前先讀一次該檔**。

1. **Hallucinated APIs / symbols**：呼叫了「假如 library 結構合理應該存在」但實際不存在的
   method、import 了不存在的 module、傳了不存在的 keyword argument。
2. **看似合理但跑不到的 control flow**：永遠 true / false 的條件、漏掉的 `await`、
   side-effect 後才 return 的順序錯誤、被 short-circuit 的 branch。
3. **Silent fallback / 過度寬鬆的 exception handling**：`except Exception: pass`、
   `except: return None`、`except: return []`，把任務要回報的錯誤吞掉。
4. **Mock 偽裝成 real**：函數 body 回傳寫死的值，docstring 卻說它查資料庫；部分實作標 TODO
   或乾脆省略；用 `NotImplementedError` 但 caller 沒處理。
5. **Testing theater（測試裝樣子）**：`assert True`、`assert result is not None` 不檢查內容、
   test 名稱說 test X 但 body 在 test Y、test 輸入走的 code path 跟 real call site 不一樣、
   mock 把要測的東西也 mock 掉。
6. **Spec drift（規格漂移）**：實作了「跟使用者要求的*類似*」的東西，但不是真正要求的。
   常發生在跟 AI 多輪對話後，某個早期 constraint 被遺忘。
7. **Over-engineering**：單一 caller 卻拉 abstract base class、factory 只 return 一種具體型別、
   依賴注入沒有 alternative implementation、feature flag 只有一個分支。
8. **Comment-as-implementation**：用 comment 描述「程式碼做了什麽」來代替正確地做；或在顯而易見
   的地方堆滿 comment；保留 `// removed X` 的死碼標記。
9. **未經請求的 backward compat / dead code**：加了相容層、`_legacy` wrapper、留下不再使用的
   舊路徑，task 沒要求他做這些。
10. **Build / type check pass ≠ 行爲正確**：尤其在 typed language 中，型別對了不代表邏輯對。
    在 fuzzing / 編譯器 / IR 這類工具中更要做 IR 層級的驗證（譬如 instrumentation 是否真的插入
    到正確的 BB、metadata 是否正確攜帶）。

## Review 流程

### Phase 1：先收集 context，再看 diff

在開 diff 前，先確定下列資訊（缺哪些就主動跟使用者要）：

1. **原始 task 是什麽？** 使用者給另一個 AI 的 prompt / spec / issue。沒有這個你只能 review
   「code 是不是合法」，而**沒辦法 review「code 是不是做到了該做的事」**。
2. **跟 AI 的對話紀錄（如果有）**：讀一遍。對話中經常透露 AI 在哪裏卡住、使用者中途追加了哪些
   constraint、AI 聲稱「現在修好了」但沒驗證的點——這些是高機率 bug 集中地。
3. **review 的範圍**：是哪個 branch、哪個 PR、base 是什麽？確認 `git diff <base>...HEAD`
   涵蓋的就是要 review 的東西。
4. **codebase 背景**：讀 README、CLAUDE.md、package manifest，理解這個 repo 的慣例；
   不熟的話，先讀變更 touch 到的檔案上下文，避免「按通用標準」judge 而錯失 repo-specific 的約定。
5. **已經跑過什麽**：另一個 AI 跑過 test 嗎？使用者跑過嗎？CI 結果？這些是已知信號，但**不能取代
   你自己 run**。

### Phase 2：Map the changes

```
git status                              # 工作區是否乾淨
git log --oneline <base>..HEAD          # commit 範圍
git diff --stat <base>...HEAD           # 哪些檔案、量多少
git diff <base>...HEAD                  # 完整 diff
```

把改動分類：production code / test / config / docs / generated。對於 generated 檔案
（lock files、auto-formatted files），確認**它跟對應的 source 變更 consistent**（譬如改了
`package.json` 但沒更新 `package-lock.json` 是個 flag）。

### Phase 3：對每塊改動建立 mental model

對每個有意義的 hunk，在腦中回答：

- 這塊改動**想做什麽**？
- 它跟使用者給 AI 的 task description 對得起來嗎？
- 對不起來的話，AI 的對話紀錄中有給合理理由嗎？還是 spec 漂移了？
- 如果你說不出這塊改動爲什麽要存在，**這本身就是發現**——要嘛是不必要的改動，要嘛是你還沒看
   懂，兩種都值得深入。

### Phase 4：逐行驗證正確性

對每塊非 trivial 的改動：

- **被呼叫到的東西是否存在？** 看到 `something.foo()`、`from pkg import bar`，去 grep、
  讀 library source、必要時打開 `node_modules` / `site-packages` 確認。**不要假設另一個 AI
  查過**。
- **追 control flow**：用一兩個代表性輸入在腦中跑過所有 branch。哪裏 return？變動了什麽 state？
  有沒有 unreachable branch？
- **Edge cases**：empty input、null/None、單元素、邊界值、concurrent、大輸入、malformed、
  缺 config——對每一種問「這份改動會怎麽行爲？是 task 要求的行爲嗎？」
- **錯誤路徑**：有沒有 `try/except` / `catch` 把該往上拋的錯誤吞掉？有沒有 fallback 把真正
  的 failure 蓋成「看起來是空結果」？
- **State / side effects**：有寫檔、改 global、call external service 的，順序對嗎？
  中途失敗 cleanup 處理了嗎？
- **Concurrency / async**：少 `await`、少 lock、cross-thread 用非 thread-safe 結構、
  setup/teardown 競爭。

### Phase 5：驗證 tests 真的在 test

對每個新增 / 改的 test：

- **讀 assertion，不是讀 test 名**。叫 `test_handles_empty_input` 但只 `assert result is
  not None` 是在 test 空氣。
- **追 test 實際 exercise 了什麽 code path**。輸入是否走過要測的程式碼？還是被 mock 攔下來
  跳過？
- **設想一個 regression，這個 test 抓得到嗎？** 抓不到的 test 就是裝飾品。

### Phase 6：實際 run

「Tests pass」**不是**變更能 work 的證據——它只證明 AI 寫的 test suite 通過 AI 寫的 code。
獨立驗證：

- 自己跑相關的 test。
- 如果是 feature / bugfix，把對應的 workflow 端到端跑一次（script、command、UI flow）。
  UI 改動就開瀏覽器點；backend 改動就打 endpoint；CLI 改動就跑 command。
- 對於這個 repo 常見的深度變更（fuzzing instrumentation、編譯器 pass、IR-level 修改），
  在**對應層級**驗證——不要停在「build 過了」。譬如改 LLVM pass 就 dump IR 看 BB 是否真的
  被 instrument、改 corpus mutation 就 sample 幾筆 output 看結構符合預期。
- 真的沒環境 / 沒 fixture / 沒 credential 跑不了，**在 report 中明說**，不要含糊讓人以爲你
  驗證過。

### Phase 7：品質檢查

正確性 OK 之後再 sweep 一遍品質：

- **Over-engineering**：只有一個 caller 的抽象、只 return 一種型別的 factory、只有一個分支
  的 feature flag。
- **Comments**：重述程式碼在做什麽的 comment、trivial helper 的長 docstring、`// removed X`
  墓碑、無 owner 的 TODO。
- **Dead code / 沒被要求的 backward-compat shim**。
- **命名**：對得起 thing 做的事嗎？AI 喜歡濫用 `Service`、`Manager`、`Handler`、`Helper`。
- **跟 codebase 一致**：import 風格、error-handling 慣例、檔案組織——若 codebase 慣用
  `pathlib`，這次改動寫 `os.path` 就是 flag。

### Phase 8：分級

把發現分成三級：

- **Critical**：行爲錯、不會 work、回歸、安全問題、沒做到 task。**必須**修才能 merge。
- **Concerns**：merge 進去會實質降低 codebase 品質的問題——silent failure、無效 test、有真
  下游成本的 over-engineering。建議修。
- **Nits**：style / naming / comment 等小事。可選。

對等級要誠實。把 nit 列成 critical 會讓 review 沒法用；爲了客氣把 bug 降級會讓 review 變
危險。

## Report 結構

最後給使用者一份結構化 report。用以下模板（empty section 寫 `None.` 而不是刪掉，讓使用者
看到你**每一級都檢查過**）：

```markdown
## Review 概要
<2–4 句：是否做到 task、整體信心、最大 concern>

## 已驗證項目
- <實際跑過的指令，例 `pytest tests/foo`、`cargo build`、手動 workflow>
- <通過什麽、什麽因爲什麽原因沒驗證到>

## Critical issues
- **<file>:<line> — <短標題>**
  <錯在哪、爲什麽要緊、建議怎麽修>

## Concerns
- **<file>:<line> — <短標題>**
  <...>

## Nits
- <file>:<line> — <一行說明>

## 還不錯的地方
- <一兩個真正的優點；沒有就跳過這節>
```

## 該 push back 的時候要 push back

你是「第二雙眼睛」。使用者跟另一個 AI 已經對這份變更達成某種程度的接受，這讓你容易滑入「橡皮章
通過」。要主動抵抗這個傾向：

- **不要直接接受 AI / commit message 的敘述**。commit 說「fix bug X」就去驗證 bug X 真的修了
  ——很多時候只是某條 path 上的 symptom 被遮掉。
- **不要把「tests pass」當成功**。見上。
- **不要因爲 codebase 別處也這樣寫就接受**。如果這次改動引入了 silent failure，即使 codebase
  其他地方也有 silent failure，**還是要 flag**——既有的壞 pattern 被複製不是它變正確的理由。
- **不要爲了客氣把 finding 降級**。會壞就說會壞。使用者的工作是修，不是被你哄。

## 拿到對話紀錄時怎麽用

如果使用者貼了他跟另一個 AI 的對話紀錄，**先讀對話再看 diff**。對話裏要找：

- **後加的 constraint**——使用者中途追加的條件，最終 diff 是否反映了？
- **AI 單方面的決定**——「順便也 refactor 了 X」「我覺得這樣更好」這類使用者沒明確 bless 的改動，
  要格外仔細看。
- **AI 聲稱「修好了」「tests pass」的點**——這些是高機率 hallucination 集中區，逐一驗證。
- **使用者提到但 diff 裏沒看到的東西**——可能漏實作了。

對話紀錄通常比 diff 本身更可靠地告訴你「**diff 裏應該要有什麽**」。

## 進一步參考

- `references/ai-failure-patterns.md` — 每個失敗模式的具體例子 + 怎麽快速辨識 + 怎麽驗證
- `references/review-output-examples.md` — 不同情境下的 review report 範例（簡單變更、
  大型 PR、給的 task 太模糊時等）
