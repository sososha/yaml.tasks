#!/bin/bash
# テンプレートエンジンモジュール

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 共通ユーティリティの読み込み
source "${SCRIPT_DIR}/../utils/common.sh"

# タスク管理システムのルートディレクトリを設定（未定義の場合のみ）
if [[ -z "$TASK_DIR" ]]; then
    TASK_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
fi

# 定数
TEMPLATES_DIR="${TASK_DIR}/tasks/templates"
CONFIG_DIR="${TASK_DIR}/tasks/config"
CONFIG_FILE="${CONFIG_DIR}/template_config.yaml"
TASKS_FILE="${TASK_DIR}/tasks/tasks.yaml"
PROJECT_TASKS_FILE="${TASK_DIR}/tasks/project.tasks"

# デフォルトのテンプレートを作成する関数
create_default_template() {
    local template_file="${TEMPLATES_DIR}/default.template"
    mkdir -p "${TEMPLATES_DIR}"
    
    cat > "$template_file" << 'EOF'
# プロジェクトタスクリスト
{{#each tasks}}
## {{id}} {{#if status}}[{{status}}]{{/if}} {{name}}
{{#if description}}
説明: {{description}}
{{/if}}
{{#if concerns}}
懸念事項: {{concerns}}
{{/if}}
{{#if subtasks.length}}
サブタスク:
{{#each subtasks}}
- {{id}} {{#if status}}[{{status}}]{{/if}} {{name}}
{{/each}}
{{/if}}

{{/each}}
EOF
    
    log_info "デフォルトのテンプレートを作成しました: $template_file"
}

# デフォルトの設定ファイルを作成する関数
create_default_config() {
    local config_file="${CONFIG_DIR}/template_config.yaml"
    mkdir -p "${CONFIG_DIR}"
    
    cat > "$config_file" << 'EOF'
current_template: default
status_symbols:
  not_started: "🔴"
  in_progress: "🟡"
  completed: "🟢"
layout:
  indent: 2
  show_statistics: true
display_options:
  show_empty_fields: false
  show_statistics: true
  show_hierarchy: true
EOF
    
    log_info "デフォルトの設定ファイルを作成しました: $config_file"
}

# テンプレート設定を読み込む
load_template_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "テンプレート設定ファイルが見つかりません: $CONFIG_FILE"
        create_default_config
    fi
    
    # 設定ファイルの構文チェック
    if ! yq eval '.' "$CONFIG_FILE" > /dev/null 2>&1; then
        log_error "テンプレート設定ファイルの形式が無効です: $CONFIG_FILE"
        return 1
    fi
    
    return 0
}

# テンプレート設定を更新
update_template_config() {
    local key="$1"
    local value="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "テンプレート設定ファイルが見つかりません: $CONFIG_FILE"
        return 1
    fi
    
    # 設定を更新
    local temp_file="${CONFIG_FILE}.tmp"
    if ! yq eval ".$key = \"$value\"" "$CONFIG_FILE" > "$temp_file"; then
        log_error "テンプレート設定の更新に失敗しました"
        rm -f "$temp_file"
        return 1
    fi
    
    mv "$temp_file" "$CONFIG_FILE"
    log_info "テンプレート設定を更新しました: $key = $value"
    return 0
}

# 現在のテンプレートを取得
get_current_template() {
    local template_name
    template_name=$(yq eval '.current_template' "$CONFIG_FILE")
    echo "${template_name}"
}

# タスクのステータスを記号に変換
convert_status_to_symbol() {
    local status="$1"
    local symbol
    
    case "$status" in
        "completed")
            symbol="✓"
            ;;
        "in_progress")
            symbol="⚡"
            ;;
        *)
            symbol="□"
            ;;
    esac
    
    echo "$symbol"
}

# インデントを生成
generate_indent() {
    local level="$1"
    local indent_char="  "
    printf "%${level}s" | sed "s/ /${indent_char}/g"
}

# タスクツリーを生成（再帰的）
generate_task_tree() {
    local task_id="$1"
    local indent_level="$2"
    local output=""
    local indent=""
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"
    
    # インデントを生成
    for ((i=0; i<indent_level; i++)); do
        indent+="  "
    done
    
    # タスク情報の取得
    local name=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .name" "$tasks_file")
    local status=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .status" "$tasks_file")
    local description=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .description" "$tasks_file")
    local concerns=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .concerns" "$tasks_file")
    
    # ステータス記号の設定
    local symbol
    case "$status" in
        "completed")
            symbol="✓"
            ;;
        "in_progress")
            symbol="⚡"
            ;;
        *)
            symbol="□"
            ;;
    esac
    
    # タスク行の生成
    output+="${indent}${symbol} ${name} (ID: ${task_id})"$'\n'
    
    # 詳細情報の追加（空でない場合のみ）
    if [[ -n "$description" && "$description" != "null" ]]; then
        output+="${indent}  Description: ${description}"$'\n'
    fi
    if [[ -n "$concerns" && "$concerns" != "null" ]]; then
        output+="${indent}  Concerns: ${concerns}"$'\n'
    fi
    output+=$'\n'
    
    # 子タスクを再帰的に処理
    local child_tasks
    child_tasks=$(yq eval ".tasks[] | select(.parent == \"$task_id\") | .id" "$tasks_file")
    
    while IFS= read -r child_id; do
        if [[ -z "$child_id" ]]; then
            continue
        fi
        output+=$(generate_task_tree "$child_id" $((indent_level + 1)))
    done <<< "$child_tasks"
    
    echo "$output"
}

# タスクデータを取得する関数
get_tasks_data() {
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"
    
    # タスクファイルの存在確認
    if [[ ! -f "$tasks_file" ]]; then
        log_error "タスクファイルが見つかりません: $tasks_file"
        return 1
    fi
    
    # すべてのタスクデータを取得
    cat "$tasks_file"
}

# 再帰的にタスクの子タスクを処理する関数
process_task_hierarchy() {
    local task_id="$1"
    local indent_level="$2"
    local result=""
    
    # タスク情報の取得
    local name=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .name" "$TASKS_FILE")
    local status=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .status" "$TASKS_FILE")
    local description=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .description" "$TASKS_FILE")
    local concerns=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .concerns" "$TASKS_FILE")
    
    # インデント生成
    local indent=""
    for ((i=0; i<indent_level; i++)); do
        indent+="  "
    done
    
    # ステータス表示
    local status_display=""
    if [[ -n "$status" && "$status" != "null" ]]; then
        case "$status" in
            "completed")
                status_display="✅"
                ;;
            "in_progress")
                status_display="[in_progress]"
                ;;
            *)
                status_display="[not_started]"
                ;;
        esac
    fi
    
    # タスク行の追加（末尾に改行文字を挿入）
    result+="${indent}## $task_id $status_display $name\n"
    
    # 説明の追加
    if [[ -n "$description" && "$description" != "null" ]]; then
        result+="${indent}説明: $description\n"
    fi
    
    # 懸念事項の追加
    if [[ -n "$concerns" && "$concerns" != "null" ]]; then
        result+="${indent}懸念事項: $concerns\n"
    fi
    
    result+="\n"
    
    # 子タスクを処理
    local child_tasks
    child_tasks=$(yq eval ".tasks[] | select(.parent == \"$task_id\") | .id" "$TASKS_FILE")
    
    while IFS= read -r child_id; do
        if [[ -z "$child_id" ]]; then
            continue
        fi
        result+=$(process_task_hierarchy "$child_id" $((indent_level + 1)))
    done <<< "$child_tasks"
    
    echo -n "$result"
}

# テンプレートを処理する関数
process_template() {
    local template_file="$1"
    local data="$2"
    
    # テンプレートファイルの存在確認
    if [[ ! -f "$template_file" ]]; then
        log_error "テンプレートファイルが見つかりません: $template_file"
        return 1
    fi
    
    # 階層的なタスクリストを生成する
    local output="# タスク一覧\n\n"
    
    # ルートタスク（親を持たないタスク）の一覧を取得
    local root_tasks=$(yq eval '.tasks[] | select(.parent == null or .parent == "") | .id' "$TASKS_FILE")
    
    # 各ルートタスクを処理
    while IFS= read -r task_id; do
        if [[ -z "$task_id" ]]; then
            continue
        fi
        output+=$(process_task_hierarchy "$task_id" 0)
    done <<< "$root_tasks"
    
    # 最終的な出力をより整えるための処理
    # 連続した改行を1つに統一するなどの整形処理を行う
    output=$(echo -e "$output" | sed -E 's/\n{3,}/\n\n/g')
    
    echo -e "$output"
}

# テンプレートを使ってタスクファイルを生成
generate_task_file_from_template() {
    local template_name=$(get_current_template)
    local template_file="${TEMPLATES_DIR}/${template_name}.template"
    
    # テンプレートファイルの存在確認
    if [[ ! -f "$template_file" ]]; then
        log_error "テンプレートファイルが見つかりません: $template_file"
        create_default_template
        template_file="${TEMPLATES_DIR}/default.template"
    fi
    
    # タスクデータの取得
    local tasks_data=$(get_tasks_data)
    
    # テンプレートエンジンを使ってタスクファイルを生成
    local output=$(process_template "$template_file" "$tasks_data")
    
    # 出力ファイルに書き込み
    echo "$output" > "$PROJECT_TASKS_FILE"
    
    log_info "タスクファイルを生成しました: $PROJECT_TASKS_FILE"
    log_info "Template generated successfully"
    
    return 0
}

# 子タスクの統計情報を取得
get_child_task_stats() {
    local parent_id="$1"
    local completed=0
    local in_progress=0
    local not_started=0
    local total=0
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"
    
    # 子タスクを取得
    local child_tasks
    child_tasks=$(yq eval ".tasks[] | select(.parent == \"$parent_id\") | .id" "$tasks_file")
    
    # 各子タスクを処理
    while IFS= read -r child_id; do
        if [[ -z "$child_id" ]]; then
            continue
        fi
        
        # 子タスクのステータスを取得
        local status
        status=$(yq eval ".tasks[] | select(.id == \"$child_id\") | .status" "$tasks_file")
        
        case "$status" in
            "completed")
                ((completed++))
                ;;
            "in_progress")
                ((in_progress++))
                ;;
            *)
                ((not_started++))
                ;;
        esac
        ((total++))
        
        # 孫タスクの統計情報を再帰的に取得
        local child_stats
        child_stats=$(get_child_task_stats "$child_id")
        completed=$((completed + $(echo "$child_stats" | cut -d' ' -f1)))
        in_progress=$((in_progress + $(echo "$child_stats" | cut -d' ' -f2)))
        not_started=$((not_started + $(echo "$child_stats" | cut -d' ' -f3)))
        total=$((total + $(echo "$child_stats" | cut -d' ' -f4)))
    done <<< "$child_tasks"
    
    echo "$completed $in_progress $not_started $total"
}

