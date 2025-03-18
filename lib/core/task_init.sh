#!/bin/bash

# タスク管理システムの初期化を担当するコアモジュール

# 共通ユーティリティ関数の読み込み
source "$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/validators.sh"

# システム要件の検証
validate_system_requirements() {
    log $LOG_LEVEL_INFO "Validating system requirements..."
    
    # 必要なコマンドの存在確認
    local required_commands=("yq" "jq" "git")
    for cmd in "${required_commands[@]}"; do
        check_dependency "$cmd"
        log $LOG_LEVEL_DEBUG "Found required command: $cmd"
    done
    
    log $LOG_LEVEL_INFO "System requirements validation completed"
}

# 初期ディレクトリ構造の作成
create_initial_structure() {
    log $LOG_LEVEL_INFO "Creating initial directory structure..."
    
    # tasksディレクトリとサブディレクトリの作成
    local directories=(
        "$TASKS_DIR"
        "$TEMPLATES_DIR"
        "$CONFIG_DIR"
    )
    
    for dir in "${directories[@]}"; do
        create_directory "$dir"
    done
    
    log $LOG_LEVEL_INFO "Directory structure creation completed"
}

# 指定されたディレクトリに初期ディレクトリ構造を作成
create_initial_structure_in_dir() {
    local TARGET_DIR="$1"
    log $LOG_LEVEL_INFO "指定されたディレクトリに初期構造を作成します: $TARGET_DIR"
    
    # ディレクトリの作成
    local TASKS_DIR_PATH="$TARGET_DIR/tasks"
    local TEMPLATES_DIR_PATH="$TASKS_DIR_PATH/templates"
    local CONFIG_DIR_PATH="$TASKS_DIR_PATH/config"
    
    mkdir -p "$TASKS_DIR_PATH"
    mkdir -p "$TEMPLATES_DIR_PATH"
    mkdir -p "$CONFIG_DIR_PATH"
    
    log $LOG_LEVEL_INFO "ディレクトリ構造の作成が完了しました"
}

