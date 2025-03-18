#!/bin/bash

# 共通ユーティリティの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../core/yaml_processor.sh"
source "${SCRIPT_DIR}/../core/template_engine.sh"

# ヘルプ表示
show_subtask_help() {
    cat << EOF
使用法: task subtask <親タスクID> <サブタスク名> [オプション]

サブタスクを追加します。コンマ区切りで複数のサブタスクを一括追加できます。

引数:
    親タスクID        サブタスクを追加する親タスクのID
    サブタスク名      追加するサブタスクの名前（コンマ区切りで複数指定可能）

オプション:
    -s, --status      タスクのステータス（未着手|進行中|完了）
    -c, --content     タスクの内容
    -n, --concerns    考慮事項
    -h, --help        このヘルプを表示

例:
    task subtask PA01 "サブタスク1"
    task subtask PA01 "サブタスク1,サブタスク2" -s "未着手,進行中"
    task subtask PA01 "サブタスク1" -c "タスク内容" -n "考慮事項"
EOF
}

# サブタスクの追加
add_subtasks() {
    local parent_id="$1"
    local names="$2"
    local statuses="${3:-}"
    local content="${4:-}"
    local concerns="${5:-}"
    
    # 親タスクの存在確認
    if ! task_exists "$parent_id"; then
        log_error "親タスクが見つかりません: $parent_id"
        return 1
    fi
    
    # コンマ区切りの値を配列に分割
    IFS=',' read -ra name_array <<< "$names"
    IFS=',' read -ra status_array <<< "$statuses"
    
    local added_ids=()
    local i=0
    
    # 各サブタスクを追加
    for name in "${name_array[@]}"; do
        local status="${status_array[$i]:-not_started}"
        
        # サブタスクを追加
        local new_id
        new_id=$(add_task "$name" "$status" "$parent_id" "$content" "$concerns")
        
        if [[ $? -eq 0 ]]; then
            added_ids+=("$new_id")
        else
            log_error "サブタスクの追加に失敗しました: $name"
        fi
        
        ((i++))
    done
    
    # テンプレートからタスクファイルを生成
    generate_task_file_from_template
    
    # 追加したサブタスクのIDを表示
    if [[ ${#added_ids[@]} -gt 0 ]]; then
        log_info "追加したサブタスク: ${added_ids[*]}"
    fi
    
    return 0
}

# メイン処理
main() {
    # 引数の解析
    local parent_id=""
    local names=""
    local statuses=""
    local content=""
    local concerns=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_subtask_help
                return 0
                ;;
            -s|--status)
                statuses="$2"
                shift 2
                ;;
            -c|--content)
                content="$2"
                shift 2
                ;;
            -n|--concerns)
                concerns="$2"
                shift 2
                ;;
            *)
                if [[ -z "$parent_id" ]]; then
                    parent_id="$1"
                elif [[ -z "$names" ]]; then
                    names="$1"
                else
                    log_error "不明な引数: $1"
                    show_subtask_help
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # 必須引数のチェック
    if [[ -z "$parent_id" || -z "$names" ]]; then
        log_error "親タスクIDとサブタスク名は必須です"
        show_subtask_help
        return 1
    fi
    
    # サブタスクを追加
    add_subtasks "$parent_id" "$names" "$statuses" "$content" "$concerns"
    return $?
}

# スクリプトとして実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 