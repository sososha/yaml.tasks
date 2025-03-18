#!/bin/bash
# テンプレートエンジンモジュール

# 定数
TEMPLATE_DIR="${TASK_DIR}/templates"
CONFIG_DIR="${TASK_DIR}/config"
TEMPLATE_CONFIG_FILE="${CONFIG_DIR}/template_config.yaml"
TASKS_FILE="${TASK_DIR}/tasks/project.tasks"

# テンプレート設定を読み込む
load_template_config() {
    if [ ! -f "$TEMPLATE_CONFIG_FILE" ]; then
        echo "エラー: テンプレート設定ファイルが見つかりません: $TEMPLATE_CONFIG_FILE"
        return 1
    fi
    
    # yqを使用して設定を読み込む
    local config_json=$(yq eval -o=json '.' "$TEMPLATE_CONFIG_FILE")
    echo "$config_json"
}

# 現在のテンプレート名を取得
get_current_template() {
    local config_json=$(load_template_config)
    local template_name=$(echo "$config_json" | jq -r '.current_template')
    echo "$template_name"
}

# ステータスシンボルを取得
get_status_symbol() {
    local status="$1"
    local config_json=$(load_template_config)
    
    local symbol=""
    case "$status" in
        "completed")
            symbol=$(echo "$config_json" | jq -r '.symbols.completed')
            ;;
        "in_progress")
            symbol=$(echo "$config_json" | jq -r '.symbols.in_progress')
            ;;
        "not_started")
            symbol=$(echo "$config_json" | jq -r '.symbols.not_started')
            ;;
        *)
            symbol="?"
            ;;
    esac
    
    echo "$symbol"
}

# インデント文字を取得
get_indent_char() {
    local config_json=$(load_template_config)
    local indent_char=$(echo "$config_json" | jq -r '.format.indent_char')
    echo "$indent_char"
}

# タスク行のフォーマット
format_task_line() {
    local task="$1"
    local indent_level="$2"
    
    local id=$(echo "$task" | jq -r '.id')
    local name=$(echo "$task" | jq -r '.name')
    local status=$(echo "$task" | jq -r '.status')
    
    # ステータスシンボルを取得
    local symbol=$(get_status_symbol "$status")
    
    # インデント文字を取得
    local indent_char=$(get_indent_char)
    local indent=""
    for ((i=0; i<indent_level; i++)); do
        indent="${indent}${indent_char}"
    done
    
    echo "${indent}${symbol} ${id} ${name}"
}

# 詳細セクションのフォーマット
format_details() {
    local task="$1"
    
    local id=$(echo "$task" | jq -r '.id')
    local content=$(echo "$task" | jq -r '.details.content')
    local design=$(echo "$task" | jq -r '.details.design')
    local concerns=$(echo "$task" | jq -r '.details.concerns')
    local results=$(echo "$task" | jq -r '.details.results')
    local result_concerns=$(echo "$task" | jq -r '.details.result_concerns')
    
    local details="- ${id}:\n  内容  :  ${content}\n  設計思想  :  ${design}"
    
    if [ -n "$concerns" ] && [ "$concerns" != "null" ]; then
        details="${details}\n  懸念  :  ${concerns}"
    fi
    
    if [ -n "$results" ] && [ "$results" != "null" ]; then
        details="${details}\n  実装結果  :  ${results}"
    fi
    
    if [ -n "$result_concerns" ] && [ "$result_concerns" != "null" ]; then
        details="${details}\n  結果的懸念  :  ${result_concerns}"
    fi
    
    echo -e "$details"
}

# タスクの階層構造を構築
build_task_hierarchy() {
    local tasks_json="$1"
    
    # ルートタスクを取得
    local root_tasks=$(echo "$tasks_json" | jq '[.[] | select(.parent == null)]')
    
    # 各ルートタスクとその子タスクを再帰的に処理
    process_task_hierarchy "$tasks_json" "$root_tasks" 0
}

# タスク階層を再帰的に処理
process_task_hierarchy() {
    local all_tasks="$1"
    local current_tasks="$2"
    local indent_level="$3"
    
    local result=""
    
    # 各タスクを処理
    local task_count=$(echo "$current_tasks" | jq 'length')
    for ((i=0; i<task_count; i++)); do
        local task=$(echo "$current_tasks" | jq ".[$i]")
        local task_id=$(echo "$task" | jq -r '.id')
        
        # タスク行をフォーマット
        local task_line=$(format_task_line "$task" "$indent_level")
        result="${result}${task_line}\n"
        
        # 子タスクを取得
        local child_tasks=$(echo "$all_tasks" | jq "[.[] | select(.parent == \"$task_id\")]")
        
        # 子タスクがある場合は再帰的に処理
        local child_count=$(echo "$child_tasks" | jq 'length')
        if [ "$child_count" -gt 0 ]; then
            local child_result=$(process_task_hierarchy "$all_tasks" "$child_tasks" $((indent_level + 1)))
            result="${result}${child_result}"
        fi
    done
    
    echo -e "$result"
}

# テンプレートを適用してファイルを生成
generate_from_template() {
    local template_name="$1"
    local output_file="$2"
    local data_file="$3"
    
    # テンプレートファイルを確認
    local template_file="${TEMPLATE_DIR}/${template_name}.template"
    if [ ! -f "$template_file" ]; then
        echo "エラー: テンプレートファイルが見つかりません: $template_file"
        return 1
    fi
    
    # YAMLデータを読み込む
    local tasks_json=$(yq eval -o=json '.tasks' "$data_file")
    
    # 出力ファイルのディレクトリを確保
    mkdir -p "$(dirname "$output_file")"
    
    # タスクセクションを生成
    local tasks_section="# Tasks\n"
    tasks_section="${tasks_section}$(build_task_hierarchy "$tasks_json")"
    
    # 詳細セクションを生成
    local details_section="# Details\n"
    local task_count=$(echo "$tasks_json" | jq 'length')
    for ((i=0; i<task_count; i++)); do
        local task=$(echo "$tasks_json" | jq ".[$i]")
        local task_details=$(format_details "$task")
        details_section="${details_section}${task_details}\n"
    done
    
    # 最終的な出力を生成
    local output="${tasks_section}\n${details_section}"
    
    # 結果をファイルに書き込む
    echo -e "$output" > "$output_file"
    
    echo "テンプレート ${template_name} を適用して ${output_file} を生成しました"
}

# テンプレート設定を変更
update_template_config() {
    local key="$1"
    local value="$2"
    
    # 設定ファイルを更新
    case "$key" in
        "current_template")
            yq eval ".current_template = \"$value\"" -i "$TEMPLATE_CONFIG_FILE"
            ;;
        "symbol.completed")
            yq eval ".symbols.completed = \"$value\"" -i "$TEMPLATE_CONFIG_FILE"
            ;;
        "symbol.in_progress")
            yq eval ".symbols.in_progress = \"$value\"" -i "$TEMPLATE_CONFIG_FILE"
            ;;
        "symbol.not_started")
            yq eval ".symbols.not_started = \"$value\"" -i "$TEMPLATE_CONFIG_FILE"
            ;;
        "format.indent_char")
            yq eval ".format.indent_char = \"$value\"" -i "$TEMPLATE_CONFIG_FILE"
            ;;
        *)
            echo "エラー: 不明な設定キー: $key"
            return 1
            ;;
    esac
    
    echo "テンプレート設定 ${key} を ${value} に更新しました"
}

# タスクデータと表示を同期
sync_tasks_file() {
    local template_name=$(get_current_template)
    generate_from_template "$template_name" "$TASKS_FILE" "$TASKS_YAML_FILE"
}