# デフォルトのテンプレートファイルを作成
create_default_template() {
    local template_file="$TEMPLATES_DIR/default.template"
    log $LOG_LEVEL_INFO "Creating default template file: $template_file"
    
    cat > "$template_file" << 'EOF'
# タスク一覧

{{#each tasks}}
{{#if parent}}{{indent_level parent}}{{/if}}{{status_symbol status}} {{id}}: {{name}}
{{#if details.content}}
{{#if parent}}{{indent_level parent}}{{/if}}  内容: {{details.content}}
{{/if}}
{{#if details.design}}
{{#if parent}}{{indent_level parent}}{{/if}}  設計: {{details.design}}
{{/if}}
{{#if details.concerns}}
{{#if parent}}{{indent_level parent}}{{/if}}  懸念: {{details.concerns}}
{{/if}}
{{#if details.results}}
{{#if parent}}{{indent_level parent}}{{/if}}  結果: {{details.results}}
{{/if}}
{{#if details.result_concerns}}
{{#if parent}}{{indent_level parent}}{{/if}}  結果の懸念: {{details.result_concerns}}
{{/if}}
{{/each}}
EOF
    
    log $LOG_LEVEL_INFO "Default template file created"
}

# 指定されたディレクトリにデフォルトテンプレートを作成
create_default_template_in_dir() {
    local TARGET_DIR="$1"
    local template_file="$TARGET_DIR/tasks/templates/default.template"
    log $LOG_LEVEL_INFO "デフォルトテンプレートを作成します: $template_file"
    
    cat > "$template_file" << 'EOF'
# タスク一覧

{{#each tasks}}
{{#if parent}}{{indent_level parent}}{{/if}}{{status_symbol status}} {{id}}: {{name}}
{{#if details.content}}
{{#if parent}}{{indent_level parent}}{{/if}}  内容: {{details.content}}
{{/if}}
{{#if details.design}}
{{#if parent}}{{indent_level parent}}{{/if}}  設計: {{details.design}}
{{/if}}
{{#if details.concerns}}
{{#if parent}}{{indent_level parent}}{{/if}}  懸念: {{details.concerns}}
{{/if}}
{{#if details.results}}
{{#if parent}}{{indent_level parent}}{{/if}}  結果: {{details.results}}
{{/if}}
{{#if details.result_concerns}}
{{#if parent}}{{indent_level parent}}{{/if}}  結果の懸念: {{details.result_concerns}}
{{/if}}
{{/each}}
EOF
    
    log $LOG_LEVEL_INFO "デフォルトテンプレートを作成しました"
}

# デフォルトの設定ファイルを作成
create_default_config() {
    local config_file="$CONFIG_DIR/template_config.yaml"
    log $LOG_LEVEL_INFO "Creating default configuration file: $config_file"
    
    cat > "$config_file" << 'EOF'
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
EOF
    
    log $LOG_LEVEL_INFO "Default configuration file created"
}

# 指定されたディレクトリにデフォルト設定を作成
create_default_config_in_dir() {
    local TARGET_DIR="$1"
    local config_file="$TARGET_DIR/tasks/config/template_config.yaml"
    log $LOG_LEVEL_INFO "デフォルト設定ファイルを作成します: $config_file"
    
    cat > "$config_file" << 'EOF'
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
EOF
    
    log $LOG_LEVEL_INFO "デフォルト設定ファイルを作成しました"
}

# 初期タスクファイルの作成
create_initial_tasks_file() {
    local tasks_file="$TASKS_DIR/tasks.yaml"
    log $LOG_LEVEL_INFO "Creating initial tasks file: $tasks_file"
    
    cat > "$tasks_file" << 'EOF'
tasks: []
EOF
    
    log $LOG_LEVEL_INFO "Initial tasks file created"
}

# 指定されたディレクトリに初期タスクファイルを作成
create_initial_tasks_file_in_dir() {
    local TARGET_DIR="$1"
    local tasks_file="$TARGET_DIR/tasks/tasks.yaml"
    log $LOG_LEVEL_INFO "初期タスクファイルを作成します: $tasks_file"
    
    cat > "$tasks_file" << 'EOF'
tasks: []
EOF
    
    log $LOG_LEVEL_INFO "初期タスクファイルを作成しました"
}

# プロジェクト表示ファイルの作成
create_project_tasks_file() {
    local project_file="$TASKS_DIR/project.tasks"
    log $LOG_LEVEL_INFO "Creating project tasks file: $project_file"
    
    touch "$project_file"
    log $LOG_LEVEL_INFO "Project tasks file created"
}

# 指定されたディレクトリにプロジェクト表示ファイルを作成
create_project_tasks_file_in_dir() {
    local TARGET_DIR="$1"
    local project_file="$TARGET_DIR/tasks/project.tasks"
    log $LOG_LEVEL_INFO "プロジェクトタスクファイルを作成します: $project_file"
    
    touch "$project_file"
    log $LOG_LEVEL_INFO "プロジェクトタスクファイルを作成しました"
}

# Gitの初期化
initialize_git() {
    if [ ! -d "$TASK_ROOT/.git" ]; then
        log $LOG_LEVEL_INFO "Initializing Git repository..."
        
        cd "$TASK_ROOT" || handle_error "Failed to change directory to $TASK_ROOT"
        git init || handle_error "Failed to initialize Git repository"
        
        # .gitignoreの作成
        cat > .gitignore << 'EOF'
*.bak
*.tmp
.DS_Store
EOF
        
        # 初期コミット
        git add . || handle_error "Failed to stage files"
        git commit -m "Initial commit: Task management system setup" || handle_error "Failed to create initial commit"
        
        log $LOG_LEVEL_INFO "Git repository initialized"
    else
        log $LOG_LEVEL_DEBUG "Git repository already exists"
    fi
}

# 指定されたディレクトリでGitを初期化
initialize_git_in_dir() {
    local TARGET_DIR="$1"
    
    if [ ! -d "$TARGET_DIR/.git" ]; then
        log $LOG_LEVEL_INFO "Gitリポジトリを初期化します: $TARGET_DIR"
        
        # 現在のディレクトリを保存
        local CURRENT_DIR=$(pwd)
        
        # 指定されたディレクトリに移動
        cd "$TARGET_DIR" || handle_error "ディレクトリの変更に失敗しました: $TARGET_DIR"
        
        # Gitリポジトリを初期化
        git init || handle_error "Gitリポジトリの初期化に失敗しました"
        
        # .gitignoreの作成
        cat > .gitignore << 'EOF'
*.bak
*.tmp
.DS_Store
EOF
        
        # 初期コミット
        git add . || handle_error "ファイルのステージングに失敗しました"
        git commit -m "🎉 タスク管理システムを初期化" || handle_error "初期コミットの作成に失敗しました"
        
        # 元のディレクトリに戻る
        cd "$CURRENT_DIR"
        
        log $LOG_LEVEL_INFO "Gitリポジトリを初期化しました"
    else
        log $LOG_LEVEL_DEBUG "Gitリポジトリは既に存在しています"
    fi
}

# タスク管理システムの初期化
initialize_task_system() {
    log $LOG_LEVEL_INFO "Initializing task management system..."
    
    # システム要件の検証
    validate_system_requirements
    
    # ディレクトリ構造の作成
    create_initial_structure
    
    # 各種ファイルの作成
    create_default_template
    create_default_config
    create_initial_tasks_file
    create_project_tasks_file
    
    # Gitの初期化
    initialize_git
    
    log $LOG_LEVEL_INFO "Task management system initialization completed"
}

# 指定されたディレクトリにタスク管理システムを初期化する関数
initialize_task_system_in_dir() {
    local TARGET_DIR="$1"
    log $LOG_LEVEL_INFO "指定されたディレクトリでタスク管理システムを初期化します: $TARGET_DIR"
    
    # システム要件の検証
    validate_system_requirements
    
    # ディレクトリ構造の作成
    create_initial_structure_in_dir "$TARGET_DIR"
    
    # 各種ファイルの作成
    create_default_template_in_dir "$TARGET_DIR"
    create_default_config_in_dir "$TARGET_DIR"
    create_initial_tasks_file_in_dir "$TARGET_DIR"
    create_project_tasks_file_in_dir "$TARGET_DIR"
    
    # Gitの初期化
    initialize_git_in_dir "$TARGET_DIR"
    
    log $LOG_LEVEL_INFO "タスク管理システムの初期化が完了しました"
}

# 既存のシステムの再初期化（データは保持）
reinitialize_task_system() {
    log $LOG_LEVEL_INFO "Re-initializing task management system..."
    
    # システム要件の検証
    validate_system_requirements
    
    # 既存のファイルのバックアップ
    if [ -f "$TASKS_DIR/tasks.yaml" ]; then
        backup_file "$TASKS_DIR/tasks.yaml"
    fi
    if [ -f "$TASKS_DIR/project.tasks" ]; then
        backup_file "$TASKS_DIR/project.tasks"
    fi
    
    # ディレクトリ構造の確認と作成
    create_initial_structure
    
    # テンプレートと設定の再作成（既存の場合はスキップ）
    if [ ! -f "$TEMPLATES_DIR/default.template" ]; then
        create_default_template
    fi
    if [ ! -f "$CONFIG_DIR/template_config.yaml" ]; then
        create_default_config
    fi
    
    log $LOG_LEVEL_INFO "Task management system re-initialization completed"
}

# 指定されたディレクトリで既存のシステムを再初期化する関数
reinitialize_task_system_in_dir() {
    local TARGET_DIR="$1"
    log $LOG_LEVEL_INFO "指定されたディレクトリでタスク管理システムを再初期化します: $TARGET_DIR"
    
    # システム要件の検証
    validate_system_requirements
    
    # 既存のファイルのバックアップ
    local TASKS_YAML="$TARGET_DIR/tasks/tasks.yaml"
    local PROJECT_TASKS="$TARGET_DIR/tasks/project.tasks"
    
    if [ -f "$TASKS_YAML" ]; then
        cp "$TASKS_YAML" "${TASKS_YAML}.bak"
        log $LOG_LEVEL_INFO "タスクファイルをバックアップしました: ${TASKS_YAML}.bak"
    fi
    
    if [ -f "$PROJECT_TASKS" ]; then
        cp "$PROJECT_TASKS" "${PROJECT_TASKS}.bak"
        log $LOG_LEVEL_INFO "プロジェクトタスクファイルをバックアップしました: ${PROJECT_TASKS}.bak"
    fi
    
    # ディレクトリ構造の確認と作成
    create_initial_structure_in_dir "$TARGET_DIR"
    
    # テンプレートと設定の再作成（既存の場合はスキップ）
    if [ ! -f "$TARGET_DIR/tasks/templates/default.template" ]; then
        create_default_template_in_dir "$TARGET_DIR"
    fi
    
    if [ ! -f "$TARGET_DIR/tasks/config/template_config.yaml" ]; then
        create_default_config_in_dir "$TARGET_DIR"
    fi
    
    # タスクファイルの作成（存在しない場合のみ）
    if [ ! -f "$TASKS_YAML" ]; then
        create_initial_tasks_file_in_dir "$TARGET_DIR"
    fi
    
    # プロジェクトタスクファイルの作成（存在しない場合のみ）
    if [ ! -f "$PROJECT_TASKS" ]; then
        create_project_tasks_file_in_dir "$TARGET_DIR"
    fi
    
    log $LOG_LEVEL_INFO "タスク管理システムの再初期化が完了しました"
} 