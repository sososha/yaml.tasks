#!/bin/bash

# タスク管理システムの初期化コマンド

# 共通ユーティリティ関数とコア初期化モジュールの読み込み
source "$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/validators.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/task_init.sh"

# 使用方法の表示
show_init_help() {
    cat << EOF
使用法: task start/init [オプション]

タスク管理システムの初期化

コマンド:
  start              タスク管理システムの初期化
  init [--force]     システムの再初期化（データは保持）

オプション:
  --force    強制的に再初期化（既に初期化済みの場合）
  -h, --help このヘルプを表示

説明:
  start   - 初期ディレクトリ構造とファイルを作成します
  init    - 既存のタスクデータを保持したままシステムを再初期化します
EOF
}

# startコマンドの実装
task_start() {
    log_info "タスク管理システムの初期化を開始します..."
    
    # ヘルプの表示
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_init_help
        return 0
    fi
    
    # カレントディレクトリにタスクフォルダを設定
    local CURRENT_DIR="$(pwd)"
    local CURRENT_TASKS_DIR="${CURRENT_DIR}/tasks"
    
    # 既に初期化されているかチェック
    if [ -d "$CURRENT_TASKS_DIR" ] && [ -f "$CURRENT_TASKS_DIR/tasks.yaml" ]; then
        log_error "タスク管理システムは既に初期化されています"
        return 1
    fi
    
    # システムの初期化（カレントディレクトリに）
    initialize_task_system_in_dir "$CURRENT_DIR"
    
    log_info "タスク管理システムを初期化しました"
    echo "タスク管理を開始できます！"
    return 0
}

# initコマンドの実装
task_init() {
    log_info "タスク管理システムの再初期化を開始します..."
    
    # ヘルプの表示
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_init_help
        return 0
    fi
    
    # 強制再初期化オプションのチェック
    local force=false
    if [ "$1" = "--force" ]; then
        force=true
        shift
    fi
    
    # カレントディレクトリにタスクフォルダを設定
    local CURRENT_DIR="$(pwd)"
    local CURRENT_TASKS_DIR="${CURRENT_DIR}/tasks"
    
    # 初期化されているかチェック
    if [ ! -d "$CURRENT_TASKS_DIR" ] || [ ! -f "$CURRENT_TASKS_DIR/tasks.yaml" ]; then
        if [ "$force" = true ]; then
            log_warn "タスク管理システムは初期化されていません。新規に初期化します..."
            initialize_task_system_in_dir "$CURRENT_DIR"
        else
            log_error "タスク管理システムは初期化されていません。'task start'で初期化してください"
            return 1
        fi
    else
        # システムの再初期化（カレントディレクトリに）
        reinitialize_task_system_in_dir "$CURRENT_DIR"
    fi
    
    log_info "タスク管理システムを再初期化しました"
    echo "システムの再初期化が完了しました。既存のタスクデータは保持されています。"
    return 0
} 