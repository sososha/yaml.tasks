#!/bin/bash

# タスク管理システムの初期化コマンド

# 共通ユーティリティ関数とコア初期化モジュールの読み込み
source "$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/validators.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/task_init.sh"

# 使用方法の表示
show_init_help() {
    cat << EOF
Task Management System - Initialization Commands

Usage:
    task start              Initialize the task management system
    task init [--force]     Re-initialize the system (preserves existing data)

Options:
    --force    Force re-initialization even if the system is already initialized
    -h, --help Show this help message

Description:
    start   - Creates the initial directory structure and files
    init    - Re-initializes the system while preserving existing task data
EOF
}

# startコマンドの実装
task_start() {
    log $LOG_LEVEL_INFO "Starting task management system initialization..."
    
    # ヘルプの表示
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_init_help
        exit 0
    fi
    
    # 既に初期化されているかチェック
    if [ -d "$TASKS_DIR" ] && [ -f "$TASKS_DIR/tasks.yaml" ]; then
        handle_error "Task management system is already initialized. Use 'task init' to re-initialize."
    fi
    
    # システムの初期化
    initialize_task_system
    
    log $LOG_LEVEL_INFO "Task management system has been initialized successfully"
    echo "You can now start managing your tasks!"
}

# initコマンドの実装
task_init() {
    log $LOG_LEVEL_INFO "Starting task management system re-initialization..."
    
    # ヘルプの表示
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_init_help
        exit 0
    fi
    
    # 強制再初期化オプションのチェック
    local force=false
    if [ "$1" = "--force" ]; then
        force=true
        shift
    fi
    
    # 初期化されているかチェック
    if [ ! -d "$TASKS_DIR" ] || [ ! -f "$TASKS_DIR/tasks.yaml" ]; then
        if [ "$force" = true ]; then
            log $LOG_LEVEL_WARN "Task management system is not initialized, performing fresh initialization..."
            initialize_task_system
        else
            handle_error "Task management system is not initialized. Use 'task start' for initial setup."
        fi
    else
        # システムの再初期化
        reinitialize_task_system
    fi
    
    log $LOG_LEVEL_INFO "Task management system has been re-initialized successfully"
    echo "System re-initialization complete. Existing task data has been preserved."
} 