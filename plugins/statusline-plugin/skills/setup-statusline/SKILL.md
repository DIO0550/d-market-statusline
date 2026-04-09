---
name: setup-statusline
description: Powerlineスタイルのステータスラインをセットアップする。「ステータスライン設定」「statusline setup」「ステータスバー」などのリクエスト時に使用。
---

# ステータスライン セットアップ

Powerlineスタイルの4行ステータスラインをプロジェクトに設定するスキル。

## 前提条件

- **Claude Code 2.1.97+** 推奨（`refreshInterval` と `workspace.git_worktree` のサポート）
- **Nerd Font** がターミナルにインストールされていること（Powerlineセパレータ `\uE0B0` とブランチアイコン `\uE0A0` を使用）
- **jq** がインストールされていること

## セットアップ手順

以下の手順を **順番に** 実行してください。

### 1. スクリプトのパスを特定

スクリプトは marketplace プラグインディレクトリ内にあります。以下のコマンドでパスを確認してください。

```bash
find ~/.claude/plugins/marketplaces -name "statusline.sh" -path "*/d-market-statusline/*" 2>/dev/null
```

見つかったパスを `<script_path>` として以降の手順で使用してください。
典型的なパスは `~/.claude/plugins/marketplaces/d-market-statusline/plugins/statusline-plugin/scripts/statusline.sh` です。

### 2. スクリプトに実行権限を付与

```bash
chmod +x <script_path>
```

### 3. 設定ファイルを更新

Claude Code の設定ファイルには優先度があります。**必ず最優先のファイルに設定してください。**

| ファイル | 優先度 |
|---------|--------|
| `.claude/settings.local.json` | **最高**（存在する場合はこちらを更新） |
| `.claude/settings.json` | 中 |
| `~/.claude/settings.json` | 低 |

**手順:**

1. まず `.claude/settings.local.json` が存在するか確認する
2. 存在する場合は `.claude/settings.local.json` を更新する
3. 存在しない場合は `.claude/settings.json` を更新する

更新対象のファイルを読み込み、`statusLine` フィールドを追加または更新してください。

**重要:** `<script_path>` には必ず marketplace プラグインディレクトリのパスを使用してください。キャッシュディレクトリのパスは使用しないでください。

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

> **注意:** `settings.local.json` に古い `statusLine` 設定が残っていると、`settings.json` を更新しても反映されません。

### 3. 完了メッセージ

セットアップ完了後、以下を伝えてください:

- ステータスラインが設定されたこと
- Claude Code を **再起動** すると反映されること
- Nerd Font 対応ターミナルが必要なこと

## カラーテーマ

**Blue + Orange accent** を採用（256色モード）。

| セグメント | 256色コード | 色 | 表示内容 |
|-----------|------------|-----|---------|
| 1番目 (L1-2) | 24 | 濃いブルー | パス / モデル名 |
| 2番目 (L1-2) | 31 | 明るいブルー | ブランチ / セッション時間 |
| 3番目 (共通) | 172 | ソフトオレンジ | 変更行数 / コンテキスト / リセット時刻 |
| 1番目 (L3-4) | 29 | ダークティール | 制限ラベル |
| 2番目 (L3-4) | 37 | ティール | 使用率 |
| 文字色 | 255 | 白 | 全セグメント共通 |

## 表示内容

```
 …/work/d-market  main  (+0,-0)
 Opus 4.6  Block: 0hr 23m  Ctx: 48.0%
 5hr Limit  Used: 28%  Reset: 21:00
 7day Limit  Used: 59%  Reset: 03/26 13:00
```

Git worktree 内で作業している場合、ブランチ名の横にワークツリー名が表示されます:

```
 …/work/d-market  main  feature-x  (+0,-0)
```

| 行 | セグメント1 | セグメント2 | セグメント3 |
|----|-----------|-----------|-----------|
| 1行目 | 作業パス（短縮） | Git ブランチ（worktree 内はワークツリー名も表示） | 変更行数 (+追加,-削除) |
| 2行目 | モデル名 | セッション経過時間 | コンテキスト使用率 |
| 3行目 | 5時間制限ラベル | 使用率 | リセット時刻 (HH:MM) |
| 4行目 | 7日制限ラベル | 使用率 | リセット日時 (MM/DD HH:MM) |
