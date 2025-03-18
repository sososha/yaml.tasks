#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 共通ユーティリティの読み込み
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/validators.sh"
source "${SCRIPT_DIR}/../core/yaml_processor.sh"
source "${SCRIPT_DIR}/../core/template_engine.sh"

# タスク管理システムのルートディレクトリを設定（未定義の場合のみ）
if [[ -z "$TASK_DIR" ]]; then
    TASK_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
fi

# ヘルプ表示
show_add_help() {
    cat << EOF
Usage: task add [options] 
Add a new task to the task management system.

Options:
  -n, --name <n>            Task name (required, multiple tasks separated by comma)
  -s, --status <status>     Task status (default: not_started)
                           Valid values: not_started, in_progress, completed
  -d, --description <text>  Task description
  -c, --concerns <text>     Task concerns
  -p, --parent <id>         Parent task ID
  -h, --help               Show this help message

Examples:
  task add -n "実装タスク" -s "in_progress" -d "機能実装" -c "最適化が必要"
  task add -n "タスク1,タスク2" -s "not_started"
  task add -n "サブタスク" -p "TA01" -s "not_started"
EOF
}

# メイン処理
main() {
    local names=""
    local status="not_started"
    local description=""
    local concerns=""
    local parent_id=""
    
    # オプションの解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_add_help
                return 0
                ;;
            -n|--name)
                names="$2"
                shift 2
                ;;
            -s|--status)
                status="$2"
                shift 2
                ;;
            -d|--description)
                description="$2"
                shift 2
                ;;
            -c|--concerns)
                concerns="$2"
                shift 2
                ;;
            -p|--parent)
                parent_id="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_add_help
                return 1
                ;;
        esac
    done
    
    # 必須パラメータのチェック
    if [[ -z "$names" ]]; then
        log_error "Task name is required"
        show_add_help
        return 1
    fi
    
    # 親タスクの存在確認
    if [[ -n "$parent_id" ]]; then
        if ! task_exists "$parent_id"; then
            log_error "Parent task not found: $parent_id"
            return 1
        fi
    fi
    
    # コンマ区切りの名前を配列に分割
    IFS=',' read -ra name_array <<< "$names"
    
    # 各タスクを追加
    for name in "${name_array[@]}"; do
        if ! add_task "$name" "$status" "$description" "$concerns" "$parent_id"; then
            log_error "Failed to add task: $name"
            continue
        fi
        log_info "Added task: $name"
    done
    
    # テンプレートからタスクファイルを生成
    if ! generate_task_file_from_template; then
        log_error "Failed to generate task file from template"
        return 1
    fi
    log_info "Template generated successfully"
    
    return 0
}

# スクリプトとして実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 