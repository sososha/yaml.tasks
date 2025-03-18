#!/bin/bash

# 共通ユーティリティの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/validators.sh"
source "${SCRIPT_DIR}/../core/yaml_processor.sh"
source "${SCRIPT_DIR}/../core/template_engine.sh"

# タスク管理システムのルートディレクトリを設定（未定義の場合のみ）
if [[ -z "$TASK_DIR" ]]; then
    TASK_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
fi

# ヘルプ表示
show_status_help() {
    cat << EOF
使用法: task status <タスクID> <新しいステータス> [オプション]

タスクのステータスを変更します。コンマ区切りで複数のタスクを一括更新できます。

引数:
    タスクID          ステータスを変更するタスクのID（コンマ区切りで複数指定可能）
    新しいステータス  設定するステータス（未着手|進行中|完了）（コンマ区切りで複数指定可能）

オプション:
    -r, --recursive   サブタスクも含めて更新
    -f, --force      確認なしで更新を実行
    -h, --help       このヘルプを表示

例:
    task status PA01 完了
    task status "PA01,PA02" "完了,進行中"
    task status PA01 完了 --recursive
EOF
}

# ステータスの検証
validate_status() {
    local status="$1"
    case "$status" in
        "not_started"|"in_progress"|"completed"|"未着手"|"進行中"|"完了")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ステータスの正規化
normalize_status() {
    local status="$1"
    case "$status" in
        "未着手")
            echo "not_started"
            ;;
        "進行中")
            echo "in_progress"
            ;;
        "完了")
            echo "completed"
            ;;
        *)
            echo "$status"
            ;;
    esac
}

# 再帰的にステータスを更新
update_status_recursive() {
    local task_id="$1"
    local new_status="$2"
    
    # 現在のタスクのステータスを更新
    update_task "$task_id" "status" "$new_status"
    
    # 子タスクを取得して再帰的に更新
    local child_tasks
    child_tasks=$(get_child_tasks "$task_id")
    
    if [[ -n "$child_tasks" ]]; then
        while IFS= read -r child; do
            local child_id
            child_id=$(echo "$child" | yq eval '.id' -)
            if [[ -n "$child_id" ]]; then
                update_status_recursive "$child_id" "$new_status"
            fi
        done <<< "$child_tasks"
    fi
}

# ステータスの更新
update_task_status() {
    local task_ids="$1"
    local new_statuses="$2"
    local recursive="$3"
    local force="$4"
    
    # コンマ区切りの値を配列に分割
    IFS=',' read -ra id_array <<< "$task_ids"
    IFS=',' read -ra status_array <<< "$new_statuses"
    
    local i=0
    local updated_tasks=()
    
    # 各タスクを処理
    for task_id in "${id_array[@]}"; do
        # タスクの存在確認
        if ! task_exists "$task_id"; then
            log_error "タスクが見つかりません: $task_id"
            continue
        fi
        
        # ステータスの取得と正規化
        local new_status="${status_array[$i]:-${status_array[0]}}"
        new_status=$(normalize_status "$new_status")
        
        # ステータスの検証
        if ! validate_status "$new_status"; then
            log_error "無効なステータス: $new_status"
            continue
        fi
        
        # 確認プロンプト（--force オプションが指定されていない場合）
        if [[ "$force" != "true" ]]; then
            local current_status
            current_status=$(get_task "$task_id" | yq eval '.status' -)
            read -p "タスク $task_id のステータスを $current_status から $new_status に変更しますか？ (y/N): " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                log_info "タスク $task_id のステータス変更をスキップしました"
                continue
            fi
        fi
        
        # ステータスの更新
        if [[ "$recursive" == "true" ]]; then
            update_status_recursive "$task_id" "$new_status"
        else
            update_task "$task_id" "status" "$new_status"
        fi
        
        if [[ $? -eq 0 ]]; then
            updated_tasks+=("$task_id")
        fi
        
        ((i++))
    done
    
    # テンプレートからタスクファイルを生成
    generate_task_file_from_template
    
    # 更新したタスクのIDを表示
    if [[ ${#updated_tasks[@]} -gt 0 ]]; then
        log_info "更新したタスク: ${updated_tasks[*]}"
    fi
    
    return 0
}

# メイン処理
main() {
    # 引数の解析
    local task_ids=""
    local new_statuses=""
    local recursive="false"
    local force="false"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_status_help
                return 0
                ;;
            -r|--recursive)
                recursive="true"
                shift
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            *)
                if [[ -z "$task_ids" ]]; then
                    task_ids="$1"
                elif [[ -z "$new_statuses" ]]; then
                    new_statuses="$1"
                else
                    log_error "不明な引数: $1"
                    show_status_help
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # 必須引数のチェック
    if [[ -z "$task_ids" || -z "$new_statuses" ]]; then
        log_error "タスクIDと新しいステータスは必須です"
        show_status_help
        return 1
    fi
    
    # ステータスを更新
    update_task_status "$task_ids" "$new_statuses" "$recursive" "$force"
    return $?
}

# スクリプトとして実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 