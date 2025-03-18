# Task Management System

YAMLベースのタスク管理システム。コマンドラインから簡単にタスクの作成、編集、削除、表示が可能です。

## 機能

- タスクの作成 (`task add`)
- タスクの編集 (`task edit`)
- タスクの削除 (`task delete`)
- タスクの一覧表示 (`task list`)
- タスクの詳細表示 (`task show`)
- タスクのステータス変更 (`task status`)
- タスクの階層構造管理（親子関係）
- 自動バックアップ機能
- テンプレートベースのタスク表示

## システム要件

- bash 4.0以上
- yq (YAML処理用)
- git (バージョン管理用)

## インストール

1. リポジトリのクローン:
```bash
git clone [repository-url]
cd yaml.tasks
```

2. 必要なディレクトリの作成:
```bash
mkdir -p tasks/{backups,templates,config}
```

3. 初期設定:
```bash
cp config/template_config.yaml.example tasks/config/template_config.yaml
```

## 使用方法

### タスクの作成

```bash
./task.sh add -n "タスク名" -d "説明" -c "懸念事項"
```

オプション:
- `-n, --name`: タスク名（必須）
- `-d, --description`: タスクの説明
- `-c, --concerns`: 懸念事項
- `-p, --parent`: 親タスクのID

### タスクの編集

```bash
./task.sh edit -i "タスクID" -n "新しいタスク名" -d "新しい説明" -c "新しい懸念事項"
```

オプション:
- `-i, --id`: 編集するタスクのID（必須）
- `-n, --name`: 新しいタスク名
- `-d, --description`: 新しい説明
- `-c, --concerns`: 新しい懸念事項
- `-p, --parent`: 新しい親タスクのID

### タスクの削除

```bash
./task.sh delete -i "タスクID"
```

### タスクの一覧表示

```bash
./task.sh list
```

### タスクの詳細表示

```bash
./task.sh show -i "タスクID"
```

### タスクのステータス変更

```bash
./task.sh status -i "タスクID" -s "新しいステータス"
```

ステータス:
- `not_started`: 未着手
- `in_progress`: 進行中
- `completed`: 完了

## ディレクトリ構造

```
yaml.tasks/
├── README.md
├── task.sh
├── lib/
│   ├── commands/
│   │   ├── task_add.sh
│   │   ├── task_delete.sh
│   │   ├── task_edit.sh
│   │   ├── task_list.sh
│   │   ├── task_show.sh
│   │   └── task_status.sh
│   ├── core/
│   │   ├── template_engine.sh
│   │   └── yaml_processor.sh
│   └── utils/
│       ├── common.sh
│       └── validators.sh
└── tasks/
    ├── backups/
    ├── config/
    ├── templates/
    ├── tasks.yaml
    └── project.tasks
```

## バックアップ

- タスクの編集時に自動的にバックアップが作成されます
- バックアップは `tasks/backups/` ディレクトリに保存されます
- バックアップファイル名には作成日時が含まれます

## テンプレート

- タスクの表示形式はテンプレートで管理されます
- テンプレートは `tasks/templates/` ディレクトリに保存されます
- テンプレート設定は `tasks/config/template_config.yaml` で管理されます

## エラーハンドリング

- 存在しないタスクIDの指定
- 存在しない親タスクIDの指定
- 必須パラメータの欠落
- YAMLファイルの構文エラー
- バックアップ作成の失敗

## 開発者向け情報

### モジュール構成

- `commands/`: 各コマンドの実装
- `core/`: コアロジックの実装
- `utils/`: ユーティリティ関数

### デバッグモード

環境変数 `DEBUG=1` を設定することで、詳細なログが出力されます：

```bash
DEBUG=1 ./task.sh [command]
```

### テスト

```bash
./test/run_tests.sh
```

## ライセンス

[ライセンス情報] 