#!/bin/bash

# 共通ユーティリティの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../core/yaml_processor.sh"
source "${SCRIPT_DIR}/../core/template_engine.sh"

# ヘルプ表示
show_list_help() {
    cat << EOF
使用法: task list [オプション]

タスク一覧を表示します。

オプション:
    -a, --all         すべてのタスクを表示（デフォルト）
    -p, --parent      親タスクのみ表示
    -c, --completed   完了したタスクのみ表示
    -i, --in-progress 進行中のタスクのみ表示
    -n, --not-started 未着手のタスクのみ表示
    -s, --search      タスク名で検索
    -f, --format      出力形式（simple|detailed）
    -h, --help        このヘルプを表示

例:
    task list
    task list --completed
    task list --search "重要"
    task list --format detailed
EOF
}

# タスクの表示（シンプル形式）
display_task_simple() {
    local task="$1"
    local indent="$2"
    
    local id=$(echo "$task" | yq eval '.id' -)
    local name=$(echo "$task" | yq eval '.name' -)
    local status=$(echo "$task" | yq eval '.status' -)
    local symbol=$(convert_status_to_symbol "$status")
    
    echo "${indent}${symbol} ${name} (${id})"
}

# タスクの表示（詳細形式）
display_task_detailed() {
    local task="$1"
    local indent="$2"
    
    local id=$(echo "$task" | yq eval '.id' -)
    local name=$(echo "$task" | yq eval '.name' -)
    local status=$(echo "$task" | yq eval '.status' -)
    local symbol=$(convert_status_to_symbol "$status")
    local content=$(echo "$task" | yq eval '.details.content' -)
    local concerns=$(echo "$task" | yq eval '.details.concerns' -)
    local results=$(echo "$task" | yq eval '.details.results' -)
    local result_concerns=$(echo "$task" | yq eval '.details.result_concerns' -)
    
    echo "${indent}${symbol} ${name} (${id})"
    [[ -n "$content" ]] && echo "${indent}  内容: ${content}"
    [[ -n "$concerns" ]] && echo "${indent}  考慮: ${concerns}"
    [[ -n "$results" ]] && echo "${indent}  結果: ${results}"
    [[ -n "$result_concerns" ]] && echo "${indent}  結果的懸念: ${result_concerns}"
}

# タスクツリーの表示
display_task_tree() {
    local parent_id="$1"
    local format="$2"
    local level="${3:-0}"
    local indent="  "
    local current_indent=""
    
    for ((i=0; i<level; i++)); do
        current_indent="${current_indent}${indent}"
    done
    
    # 親タスクまたはルートレベルのタスクを取得
    local tasks
    if [[ -z "$parent_id" ]]; then
        tasks=$(get_child_tasks)
    else
        tasks=$(get_child_tasks "$parent_id")
    fi
    
    # 各タスクを処理
    while IFS= read -r task; do
        if [[ -z "$task" ]]; then
            continue
        fi
        
        # タスクを表示
        if [[ "$format" == "detailed" ]]; then
            display_task_detailed "$task" "$current_indent"
        else
            display_task_simple "$task" "$current_indent"
        fi
        
        # 子タスクを再帰的に処理
        local task_id=$(echo "$task" | yq eval '.id' -)
        display_task_tree "$task_id" "$format" $((level + 1))
    done <<< "$tasks"
}

# タスク一覧の表示
list_tasks() {
    local filter="$1"
    local search_query="$2"
    local format="${3:-simple}"
    
    # 検索クエリがある場合は検索を実行
    if [[ -n "$search_query" ]]; then
        local search_results
        search_results=$(search_tasks "$search_query")
        if [[ -n "$search_results" ]]; then
            echo "検索結果: \"$search_query\""
            echo "$search_results" | while IFS= read -r task; do
                if [[ "$format" == "detailed" ]]; then
                    display_task_detailed "$task" ""
                else
                    display_task_simple "$task" ""
                fi
                echo
            done
        else
            log_info "検索条件に一致するタスクはありません"
        fi
        return 0
    fi
    
    # フィルタに基づいてタスクを表示
    case "$filter" in
        "completed"|"in_progress"|"not_started")
            echo "ステータス: $filter のタスク"
            local filtered_tasks
            filtered_tasks=$(yq eval ".tasks[] | select(.status == \"$filter\")" "$TASKS_FILE")
            if [[ -n "$filtered_tasks" ]]; then
                echo "$filtered_tasks" | while IFS= read -r task; do
                    if [[ "$format" == "detailed" ]]; then
                        display_task_detailed "$task" ""
                    else
                        display_task_simple "$task" ""
                    fi
                    echo
                done
            else
                log_info "該当するタスクはありません"
            fi
            ;;
        "parent")
            echo "親タスク一覧:"
            display_task_tree "" "$format"
            ;;
        *)
            echo "全タスク一覧:"
            display_task_tree "" "$format"
            
            # タスク統計の表示
            echo
            get_task_stats
            ;;
    esac
    
    return 0
}

# メイン処理
main() {
    # 引数の解析
    local filter="all"
    local search_query=""
    local format="simple"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_list_help
                return 0
                ;;
            -a|--all)
                filter="all"
                shift
                ;;
            -p|--parent)
                filter="parent"
                shift
                ;;
            -c|--completed)
                filter="completed"
                shift
                ;;
            -i|--in-progress)
                filter="in_progress"
                shift
                ;;
            -n|--not-started)
                filter="not_started"
                shift
                ;;
            -s|--search)
                search_query="$2"
                shift 2
                ;;
            -f|--format)
                format="$2"
                if [[ "$format" != "simple" && "$format" != "detailed" ]]; then
                    log_error "無効な出力形式: $format"
                    return 1
                fi
                shift 2
                ;;
            *)
                log_error "不明な引数: $1"
                show_list_help
                return 1
                ;;
        esac
    done
    
    # タスク一覧を表示
    list_tasks "$filter" "$search_query" "$format"
    return $?
}

# スクリプトとして実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 