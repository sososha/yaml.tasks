#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# タスク管理システムのルートディレクトリを設定
TASK_DIR="$(pwd)"
export TASK_DIR

# 共通の設定と関数をインポート
source "${SCRIPT_DIR}/utils/common.sh"
source "${SCRIPT_DIR}/utils/validators.sh"
source "${SCRIPT_DIR}/core/yaml_processor.sh"
source "${SCRIPT_DIR}/core/template_engine.sh"

# 必要なディレクトリとファイルの存在確認
ensure_directories() {
    mkdir -p "${TASK_DIR}/tasks/templates"
    mkdir -p "${TASK_DIR}/tasks/config"
    mkdir -p "${TASK_DIR}/tasks/backups"
    
    # テンプレートファイルが存在しない場合は作成
    if [[ ! -f "${TASK_DIR}/tasks/templates/default.template" ]]; then
        create_default_template
    fi
    
    # 設定ファイルが存在しない場合は作成
    if [[ ! -f "${TASK_DIR}/tasks/config/template_config.yaml" ]]; then
        create_default_config
    fi
    
    # タスクファイルの作成（存在しない場合）
    if [[ ! -f "${TASK_DIR}/tasks/tasks.yaml" ]]; then
        echo "tasks: []" > "${TASK_DIR}/tasks/tasks.yaml"
    fi
}

# タスク編集コマンドのヘルプ表示
show_help() {
    cat << EOF
Usage: task edit [options]
Edit an existing task in the task management system.

Options:
  -i, --id <id>            Task ID to edit (required)
  -n, --name <name>        New task name
  -d, --description <text> New task description
  -c, --concerns <text>    New task concerns
  -p, --parent <id>        New parent task ID
  -h, --help              Show this help message

Examples:
  task edit -i TA01 -n "新しいタスク名"
  task edit -i TA01 -d "新しい説明" -c "新しい懸念事項"
  task edit -i TA01 -p TA02
EOF
}

# メイン処理
main() {
    # 必要なディレクトリとファイルの作成
    ensure_directories

    local task_id=""
    local new_name=""
    local new_description=""
    local new_concerns=""
    local new_parent=""

    # オプションの解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--id)
                task_id="$2"
                shift 2
                ;;
            -n|--name)
                new_name="$2"
                shift 2
                ;;
            -d|--description)
                new_description="$2"
                shift 2
                ;;
            -c|--concerns)
                new_concerns="$2"
                shift 2
                ;;
            -p|--parent)
                new_parent="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                return 0
                ;;
            *)
                log_error "不明なオプション: $1"
                show_help
                return 1
                ;;
        esac
    done

    # タスクIDの必須チェック
    if [[ -z "$task_id" ]]; then
        log_error "タスクIDは必須です"
        show_help
        return 1
    fi

    # 少なくとも1つの編集項目があることを確認
    if [[ -z "$new_name" && -z "$new_description" && -z "$new_concerns" && -z "$new_parent" ]]; then
        log_error "編集する項目を少なくとも1つ指定してください"
        show_help
        return 1
    fi

    # タスクの存在確認
    if ! task_exists "$task_id"; then
        log_error "タスクが見つかりません: $task_id"
        return 1
    fi

    # 親タスクの存在確認（指定された場合）
    if [[ -n "$new_parent" ]] && ! task_exists "$new_parent"; then
        log_error "親タスクが見つかりません: $new_parent"
        return 1
    fi

    # バックアップの作成
    if ! backup_yaml_file; then
        log_error "バックアップの作成に失敗しました"
        return 1
    fi

    # タスクの更新
    local updated=false

    if [[ -n "$new_name" ]]; then
        if update_task "$task_id" "name" "$new_name"; then
            log_info "タスク名を更新しました: $new_name"
            updated=true
        fi
    fi

    if [[ -n "$new_description" ]]; then
        if update_task "$task_id" "description" "$new_description"; then
            log_info "説明を更新しました"
            updated=true
        fi
    fi

    if [[ -n "$new_concerns" ]]; then
        if update_task "$task_id" "concerns" "$new_concerns"; then
            log_info "懸念事項を更新しました"
            updated=true
        fi
    fi

    if [[ -n "$new_parent" ]]; then
        if update_task "$task_id" "parent" "$new_parent"; then
            log_info "親タスクを更新しました: $new_parent"
            updated=true
        fi
    fi

    if $updated; then
        # テンプレートの再生成
        if ! generate_task_file_from_template; then
            log_error "タスクファイルの生成に失敗しました"
            return 1
        fi
        log_info "更新したタスク: $task_id"
        return 0
    else
        log_error "タスクの更新に失敗しました"
        return 1
    fi
} 