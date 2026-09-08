# ADR: planner と generator の経路判定

## Background

planner と generator をすべての非軽微作業で必須にすると、作業規模に対して委託のオーバーヘッドが過大になる場合があります。一方、設計判断や複数ファイルを含む作業を直接実装へ流すと、要件整理と設計の抜けが生じます。

## Options Considered

### A. すべての非軽微作業で planner、generator、evaluator を固定する

既存の三役経路を維持し、作業規模にかかわらず同じ委託手順を適用します。

### B. planner は任意化するが generator は常に使う

小規模な作業では計画だけを省略し、generator と evaluator を固定します。

### C. planner は規模・設計リスクで、generator は委託効果とオーバーヘッドで選ぶ

軽微変更は client が直接実装します。小規模な実装は client または generator が担当し、中規模以上、複数コンポーネント、複数実装ファイル、設計判断、要件の曖昧さがある場合は planner を使います。いずれの実装担当を選んでも evaluator が独立検証します。

## Rejected Because

- A は、最小規模の作業で planner を省略する要件と、generator の委託オーバーヘッドを比較する要件に反します。
- B は、メインセッションが直接実装した方が効率的な小規模作業にも generator を要求します。

## Decision

C を採用します。planner は、既存の軽微変更の定義を最小規模の基準とし、複数コンポーネント、複数実装ファイル、設計判断、要件の曖昧さ、または中規模以上の作業で起動します。小規模な実装は、要件が明確で既存パターンに沿い新しい設計判断がない場合に限り、client または generator が実装して evaluator へ渡します。generator は、並行作業、専門性、規模、複雑さ、安全性、独立した実装担当の有効性が委託オーバーヘッドを上回る場合だけ使います。

## Rationale

planner の判定を設計の不確実性と規模に、generator の判定を委託効果とオーバーヘッドに分けると、実行者が作業の性質に応じて再現可能に経路を選べます。複数の実装ファイルは planner の起動条件ですが、作業に付随する ADR は実装ファイル数へ含めません。

## Impact

- 小規模な実装では、planner を使わずに client または generator から evaluator へ進めます。
- 中規模以上などの planner 経路では、ユーザー承認済みの plan を使った後、client または generator を委託効果で選びます。
- client が generator を省略した場合も、その理由と実装判断を ADR に記録し、evaluator の独立検証を受けます。

## Unresolved Items or Review Conditions

- 同じ規模の作業で経路判定が繰り返し揺れる場合は、実例を evaluator の指摘として集め、判定例または起動条件を見直します。
- 安全性や専門性の評価が変わる実行環境では、委託オーバーヘッドとの比較を再記録します。
