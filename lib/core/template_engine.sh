#!/bin/bash
# テンプレートエンジンモジュール

# 共通ユーティリティの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ルートディレクトリを設定（未定義の場合のみ）
if [[ -z "$TASK_DIR" ]]; then
    TASK_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
fi

# 定数
TEMPLATES_DIR="${TASK_DIR}/tasks/templates"
CONFIG_DIR="${TASK_DIR}/tasks/config"
CONFIG_FILE="${CONFIG_DIR}/template_config.yaml"
TASKS_FILE="${TASK_DIR}/tasks/tasks.yaml"
PROJECT_TASKS_FILE="${TASK_DIR}/tasks/project.tasks"

# テンプレート設定を読み込む
load_template_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "テンプレート設定ファイルが見つかりません: $CONFIG_FILE"
        return 1
    }
    
    # 設定ファイルの構文チェック
    if ! yq eval '.' "$CONFIG_FILE" > /dev/null 2>&1; then
        log_error "テンプレート設定ファイルの形式が無効です: $CONFIG_FILE"
        return 1
    }
    
    return 0
}

# テンプレート設定を更新
update_template_config() {
    local key="$1"
    local value="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "テンプレート設定ファイルが見つかりません: $CONFIG_FILE"
        return 1
    }
    
    # 設定を更新
    local temp_file="${CONFIG_FILE}.tmp"
    if ! yq eval ".$key = \"$value\"" "$CONFIG_FILE" > "$temp_file"; then
        log_error "テンプレート設定の更新に失敗しました"
        rm -f "$temp_file"
        return 1
    }
    
    mv "$temp_file" "$CONFIG_FILE"
    log_info "テンプレート設定を更新しました: $key = $value"
    return 0
}

# 現在のテンプレートを取得
get_current_template() {
    local template_name
    template_name=$(yq eval '.current_template' "$CONFIG_FILE")
    echo "${TEMPLATES_DIR}/${template_name}.template"
}

# タスクのステータスを記号に変換
convert_status_to_symbol() {
    local status="$1"
    local symbol
    
    case "$status" in
        "completed")
            symbol=$(yq eval '.symbols.completed' "$CONFIG_FILE")
            ;;
        "in_progress")
            symbol=$(yq eval '.symbols.in_progress' "$CONFIG_FILE")
            ;;
        *)
            symbol=$(yq eval '.symbols.not_started' "$CONFIG_FILE")
            ;;
    esac
    
    echo "$symbol"
}

# インデントを生成
generate_indent() {
    local level="$1"
    local indent_char
    indent_char=$(yq eval '.format.indent_char' "$CONFIG_FILE")
    
    printf "%${level}s" | sed "s/ /${indent_char}/g"
}

# タスクツリーを生成
generate_task_tree() {
    local parent_id="$1"
    local level="${2:-0}"
    local output=""
    local indent
    indent=$(generate_indent "$level")
    
    # 親タスクまたはルートレベルのタスクを取得
    local tasks
    if [[ -z "$parent_id" ]]; then
        tasks=$(yq eval '.tasks[] | select(.parent == null)' "$TASKS_FILE")
    else
        tasks=$(yq eval ".tasks[] | select(.parent == \"$parent_id\")" "$TASKS_FILE")
    fi
    
    # 各タスクを処理
    while IFS= read -r task; do
        if [[ -z "$task" ]]; then
            continue
        fi
        
        local id=$(echo "$task" | yq eval '.id' -)
        local name=$(echo "$task" | yq eval '.name' -)
        local status=$(echo "$task" | yq eval '.status' -)
        local symbol=$(convert_status_to_symbol "$status")
        local content=$(echo "$task" | yq eval '.details.content' -)
        local concerns=$(echo "$task" | yq eval '.details.concerns' -)
        
        # タスク行を生成
        output+="${indent}${symbol} ${name} (${id})"
        
        # 詳細情報を追加（設定で有効な場合）
        if yq eval '.sections[] | select(.name == "Details") | .enabled' "$CONFIG_FILE" > /dev/null; then
            if [[ -n "$content" ]]; then
                output+="\n${indent}  内容: ${content}"
            fi
            if [[ -n "$concerns" ]]; then
                output+="\n${indent}  考慮: ${concerns}"
            fi
        fi
        
        output+="\n"
        
        # 子タスクを再帰的に処理
        local children
        children=$(generate_task_tree "$id" $((level + 1)))
        if [[ -n "$children" ]]; then
            output+="${children}"
        fi
    done <<< "$tasks"
    
    echo "$output"
}

# タスクファイルをテンプレートから生成
generate_task_file_from_template() {
    # テンプレート設定の読み込み
    if ! load_template_config; then
        return 1
    fi
    
    # タスクツリーを生成
    local task_tree
    task_tree=$(generate_task_tree)
    
    if [[ $? -ne 0 ]]; then
        log_error "タスクツリーの生成に失敗しました"
        return 1
    fi
    
    # プロジェクトタスクファイルを生成
    echo "$task_tree" > "$PROJECT_TASKS_FILE"
    
    if [[ $? -eq 0 ]]; then
        log_info "タスクファイルを生成しました: $PROJECT_TASKS_FILE"
        return 0
    else
        log_error "タスクファイルの生成に失敗しました"
        return 1
    fi
}
