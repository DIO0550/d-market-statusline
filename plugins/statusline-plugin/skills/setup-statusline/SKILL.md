---
name: setup-statusline
description: Powerlineスタイルのステータスラインをセットアップする。「ステータスライン設定」「statusline setup」「ステータスバー」などのリクエスト時に使用。
---

# ステータスライン セットアップ

Powerlineスタイルのステータスラインをプロジェクトに設定するスキル。

## 前提条件

- **Claude Code 2.1.97+** 推奨（`refreshInterval` と `workspace.git_worktree` のサポート）
- **Nerd Font** がターミナルにインストールされていること（Powerlineセパレータ `\uE0B0`・ブランチアイコン `\uE0A0`・ワークツリーアイコン `\uF1BB` を使用）
- **jq** がインストールされていること

## セットアップ手順

以下の手順を **順番に** 実行する。

### 1. スクリプトのパスを特定

スクリプトは marketplace プラグインディレクトリ内にある。以下のコマンドでパスを確認する。

```bash
find ~/.claude/plugins/marketplaces -name "statusline.sh" -path "*/d-market-statusline/*" 2>/dev/null
```

見つかったパスを `<script_path>` として以降の手順で使用する。
典型的なパスは `~/.claude/plugins/marketplaces/d-market-statusline/plugins/statusline-plugin/scripts/statusline.sh` である。

`find` が 0 件を返した場合（ローカルプラグイン構成など）は、`${CLAUDE_SKILL_DIR}/../../scripts/statusline.sh` の絶対パス（`realpath "${CLAUDE_SKILL_DIR}/../../scripts/statusline.sh"` 等）をフォールバックとして使用する。

### 2. スクリプトに実行権限を付与

```bash
chmod +x <script_path>
```

### 3. 設定ファイルを更新

Claude Code の設定ファイルには優先度がある。**必ず最優先のファイルに設定する。**

| ファイル | 優先度 |
|---------|--------|
| `.claude/settings.local.json` | **最高**（存在する場合はこちらを更新） |
| `.claude/settings.json` | 中 |
| `~/.claude/settings.json` | 低 |

**手順:**

1. まず `.claude/settings.local.json` が存在するか確認する
2. 存在する場合は `.claude/settings.local.json` を更新する
3. 存在しない場合は `.claude/settings.json` を更新する

更新対象のファイルを読み込み、`statusLine` フィールドを追加または更新する。

**重要:** `<script_path>` には marketplace プラグインディレクトリのパス（または手順1のフォールバック絶対パス）を使用し、キャッシュディレクトリのパスは使用しない。

設定内容:

```json
{
  "statusLine": {
    "type": "command",
    "command": "<script_path>",
    "refreshInterval": 5
  }
}
```

- ファイルが存在しない場合は新規作成
- 既存のフィールドがある場合はそれを保持し、`statusLine` のみ追加/上書き
- `<script_path>` は手順1で取得した絶対パスに置き換え
- `refreshInterval` はステータスラインの自動更新間隔（秒）。設定すると会話ターンの切り替え以外でも指定秒数ごとに更新される（Claude Code 2.1.97+）。推奨値は `5`

> **注意:** `settings.local.json` に古い `statusLine` 設定が残っていると、`settings.json` を更新しても反映されない。

### 4. 完了メッセージ

セットアップ完了後、以下をユーザーへ伝える:

- ステータスラインが設定されたこと
- Claude Code を **再起動** すると反映されること
- Nerd Font 対応ターミナルが必要なこと

## カラーテーマ

**Blue + Orange accent** を採用（256色モード）。

| 要素 | 256色コード | 色 | 用途 |
|------|------------|-----|------|
| Powerline 1番目 (L1-2) | 24 | 濃いブルー | パス / モデル名 |
| Powerline 2番目 (L1-2) | 31 | 明るいブルー | Git ブランチ / セッション経過時間 |
| Powerline 3番目 (L1-2) | 172 | ソフトオレンジ | 変更行数 / コンテキスト使用率 |
| 進捗バー（使用分 `█`） | 215 | ライトオレンジ | 5時間 / 7日レート制限の使用量 |
| 進捗バー（残余 `░`）・区切り線・worktree | 240 | グレー | バー背景・区切り線・worktree 名 |
| PR 番号 | 208 | オレンジ | PR 番号（`#N`） |
| 文字色 | 255 | 白 | Powerline セグメント・レート制限テキスト |

## 表示内容

`scripts/statusline.sh` の出力構成（Powerline 2行 + 区切り線 + 条件付き情報行 + レート制限プログレスバー 2行）:

```
 …/work/d-market  main  (+0,-0)
 Opus 4.6  Block: 0hr 23m  Ctx: 48.0%
─────────────────────────────
  feature-x
 PR #42
 Current  █ █ █ ░ ░ ░ ░ ░ ░ ░  28%  ↻ 21:00

 Weekly   █ █ █ █ █ █ ░ ░ ░ ░  59%  ↻ 03/26 13:00
```

| 要素 | 表示条件 | 表示内容 |
|------|---------|---------|
| Powerline 1行目 | 常時 | 作業パス（短縮） / Git ブランチ / 変更行数 `(+追加,-削除)` |
| Powerline 2行目 | 常時 | モデル名 / セッション経過時間 `Block: Xhr Ym` / コンテキスト使用率 `Ctx: N.N%` |
| 区切り線 | 常時 | 水平罫線（`─────────────────────────────`） |
| Worktree 行 | Git worktree 内のみ | ワークツリーアイコン + ワークツリー名 |
| PR 行 | PR 紐づき時のみ | PR 番号（通常環境は OSC 8 クリック可能リンク、Docker/コンテナ環境は URL 併記） |
| 5時間レート制限行 | 常時 | `Current` + 10ブロック進捗バー + 使用率 + リセット時刻（JST `HH:MM`） |
| 空行 | 常時 | `Current` 行と `Weekly` 行のスペーサー |
| 7日レート制限行 | 常時 | `Weekly` + 10ブロック進捗バー + 使用率 + リセット日時（JST `MM/DD HH:MM`） |
