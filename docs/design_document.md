# タスク管理システム設計ドキュメント

## 1. 設計思想

### 1.1 基本理念
- **シンプルさ**: 不必要な複雑さを避け、直感的に使えるシステム
- **データと表示の分離**: データ構造と表示形式を明確に分離
- **AI連携**: AIによる操作を前提とした設計
- **カスタマイズ性**: ユーザーの好みに合わせて表示形式を調整可能
- **堅牢性**: データの整合性を保ち、破損を防止

### 1.2 設計原則
- YAMLをデータストレージとして使用し、構造化されたデータを保持
- テンプレートを使用して柔軟な表示形式を実現
- コマンドラインインターフェースを通じてのみデータを操作
- Gitによるバージョン管理を前提とした設計
- コンマ区切りの引数で複数タスクの一括操作をサポート

## 2. システム構成

### 2.1 ファイル構造
```
/Users/sososha/Documents/task.sh/
├── tasks/
│   ├── tasks.yaml          # タスクデータ（内部用）
│   └── project.tasks       # ユーザー向け表示ファイル
├── templates/
│   ├── default.template    # デフォルトテンプレート
│   ├── compact.template    # コンパクト表示用テンプレート
│   └── detailed.template   # 詳細表示用テンプレート
├── config/
│   └── template_config.yaml  # テンプレート設定ファイル
├── lib/
│   ├── core/
│   │   ├── task_processor.sh     # 基本的なタスク処理関数
│   │   ├── yaml_processor.sh     # YAMLデータ操作関数
│   │   ├── task_init.sh         # 初期化処理関数
│   │   └── template_engine.sh    # テンプレート処理関数
│   ├── commands/
│   │   ├── task_init.sh         # 初期化コマンド
│   │   ├── task_add.sh           # タスク追加コマンド
│   │   ├── task_subtask.sh       # サブタスク追加コマンド
│   │   ├── task_status.sh        # ステータス変更コマンド
│   │   ├── task_list.sh          # タスク一覧表示コマンド
│   │   ├── task_sync.sh          # データと表示の同期コマンド
│   │   ├── task_sort.sh          # タスク並び替えコマンド
│   │   └── task_template.sh      # テンプレート操作コマンド
│   └── utils/
│       ├── common.sh             # 共通ユーティリティ関数
│       └── validators.sh         # 入力検証関数
├── docs/
│   └── design_document.md        # 設計ドキュメント
└── task.sh                       # メインスクリプト
```

### 2.2 データモデル
```yaml
# tasks.yaml
tasks:
  - id: PA01
    name: "タスク1"
    status: "not_started"
    parent: null
    details:
      content: "タスク内容の詳細"
      design: "設計思想"
      concerns: "懸念事項"
      results: ""
      result_concerns: ""
  - id: PB01
    name: "サブタスク1-1"
    status: "not_started"
    parent: "PA01"
    details:
      content: "サブタスク内容"
      design: "サブタスク設計思想"
      concerns: ""
      results: ""
      result_concerns: ""
```

### 2.3 テンプレート設定
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

## 3. コンポーネント詳細

### 3.1 コアモジュール

#### 3.1.0 task_init.sh
タスク管理システムの初期化を担当するモジュール。

**主要関数**:
- `initialize_task_system()`: タスク管理システムの初期化
  - tasksディレクトリの作成
  - 必要なサブディレクトリの作成
  - 初期設定ファイルの配置
  - デフォルトテンプレートの配置
- `validate_system_requirements()`: 必要なツール（yq, jq）の存在確認
- `create_initial_structure()`: ディレクトリ構造の作成

**使用例**:
```bash
task start        # システムの初期化
task init         # 既存のシステムの再初期化（データは保持）
```

#### 3.1.1 yaml_processor.sh
YAMLデータの操作を担当するモジュール。タスクの追加、更新、削除などの基本操作を提供。

**主要関数**:
- `load_tasks()`: YAMLからタスクデータを読み込む
- `save_tasks()`: タスクデータをYAMLに保存
- `add_task()`: 新しいタスクを追加
- `update_task_status()`: タスクのステータスを更新
- `get_task_by_id()`: IDでタスクを取得
- `get_child_tasks()`: 親IDに基づいて子タスクを取得

#### 3.1.2 template_engine.sh
テンプレートを使用してYAMLデータから.tasksファイルを生成するモジュール。

**主要関数**:
- `load_template_config()`: テンプレート設定を読み込む
- `generate_from_template()`: テンプレートを適用してファイルを生成
- `update_template_config()`: テンプレート設定を変更

#### 3.1.3 task_processor.sh
高レベルのタスク処理ロジックを提供するモジュール。

