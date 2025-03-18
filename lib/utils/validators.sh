#!/bin/bash

# 入力検証関数

# 共通ユーティリティ関数の読み込み
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# タスクIDの形式を検証
validate_task_id() {
    local id="$1"
    
    # 形式チェック（PA01, PB01など）
    if [[ ! "$id" =~ ^[A-Z]{2}[0-9]{2}$ ]]; then
        return 1
    fi
    
    return 0
}

# タスク名の検証
validate_task_name() {
    local name="$1"
    
    # 空文字チェック
    if [[ -z "$name" ]]; then
        return 1
    fi
    
    # 長さチェック（1-100文字）
    if [[ ${#name} -gt 100 ]]; then
        return 1
    fi
    
    return 0
}

# タスクステータスの検証
validate_task_status() {
    local status="$1"
    local valid_statuses=("not_started" "in_progress" "completed")
    
    for valid_status in "${valid_statuses[@]}"; do
        if [[ "$status" == "$valid_status" ]]; then
            return 0
        fi
    done
    
    return 1
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
    local path="$1"
    
    # パスの存在チェック
    if [[ ! -e "$path" ]]; then
        return 1
    fi
    
    return 0
}

# ディレクトリパスの検証
validate_directory_path() {
    local path="$1"
    
    # ディレクトリの存在チェック
    if [[ ! -d "$path" ]]; then
        return 1
    fi
    
    return 0
}

# YAML構文の検証
validate_yaml_syntax() {
    local file="$1"
    
    # ファイルの存在チェック
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # YAML構文チェック
    if ! yq eval '.' "$file" > /dev/null 2>&1; then
        return 1
    fi
    
    return 0
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
validate_date_format() {
    local date="$1"
    local format="${2:-%Y-%m-%d}"
    
    # 日付形式チェック
    if ! date -j -f "$format" "$date" > /dev/null 2>&1; then
        return 1
    fi
    
    return 0
}

# 優先度の検証
validate_priority() {
    local priority="$1"
    
    case "$priority" in
        "high"|"medium"|"low")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# コマンドライン引数の検証
validate_command_args() {
    local command="$1"
    shift
    local args=("$@")
    
    case "$command" in
        "add")
            # addコマンドの引数検証
            if [[ ${#args[@]} -lt 1 ]]; then
                return 1
            fi
            ;;
        "status")
            # statusコマンドの引数検証
            if [[ ${#args[@]} -lt 2 ]]; then
                return 1
            fi
            if ! validate_task_id "${args[0]}"; then
                return 1
            fi
            if ! validate_task_status "${args[1]}"; then
                return 1
            fi
            ;;
        "template")
            # templateコマンドの引数検証
            if [[ ${#args[@]} -lt 1 ]]; then
                return 1
            fi
            ;;
        *)
            # 不明なコマンド
            return 1
            ;;
    esac
    
    return 0
} 