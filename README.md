# YAMLベースのタスク管理システム 🗂️

シンプルで使いやすいYAMLベースのタスク管理システムです。コマンドラインから簡単にタスクを追加、編集、削除できます。階層的なタスク管理が可能で、視覚的にわかりやすい出力を提供します。

## 特徴 ✨

- シンプルなコマンドラインインターフェース
- YAMLベースのデータストレージ
- 階層的なタスク管理（親タスク・サブタスク）
- カスタマイズ可能なテンプレート
- 完了タスクのチェックマーク表示 (✅)
- 詳細なタスク記述（説明・懸念点など）
- 複数タスクの一括追加機能
- カスタムタスクID対応
- 柔軟なタスクステータス管理
- データ検証と同期機能

## インストール方法 🚀

GitHubからリポジトリをクローンし、インストールスクリプトを実行します。

```bash
git clone https://github.com/your-username/yaml.tasks.git
cd yaml.tasks
./install.sh
```

インストールスクリプトは、必要なファイルを `~/.local/bin/` ディレクトリにコピーします。インストール後、`task` コマンドをどこからでも実行できるようになります。

## 使い方 📝

### システム初期化

```bash
# 新しいプロジェクトディレクトリでタスク管理システムを初期化
task start

# 既存システムの再初期化（タスクデータは保持）
task init

# 強制的に再初期化
task init --force
```

### タスクの追加

```bash
# 単一タスクの追加
task add -n "タスク名"

# 詳細情報付きでタスクを追加
task add -n "タスク名" -d "詳細説明" -c "懸念点"

# サブタスクの追加 (親タスクIDを指定)
task add -n "サブタスク名" -p TA01

# 複数タスクを一度に追加
task add -n "タスク1,タスク2,タスク3"

# 複数サブタスクを一度に追加
task add -n "サブタスク1,サブタスク2" -p TA01

# カスタムプレフィックスでタスクを追加
task add -n "特別タスク" --prefix "SP"

# 特定の番号から開始する連番タスク
task add -n "連番タスク" --start-num 100
```

### サブタスクの専用コマンド

```bash
# サブタスクの追加（親タスクIDを指定）
task subtask -p TA01 -n "サブタスク名"

# 複数のサブタスクを追加
task subtask -p TA01 -n "サブタスク1,サブタスク2,サブタスク3"

# 詳細情報付きでサブタスクを追加
task subtask -p TA01 -n "サブタスク名" -d "詳細説明" -c "懸念点"
```

### タスクの一覧表示

```bash
# すべてのタスクを表示
task list

# 完了済みタスクのみ表示
task list --completed

# 未完了タスクのみ表示
task list --not-completed
```

### タスクの詳細表示

```bash
# タスクIDを指定して詳細表示
task show -i TA01
```

### タスクの編集

```bash
# タスク名を編集
task edit -i TA01 -n "新しいタスク名"

# タスクの説明を編集
task edit -i TA01 -d "新しい説明"

# タスクの懸念点を編集
task edit -i TA01 -c "新しい懸念点"

# タスクの状態を変更（完了/未完了）
task edit -i TA01 -s completed  # または not_completed
```

### タスクのステータス管理

```bash
# タスクのステータスを変更
task status -i TA01 -s completed

# 複数タスクのステータスを一括変更
task status -i "TA01,TA02,TA03" -s in_progress

# ステータス一覧の表示
task status --list
```

### タスクの削除

```bash
# タスクIDを指定して削除
task delete -i TA01

# 複数タスクを一括削除
task delete -i "TA01,TA02"
```

### データの検証と同期

```bash
# タスクデータの検証
task validate

# タスクデータの同期
task sync

# 特定のディレクトリへの同期
task sync --dir /path/to/backup
```

### テンプレートの管理

```bash
# 現在のテンプレートを表示
task template --show

# 利用可能なテンプレート一覧を表示
task template --list

# テンプレートを使用
task template --use <テンプレート名>

# 新しいテンプレートを作成
task template --create <テンプレート名>
```

### システム管理

```bash
# タスク管理システムを最新版に更新
task update

# 強制的に更新
task update --force

# 特定のリポジトリから更新
task update --repo <URL>
```

### システムのアンインストール

```bash
# タスク管理システムをアンインストール
task uninstall

# データを保持してアンインストール
task uninstall --keep-data

# 確認なしで強制的にアンインストール
task uninstall --force
```

## ディレクトリ構造 📂

```
~/.local/bin/
├── task                # メインの実行ファイル
├── lib/                # ライブラリファイル
│   ├── commands/       # コマンド実装
│   ├── core/           # コア機能
│   └── utils/          # ユーティリティ関数
└── tasks/              # タスクデータ
    ├── templates/      # 出力テンプレート
    ├── backups/        # バックアップファイル
    └── config/         # 設定ファイル
```

プロジェクトディレクトリで `task start` を実行すると、以下のような構造が作成されます：

```
your-project/
└── tasks/
    ├── templates/      # 出力テンプレート
    ├── backups/        # バックアップファイル
    ├── config/         # 設定ファイル
    ├── tasks.yaml      # タスクデータ
    └── project.tasks   # フォーマットされたタスク出力
```

## 必要なシステム要件 🔧

- bash 4.0以上
- yq コマンド（YAML処理用）
- Linux または macOS

## エラー処理 🚨

タスク管理システムは、一般的なエラー（存在しないタスクIDの指定、不正なオプションの使用など）を検出して適切なエラーメッセージを表示します。

## ライセンス 📄

このプロジェクトはMITライセンスの下で公開されています。詳細はLICENSEファイルを参照してください。 