#!/bin/bash

# 入力検証関数

# 共通ユーティリティ関数の読み込み
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# タスクIDの形式を検証
validate_task_id() {
    local task_id=$1
    if [[ ! $task_id =~ ^[A-Z]{2}[0-9]{2}$ ]]; then
        handle_error "Invalid task ID format: $task_id (expected format: AA00)"
    fi
}

# タスク名の検証
validate_task_name() {
    local task_name=$1
    if [ -z "$task_name" ]; then
        handle_error "Task name cannot be empty"
    fi
    if [ ${#task_name} -gt 100 ]; then
        handle_error "Task name is too long (max 100 characters)"
    fi
}

# タスクステータスの検証
validate_task_status() {
    local status=$1
    local valid_statuses=("not_started" "in_progress" "completed")
    local valid=false
    
    for valid_status in "${valid_statuses[@]}"; do
        if [ "$status" = "$valid_status" ]; then
            valid=true
            break
        fi
    done
    
    if [ "$valid" = false ]; then
        handle_error "Invalid task status: $status (valid: ${valid_statuses[*]})"
    fi
}

# 必須パラメータの検証
validate_required_param() {
    local param_value=$1
    local param_name=$2
    
    if [ -z "$param_value" ]; then
        handle_error "Required parameter '$param_name' is missing"
    fi
}

# ファイルパスの検証
validate_file_path() {
    local file_path=$1
    local create_if_missing=${2:-false}
    
    if [ ! -e "$file_path" ]; then
        if [ "$create_if_missing" = true ]; then
            touch "$file_path" || handle_error "Failed to create file: $file_path"
            log $LOG_LEVEL_INFO "Created file: $file_path"
        else
            handle_error "File not found: $file_path"
        fi
    fi
}

# ディレクトリパスの検証
validate_directory() {
    local dir_path=$1
    local create_if_missing=${2:-false}
    
    if [ ! -d "$dir_path" ]; then
        if [ "$create_if_missing" = true ]; then
            create_directory "$dir_path"
        else
            handle_error "Directory not found: $dir_path"
        fi
    fi
}

# YAMLファイルの構文検証
validate_yaml_syntax() {
    local yaml_file=$1
    check_dependency "yq"
    
    if ! yq eval '.' "$yaml_file" > /dev/null 2>&1; then
        handle_error "Invalid YAML syntax in file: $yaml_file"
    fi
}

# テンプレート名の検証
validate_template_name() {
    local template_name=$1
    local valid_templates=("default" "compact" "detailed")
    local valid=false
    
    for valid_template in "${valid_templates[@]}"; do
        if [ "$template_name" = "$valid_template" ]; then
            valid=true
            break
        fi
    done
    
    if [ "$valid" = false ]; then
        handle_error "Invalid template name: $template_name (valid: ${valid_templates[*]})"
    fi
}

# コマンドライン引数の数を検証
validate_args_count() {
    local actual=$1
    local expected=$2
    local command=$3
    
    if [ "$actual" -ne "$expected" ]; then
        handle_error "Invalid number of arguments for '$command' command. Expected $expected, got $actual"
    fi
}

# 数値の検証
validate_number() {
    local number=$1
    local param_name=$2
    
    if ! [[ "$number" =~ ^[0-9]+$ ]]; then
        handle_error "Invalid $param_name: $number (must be a number)"
    fi
}

# 日付形式の検証
validate_date() {
    local date=$1
    local param_name=$2
    
    if ! date -d "$date" > /dev/null 2>&1; then
        handle_error "Invalid $param_name format: $date (expected format: YYYY-MM-DD)"
    fi
} 