**主要関数**:
- `process_add_task()`: タスク追加処理
- `process_subtask()`: サブタスク追加処理
- `process_status_change()`: ステータス変更処理
- `validate_task_data()`: タスクデータの検証

### 3.2 コマンドモジュール

### 3.2.0 メインコマンドインターフェース
すべてのコマンドは単一の`task`コマンドのサブコマンドとして実装されます。

**基本構造**:
```bash
task <subcommand> [options] [arguments]
```

**主要サブコマンド**:
- `start`: システムの初期化
- `init`: システムの再初期化
- `add`: タスクの追加
- `subtask`: サブタスクの追加
- `status`: ステータスの変更
- `list`: タスク一覧の表示
- `template`: テンプレートの操作
- `sync`: データと表示の同期
- `sort`: タスクの並び替え

#### 3.2.1 task_add.sh
新しいタスクを追加するコマンド。コンマ区切りの引数で複数タスクの一括追加をサポート。

**使用例**:
```bash
task add "タスク名" "ステータス" "詳細" "考慮事項"
task add "タスク1,タスク2,タスク3" "未着手,進行中,未着手"
```

#### 3.2.2 task_subtask.sh
親タスクの下にサブタスクを追加するコマンド。

**使用例**:
```bash
task subtask "親タスクID" "サブタスク名" "ステータス" "詳細" "考慮事項"
task subtask "PA01" "サブタスク1,サブタスク2" "未着手,未着手"
```

#### 3.2.3 task_template.sh
テンプレートの操作を行うコマンド。

**使用例**:
```bash
task template use "detailed"
task template config "symbol.completed" "✅"
task template generate
```

## 4. 処理フロー

### 4.1 タスク追加フロー
1. ユーザーが `task add` コマンドを実行
2. `task_add.sh` がコマンドライン引数を解析
3. コンマ区切りの場合は複数タスクに分割
4. 各タスクに対して:
   a. `yaml_processor.sh` の `add_task()` を呼び出してYAMLデータを更新
   b. 新しいタスクIDを生成
5. `template_engine.sh` の `generate_from_template()` を呼び出して.tasksファイルを再生成
6. 成功メッセージを表示

### 4.2 テンプレート変更フロー
1. ユーザーが `task template config` コマンドを実行
2. `task_template.sh` がコマンドライン引数を解析
3. `template_engine.sh` の `update_template_config()` を呼び出して設定を更新
4. `generate_from_template()` を呼び出して.tasksファイルを再生成
5. 成功メッセージを表示

## 5. AI連携

### 5.1 AIによる操作
システムはAIによる操作を前提として設計されています。AIは以下のような操作を行うことができます:

- 複数タスクの一括追加: `task add "タスク1,タスク2,タスク3"`
- 複数サブタスクの一括追加: `task subtask "親ID" "サブタスク1,サブタスク2"`
- テンプレート設定の変更: `task template config "format.indent_char" "    "`

### 5.2 AIへの指示例
ユーザーがAIに「タスク1、タスク2、タスク3を追加して」と指示した場合、AIは以下のコマンドを生成します:

```bash
task add "タスク1,タスク2,タスク3" "未着手,未着手,未着手"
```

## 6. 移行戦略

### 6.1 既存データの移行
既存のタスクデータを新しいYAML形式に移行するための手順:

1. 既存のタスクファイルを解析
2. タスクの階層構造と詳細情報を抽出
3. YAMLデータを生成
4. テンプレートを適用して.tasksファイルを生成

### 6.2 移行コマンド
```bash
task migrate
```

## 7. 拡張性と将来の展望

### 7.1 将来の拡張可能性
- タグ付け機能の追加
- 優先度の設定
- 期限日の追加
- フィルタリングと検索機能の強化
- 複数プロジェクトの管理

### 7.2 拡張方法
データモデルとテンプレートの柔軟な設計により、新しい機能を追加する際にも大幅な変更を必要としません。新しい属性をYAMLデータモデルに追加し、テンプレートを更新するだけで対応可能です。

## 8. 結論

このタスク管理システムは、データと表示の分離、テンプレートによるカスタマイズ、AI連携を重視した設計となっています。シンプルさを保ちながらも、柔軟性と拡張性を備えたシステムを目指しています。YAMLデータ形式とテンプレートエンジンの組み合わせにより、ユーザーは自分の好みに合わせてタスク表示をカスタマイズすることができます。

AIとの連携を前提とした設計により、複雑なコマンドを覚える必要なく、自然言語での指示でタスク管理を行うことができます。また、Gitによるバージョン管理を前提としているため、タスクの変更履歴を追跡することも容易です。

シンプルなコマンドラインインターフェースと柔軟なデータ構造の組み合わせにより、使いやすさと機能性を両立したタスク管理システムとなっています。
