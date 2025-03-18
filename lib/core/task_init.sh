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

# 初期タスクファイルの作成
create_initial_tasks_file() {
    local tasks_file="$TASKS_DIR/tasks.yaml"
    log $LOG_LEVEL_INFO "Creating initial tasks file: $tasks_file"
    
    cat > "$tasks_file" << 'EOF'
tasks: []
EOF
    
    log $LOG_LEVEL_INFO "Initial tasks file created"
}

# プロジェクト表示ファイルの作成
create_project_tasks_file() {
    local project_file="$TASKS_DIR/project.tasks"
    log $LOG_LEVEL_INFO "Creating project tasks file: $project_file"
    
    touch "$project_file"
    log $LOG_LEVEL_INFO "Project tasks file created"
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