# テンプレートの生成
generate_template() {
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"
    local template_file="${TASK_DIR}/tasks/templates/default.template"
    local output_file="${TASK_DIR}/tasks/project.tasks"
    
    # タスクファイルの存在確認
    if [[ ! -f "$tasks_file" ]]; then
        log_error "Task file not found: $tasks_file"
        return 1
    fi
    
    # テンプレートファイルの存在確認
    if [[ ! -f "$template_file" ]]; then
        log_error "Template file not found: $template_file"
        return 1
    fi
    
    # 統計情報の初期化
    local completed_count=0
    local in_progress_count=0
    local not_started_count=0
    local total_count=0
    local task_list=""
    
    # タスク一覧の生成
    while IFS= read -r task; do
        if [[ -z "$task" ]]; then
            continue
        fi
        
        # タスク情報の取得
        local id=$(echo "$task" | yq eval '.id' -)
        local name=$(echo "$task" | yq eval '.name' -)
        local status=$(echo "$task" | yq eval '.status' -)
        local description=$(echo "$task" | yq eval '.description' -)
        local concerns=$(echo "$task" | yq eval '.concerns' -)
        
        # ステータス記号の設定と統計情報の更新
        local symbol
        case "$status" in
            "completed")
                symbol="✓"
                ((completed_count++))
                ;;
            "in_progress")
                symbol="⚡"
                ((in_progress_count++))
                ;;
            *)
                symbol="□"
                ((not_started_count++))
            ;;
    esac
        ((total_count++))
        
        # タスク行の生成
        task_list+="$symbol $name (ID: $id)\n"
        
        # 詳細情報の追加（空でない場合のみ）
        if [[ -n "$description" && "$description" != "null" ]]; then
            task_list+="  Description: $description\n"
        fi
        if [[ -n "$concerns" && "$concerns" != "null" ]]; then
            task_list+="  Concerns: $concerns\n"
        fi
        task_list+="\n"
    done < <(yq eval '.tasks[]' "$tasks_file")
    
    # テンプレートの読み込みと置換
    local template
    template=$(<"$template_file")
    
    # テンプレートの置換
    local output="$template"
    output=${output//\{\{tasks\}\}/"$task_list"}
    output=${output//\{\{completed_count\}\}/$completed_count}
    output=${output//\{\{in_progress_count\}\}/$in_progress_count}
    output=${output//\{\{not_started_count\}\}/$not_started_count}
    output=${output//\{\{total_count\}\}/$total_count}
    
    # 出力ファイルの生成
    echo -e "$output" > "$output_file"
    
    if [[ $? -eq 0 ]]; then
        log_info "Template generated successfully: $output_file"
        return 0
    else
        log_error "Failed to generate template"
        return 1
    fi
}
