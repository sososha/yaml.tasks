# Task.sh

シンプルで階層的なYAMLベースのタスク管理ツール

## 特徴

- YAMLベースのシンプルなタスク管理
- 4階層までの詳細な階層的タスク構造
- 直感的なコマンドラインインターフェース
- マークダウンフォーマットでのタスク表示
- ✅ 完了タスクの視覚的表示
- 自動バックアップ機能
- テンプレートベースのカスタマイズ可能な表示
- カスタムプレフィックスによるタスク分類（PA, BUG, FEATなど）
- コマンド一つで簡単アップデート

## インストール

### GitHubからのインストール

```bash
git clone https://github.com/username/task.sh.git
cd task.sh/yaml.tasks
./install.sh
```

### 直接インストール

```bash
curl -sSL https://raw.githubusercontent.com/username/task.sh/main/yaml.tasks/install.sh | bash
```

## 使い方

1. プロジェクトディレクトリで初期化：
```bash
cd your-project
task start
```

2. タスクの追加：
```bash
task add -n "タスク名" -d "説明" -c "懸念事項"
```

3. タスク一覧の表示：
```bash
task list
```

4. ヘルプの表示：
```bash
task --help
```

## コマンド一覧

- `task start` : タスク管理を開始（初期化）
- `task add` : タスクを追加
- `task list` : タスク一覧を表示
- `task edit` : タスクを編集
- `task delete` : タスクを削除
- `task subtask` : サブタスクを追加
- `task status` : タスクのステータスを変更
- `task template` : タスク表示テンプレートを管理
- `task update` : タスク管理システムを最新版に更新

## 階層的なタスク管理

Task.shでは、4階層までの詳細なタスク階層を管理できます：

```
## TA01 [in_progress] プロジェクト管理
説明: プロジェクト全体の管理
懸念事項: スケジュール管理が重要

  ## TA04 [in_progress] スケジュール管理

    ## TA13 ✅ 週次計画
    説明: 毎週の進捗確認
    懸念事項: 遅延の早期検出

      ## TA22 ✅ 担当者割当
      説明: 担当者の決定
```

親子関係のあるタスクはインデントで表現され、視覚的に把握しやすくなっています。

## タスクのステータス

タスクには以下の3つのステータスがあります：

- `not_started` : 未着手（デフォルト）
- `in_progress` : 進行中
- `completed` : 完了（✅で表示）

## 使用方法

### タスクの作成

```bash
task add -n "タスク名" -d "説明" -c "懸念事項"
```

オプション:
- `-n, --name`: タスク名（必須）
- `-d, --description`: タスクの説明
- `-c, --concerns`: 懸念事項
- `-p, --parent`: 親タスクのID
- `--prefix`: タスクIDのプレフィックス（TA, PA, BUG など、デフォルト: TA）
- `--start-num`: タスクID番号の開始値

### カスタムプレフィックスの使用

タスクの種類に応じて異なるプレフィックスを使用できます：

```bash
# プロジェクトAのタスク
task add -n "仕様策定" --prefix "PA"  # 例: PA01

# バグ修正タスク
task add -n "表示崩れの修正" --prefix "BUG"  # 例: BUG02

# 新機能開発
task add -n "認証機能追加" --prefix "FEAT"  # 例: FEAT03
```

タスクIDは全体で連続した番号が付与されるため、プレフィックスが変わっても新しいタスクには必ず次の番号が使われます。

### サブタスクの追加

```bash
task subtask -p "親タスクID" -n "サブタスク名" -d "説明"
```

または

```bash
task add -p "親タスクID" -n "サブタスク名"
```

### 複数タスクの一括追加

```bash
task add -n "タスク1,タスク2,タスク3" -p "親タスクID"
```

### タスクの編集

```bash
task edit -i "タスクID" -n "新しいタスク名" -d "新しい説明" -c "新しい懸念事項"
```

オプション:
- `-i, --id`: 編集するタスクのID（必須）
- `-n, --name`: 新しいタスク名
- `-d, --description`: 新しい説明
- `-c, --concerns`: 新しい懸念事項
- `-p, --parent`: 新しい親タスクのID

### タスクの削除

```bash
task delete -i "タスクID"
```

### タスクの一覧表示

```bash
task list
```

オプション:
- `-a, --all`: すべてのタスクを表示（デフォルト）
- `-c, --completed`: 完了したタスクのみ表示
- `-i, --in-progress`: 進行中のタスクのみ表示
- `-n, --not-started`: 未着手のタスクのみ表示

### テンプレートの管理

```bash
task template --list          # 利用可能なテンプレート一覧
task template --show          # 現在のテンプレートを表示
task template --use minimal   # 指定したテンプレートを使用
task template --create custom # 新しいテンプレートを作成
```

### システムの更新

```bash
task update                  # 最新版に更新
task update --force          # 確認なしで更新
task update --repo <URL>     # 特定のリポジトリから更新
```

## プロジェクト設定

プロジェクトの設定は `tasks/config/project_config.yaml` で管理されます：

```yaml
# タスク管理の設定
prefix: "TA"  # デフォルトのタスクIDプレフィックス
auto_numbering: true  # 自動採番を行うかどうか
start_number: 1  # 自動採番の開始番号
```

## ディレクトリ構造

タスク管理を開始すると、以下のディレクトリ構造が作成されます：

```
your-project/
└── tasks/
    ├── tasks.yaml        # タスクデータ（YAML形式）
    ├── project.tasks     # タスク一覧表示（マークダウン形式）
    ├── backups/          # バックアップファイル
    ├── config/           # 設定ファイル
    │   └── project_config.yaml  # プロジェクト設定
    └── templates/        # 表示テンプレート
```

## システム要件

- bash 4.0以上
- yq (YAML処理用)
- git (バージョン管理用、および更新機能)

## バックアップと安全性

- タスクの編集・削除時に自動的にバックアップが作成されます
- バックアップは `tasks/backups/` ディレクトリに保存され、日時が付与されます
- 誤って削除してもバックアップから復元できます

## 開発者向け情報

### モジュール構成

- `commands/`: 各コマンドの実装
- `core/`: コアロジック（YAML処理、テンプレートエンジン）
- `utils/`: ユーティリティ関数と検証機能

### デバッグモード

環境変数 `DEBUG=1` を設定することで、詳細なログが出力されます：

```bash
DEBUG=1 task [command]
```

## ライセンス

MIT License 