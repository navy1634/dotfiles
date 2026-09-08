# ADR: plan の明示参照と Approval の所有者

## Background

親エージェントが「承認済み」と自己申告したり、計画ファイルの Approval を代理で `[x]` に変更したりすると、ユーザーが計画全文を確認した事実を検証できません。また、generator が計画ファイルの場所を推測すると、意図しない計画を読んで実装する危険があります。

## Options Considered

### A. 親エージェントまたはサブエージェントが Approval を代理で変更する

親エージェントがユーザーの短い返答を解釈して checkbox を更新し、実装担当へ引き渡します。

### B. Approval checkbox だけを確認し、依頼文の承認主張や計画指定は検査しない

generator はファイルの `[x]` だけを根拠にし、計画名や計画なし経路を文脈から補います。

### C. ユーザーだけが Approval を変更し、work order の明示宣言と generator pre-check を必須にする

planner 経路では exact な `plan.md` を明示し、direct generator 経路では `No plan file is used for this route.` を明示します。親エージェントの承認済み主張を検出した場合は停止し、計画全文をユーザーへ提示して明示承認を得た後に再依頼します。

## Rejected Because

- A は、ユーザーの確認と承認を親エージェントの自己申告で置き換えるため不採用です。
- B は、Approval の状態だけでは承認経路と参照対象の計画を証明できず、意図しない計画の推測を許すため不採用です。

## Decision

C を採用します。計画は `.agents/plan/<slug>/plan.md` に保存し、`Approval` は計画全文を確認したユーザーだけが `[ ]` から `[x]` へ変更できます。親エージェント、planner、generator、evaluator は checkbox を変更せず、ユーザー承認を自己申告で代替しません。generator は明示された `## Plan` 宣言を読み、宣言がない場合は計画名、slug、パス、計画の有無を推測せず停止します。

## Rationale

Approval の操作主体と plan の参照対象を work order とファイル状態の両方で限定すると、承認の事実と実装対象を別々に検証できます。明白な承認済み主張を pre-check で止め、計画全文のユーザー確認へ戻すことで、親エージェントの自己申告を承認の代替にしません。

## Impact

- planner は unchecked の Approval を持つ plan だけを作成します。
- generator は、planner 経路では work order に明示された exact path だけを読み、direct route では明示された計画なし宣言だけを受け付けます。
- Approval の変更権限はユーザーに限定され、evaluator はその経路と ADR を独立して検証します。
- 今回のタスクはユーザーが計画なしを明示しているため、plan.md は作成しません。

## Unresolved Items or Review Conditions

- 実行環境で、親エージェントの承認済み主張を含む依頼が pre-check により停止し、ユーザーへの計画全文提示を促すことを確認する必要があります。
- Approval の表記を変更する場合は、planner、generator、orchestrate、plan command、evaluator の全参照を同時に見直します。
