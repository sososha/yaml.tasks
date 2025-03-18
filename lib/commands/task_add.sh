#!/bin/bash

# 共通ユーティリティと必要なモジュールの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/validators.sh"
source "${SCRIPT_DIR}/../core/yaml_processor.sh"
source "${SCRIPT_DIR}/../core/template_engine.sh"

# ヘルプメッセージの表示
show_add_help() {
    cat << EOF
Usage: task add <task_name> [status] [details] [concerns]
   or: task add "<task1,task2,task3>" ["status1,status2,status3"]

Options:
    task_name   タスク名（必須）。複数のタスクはカンマ区切りで指定
    status      タスクのステータス（オプション、デフォルト: not_started）
                複数のタスクの場合はカンマ区切りで指定
    details     タスクの詳細情報（オプション）
    concerns    考慮事項（オプション）

Examples:
    task add "新機能の実装"
    task add "バグ修正" "in_progress" "認証機能のバグ" "セキュリティ考慮"
    task add "タスク1,タスク2,タスク3" "not_started,in_progress,completed"
EOF
    exit 0
}

# タスク追加処理のメイン関数
task_add() {
    local task_names="$1"
    local statuses="$2"
    local details="$3"
    local concerns="$4"

    # 引数チェック
    if [[ -z "$task_names" ]]; then
        show_add_help
        return 1
    fi

    # タスク名をカンマで分割
    IFS=',' read -ra task_name_array <<< "$task_names"
    
    # ステータスをカンマで分割（指定がない場合はデフォルト値を使用）
    local status_array=()
    if [[ -n "$statuses" ]]; then
        IFS=',' read -ra status_array <<< "$statuses"
    fi

    # 各タスクを処理
    local success_count=0
    local total_tasks=${#task_name_array[@]}

    for ((i=0; i<${#task_name_array[@]}; i++)); do
        local task_name="${task_name_array[$i]}"
        local status="${status_array[$i]:-not_started}"

        # 入力検証
        if ! validate_task_name "$task_name"; then
            log_error "無効なタスク名: $task_name"
            continue
        fi

        if ! validate_task_status "$status"; then
            log_error "無効なステータス: $status"
            continue
        fi

        # 新しいタスクIDの生成
        local new_task_id=$(generate_task_id)

        # タスクの追加
        if add_task_to_yaml "$new_task_id" "$task_name" "$status" "$details" "$concerns"; then
            log_info "タスクを追加しました: $task_name (ID: $new_task_id)"
            ((success_count++))
        else
            log_error "タスクの追加に失敗しました: $task_name"
        fi
    done

    # テンプレートの再生成
    if ((success_count > 0)); then
        if generate_task_file_from_template; then
            log_info "$success_count/$total_tasks 個のタスクが正常に追加されました"
            return 0
        else
            log_error "タスクファイルの生成に失敗しました"
            return 1
        fi
    else
        log_error "タスクの追加に失敗しました"
        return 1
    fi
}

# メイン処理
case "$1" in
    "-h"|"--help")
        show_add_help
        ;;
    *)
        task_add "$@"
        ;;
esac 