#!/bin/bash

# タスク削除コマンド

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 共通ユーティリティの読み込み
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/validators.sh"
source "${SCRIPT_DIR}/../core/yaml_processor.sh"
source "${SCRIPT_DIR}/../core/template_engine.sh"

# ヘルプメッセージの表示
show_help() {
    cat << EOF
Usage: task delete <task_id> [task_id...]

Delete one or more tasks by their IDs.

Arguments:
    task_id     ID of the task to delete (e.g., TA01)

Options:
    -h, --help  Show this help message
EOF
}

# メイン処理
main() {
    # オプションの解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                return 0
                ;;
            *)
                break
                ;;
        esac
        shift
    done
    
    # 引数のチェック
    if [[ $# -eq 0 ]]; then
        log_error "タスクIDが指定されていません"
        show_help
        return 1
    fi
    
    # 各タスクIDに対して削除を実行
    local success=true
    for task_id in "$@"; do
        if ! delete_task "$task_id"; then
            log_error "タスクの削除に失敗しました: $task_id"
            success=false
        else
            log_info "タスクを削除しました: $task_id"
        fi
    done
    
    # テンプレートの再生成
    if ! generate_template; then
        log_error "テンプレートの生成に失敗しました"
        success=false
    fi
    
    if [[ "$success" = true ]]; then
        return 0
    else
        return 1
    fi
} 