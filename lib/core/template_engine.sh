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

# テンプレート設定を読み込む
load_template_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "テンプレート設定ファイルが見つかりません: $CONFIG_FILE"
        return 1
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
    echo "${TEMPLATES_DIR}/${template_name}.template"
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

# タスクファイルをテンプレートから生成
generate_task_file_from_template() {
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"
    local output_file="${TASK_DIR}/tasks/project.tasks"
    
    # タスクファイルの存在確認
    if [[ ! -f "$tasks_file" ]]; then
        log_error "タスクファイルが見つかりません: $tasks_file"
        return 1
    fi
    
    # 統計情報の初期化
    local completed_count=0
    local in_progress_count=0
    local not_started_count=0
    local total_count=0
    local task_list=""
    
    # ルートレベルのタスクを取得
    local root_tasks
    root_tasks=$(yq eval '.tasks[] | select(.parent == null) | .id' "$tasks_file")
    
    # 各ルートタスクを処理
    while IFS= read -r task_id; do
        if [[ -z "$task_id" ]]; then
            continue
        fi
        
        # タスク情報の取得
        local name=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .name" "$tasks_file")
        local status=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .status" "$tasks_file")
        local description=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .description" "$tasks_file")
        local concerns=$(yq eval ".tasks[] | select(.id == \"$task_id\") | .concerns" "$tasks_file")
        
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
        task_list+="${symbol} ${name} (ID: ${task_id})"$'\n'
        
        # 詳細情報の追加（空でない場合のみ）
        if [[ -n "$description" && "$description" != "null" ]]; then
            task_list+="  Description: ${description}"$'\n'
        fi
        if [[ -n "$concerns" && "$concerns" != "null" ]]; then
            task_list+="  Concerns: ${concerns}"$'\n'
        fi
        task_list+=$'\n'
        
        # 子タスクを再帰的に処理
        local child_tasks
        child_tasks=$(yq eval ".tasks[] | select(.parent == \"$task_id\") | .id" "$tasks_file")
        
        while IFS= read -r child_id; do
            if [[ -z "$child_id" ]]; then
                continue
            fi
            
            # 子タスク情報の取得
            local child_name=$(yq eval ".tasks[] | select(.id == \"$child_id\") | .name" "$tasks_file")
            local child_status=$(yq eval ".tasks[] | select(.id == \"$child_id\") | .status" "$tasks_file")
            local child_description=$(yq eval ".tasks[] | select(.id == \"$child_id\") | .description" "$tasks_file")
            local child_concerns=$(yq eval ".tasks[] | select(.id == \"$child_id\") | .concerns" "$tasks_file")
            
            # 子タスクのステータス記号の設定と統計情報の更新
            local child_symbol
            case "$child_status" in
                "completed")
                    child_symbol="✓"
                    ((completed_count++))
                    ;;
                "in_progress")
                    child_symbol="⚡"
                    ((in_progress_count++))
                    ;;
                *)
                    child_symbol="□"
                    ((not_started_count++))
                    ;;
            esac
            ((total_count++))
            
            # 子タスク行の生成（インデント付き）
            task_list+="  ${child_symbol} ${child_name} (ID: ${child_id})"$'\n'
            
            # 子タスクの詳細情報の追加（空でない場合のみ）
            if [[ -n "$child_description" && "$child_description" != "null" ]]; then
                task_list+="    Description: ${child_description}"$'\n'
            fi
            if [[ -n "$child_concerns" && "$child_concerns" != "null" ]]; then
                task_list+="    Concerns: ${child_concerns}"$'\n'
            fi
            task_list+=$'\n'
            
            # 孫タスクを再帰的に処理
            local grandchild_tasks
            grandchild_tasks=$(yq eval ".tasks[] | select(.parent == \"$child_id\") | .id" "$tasks_file")
            
            while IFS= read -r grandchild_id; do
                if [[ -z "$grandchild_id" ]]; then
                    continue
                fi
                
                # 孫タスク情報の取得
                local grandchild_name=$(yq eval ".tasks[] | select(.id == \"$grandchild_id\") | .name" "$tasks_file")
                local grandchild_status=$(yq eval ".tasks[] | select(.id == \"$grandchild_id\") | .status" "$tasks_file")
                local grandchild_description=$(yq eval ".tasks[] | select(.id == \"$grandchild_id\") | .description" "$tasks_file")
                local grandchild_concerns=$(yq eval ".tasks[] | select(.id == \"$grandchild_id\") | .concerns" "$tasks_file")
                
                # 孫タスクのステータス記号の設定と統計情報の更新
                local grandchild_symbol
                case "$grandchild_status" in
                    "completed")
                        grandchild_symbol="✓"
                        ((completed_count++))
                        ;;
                    "in_progress")
                        grandchild_symbol="⚡"
                        ((in_progress_count++))
                        ;;
                    *)
                        grandchild_symbol="□"
                        ((not_started_count++))
                        ;;
                esac
                ((total_count++))
                
                # 孫タスク行の生成（インデント付き）
                task_list+="    ${grandchild_symbol} ${grandchild_name} (ID: ${grandchild_id})"$'\n'
                
                # 孫タスクの詳細情報の追加（空でない場合のみ）
                if [[ -n "$grandchild_description" && "$grandchild_description" != "null" ]]; then
                    task_list+="      Description: ${grandchild_description}"$'\n'
                fi
                if [[ -n "$grandchild_concerns" && "$grandchild_concerns" != "null" ]]; then
                    task_list+="      Concerns: ${grandchild_concerns}"$'\n'
                fi
                task_list+=$'\n'
            done <<< "$grandchild_tasks"
        done <<< "$child_tasks"
    done <<< "$root_tasks"
    
    # 統計情報の追加
    local stats="Task Statistics:"$'\n'
    stats+="Completed: ${completed_count}"$'\n'
    stats+="In Progress: ${in_progress_count}"$'\n'
    stats+="Not Started: ${not_started_count}"$'\n'
    stats+="Total: ${total_count}"$'\n'
    
    # 出力ファイルの生成
    {
        echo "Task Management System"
        echo "====================="
        echo
        echo -n "$task_list"
        echo "$stats"
    } > "$output_file"
    
    if [[ $? -eq 0 ]]; then
        log_info "タスクファイルを生成しました: $output_file"
        return 0
    else
        log_error "タスクファイルの生成に失敗しました"
        return 1
    fi
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
