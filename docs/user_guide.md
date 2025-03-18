# タスク管理システム ユーザーガイド

## 1. はじめに

このタスク管理システムは、YAMLベースのシンプルで柔軟なタスク管理ツールです。コマンドラインインターフェースを通じて操作し、Gitによるバージョン管理をサポートしています。

### 1.1 特徴
- シンプルで直感的な操作
- YAMLデータ形式による堅牢なデータ管理
- テンプレートによる柔軟な表示カスタマイズ
- 複数タスクの一括操作サポート
- Gitによるバージョン管理

### 1.2 システム要件
- bash 4.0以上
- yq（YAMLプロセッサ）
- jq（JSONプロセッサ）
- Git

## 2. インストールと初期設定

### 2.1 システムの初期化
```bash
# タスク管理システムの初期化
task start

# 既存システムの再初期化（データは保持）
task init
```

### 2.2 初期設定の確認
```bash
# 設定の確認
task template show
```

## 3. 基本的な使い方

### 3.1 タスクの追加
```bash
# 単一タスクの追加
task add "タスク名" -d "タスクの詳細" -p "優先度"

# 複数タスクの一括追加
task add "タスク1,タスク2,タスク3" -s "未着手,進行中,未着手"
```

### 3.2 サブタスクの追加
```bash
# 単一サブタスクの追加
task subtask "親タスクID" "サブタスク名" -d "詳細"

# 複数サブタスクの一括追加
task subtask "親タスクID" "サブタスク1,サブタスク2" -s "未着手,未着手"
```

### 3.3 タスクの状態変更
```bash
# タスクのステータス変更
task status "タスクID" "進行中"
```

### 3.4 タスクの一覧表示
```bash
# 全タスクの表示
task list

# 詳細表示
task list -f detailed

# ステータスでフィルタリング
task list -s "進行中"
```

## 4. テンプレートの使用

### 4.1 テンプレートの切り替え
```bash
# デフォルトテンプレートの使用
task template use default

# 詳細テンプレートの使用
task template use detailed
```

### 4.2 テンプレート設定のカスタマイズ
```bash
# 完了タスクの表示記号を変更
task template config "symbols.completed" "✅"

# インデント文字の変更
task template config "format.indent_char" "    "
```

## 5. データの同期と管理

### 5.1 データの同期
```bash
# タスクデータと表示の同期
task sync

# 強制同期
task sync -f

# バックアップを作成して同期
task sync -b
```

### 5.2 データの検証
```bash
# データ整合性の検証
task validate

# タスクデータのみ検証
task validate -d
```

## 6. タスクの整理

### 6.1 タスクの並び替え
```bash
# 名前でソート
task sort name

# ステータスでソート（降順）
task sort status desc
```

### 6.2 タスクの検索
```bash
# キーワードで検索
task list -q "検索キーワード"
```

## 7. トラブルシューティング

### 7.1 一般的な問題と解決方法
1. タスクファイルが同期されない
   - `task sync -f` で強制同期を試す
   - `task validate` でデータの整合性を確認

2. テンプレートが適用されない
   - `task template show` で現在の設定を確認
   - `task template reset` でデフォルト設定に戻す

3. タスクIDが重複する
   - `task validate` でデータの整合性を確認
   - 必要に応じて `task init` で再初期化

### 7.2 エラーメッセージの意味
- "無効なタスクID": タスクIDの形式が正しくありません
- "親タスクが見つかりません": 指定された親タスクが存在しません
- "循環参照を検出": タスクの親子関係に循環参照があります

## 8. ベストプラクティス

### 8.1 効率的なタスク管理
1. タスクは適切な粒度で作成する
2. サブタスクを活用して大きなタスクを分割する
3. 定期的にタスクの状態を更新する
4. 完了したタスクは速やかにマークする

### 8.2 データ管理のヒント
1. 定期的にバックアップを作成する
2. Gitでコミットを適切に行う
3. データの整合性を定期的に確認する
4. テンプレートを活用して見やすい表示にする

## 9. 付録

### 9.1 コマンド一覧
- `task start`: システムの初期化
- `task init`: システムの再初期化
- `task add`: タスクの追加
- `task subtask`: サブタスクの追加
- `task status`: ステータスの変更
- `task list`: タスク一覧の表示
- `task template`: テンプレートの管理
- `task sync`: データの同期
- `task sort`: タスクの並び替え
- `task validate`: データの検証

### 9.2 設定ファイルの構造
```yaml
# template_config.yaml
current_template: "default"
symbols:
  completed: "✓"
  in_progress: "◎"
  not_started: "□"
format:
  indent_char: "  "
  task_separator: "\n"
  section_separator: "\n\n"
sections:
  - name: "Tasks"
    enabled: true
  - name: "Details"
    enabled: true
``` 