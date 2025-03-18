#!/bin/bash
# データ整合性検証モジュール

# 共通ユーティリティの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# ルートディレクトリを設定（未定義の場合のみ）
if [[ -z "$TASK_DIR" ]]; then
    TASK_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
fi

# 定数
TASKS_FILE="${TASK_DIR}/tasks/tasks.yaml"
CONFIG_FILE="${TASK_DIR}/tasks/config/template_config.yaml"

# YAMLファイルの構文チェック
validate_yaml_syntax() {
    local file="$1"
    if ! yq eval '.' "$file" > /dev/null 2>&1; then
        log_error "無効なYAML構文: $file"
        return 1
    fi
    return 0
}

# タスクIDの形式チェック
validate_task_id_format() {
    local task_id="$1"
    if [[ ! "$task_id" =~ ^[A-Z]{2}[0-9]{2}$ ]]; then
        log_error "無効なタスクID形式: $task_id"
        return 1
    fi
    return 0
}

# タスクステータスの検証
validate_task_status() {
    local status="$1"
    case "$status" in
        "not_started"|"in_progress"|"completed")
            return 0
            ;;
        *)
            log_error "無効なタスクステータス: $status"
            return 1
            ;;
    esac
}

# 親子関係の循環参照チェック
check_circular_reference() {
    local task_id="$1"
    local visited=()
    local current="$task_id"

    while [[ -n "$current" && "$current" != "null" ]]; do
        # 循環参照の検出
        for visited_id in "${visited[@]}"; do
            if [[ "$visited_id" == "$current" ]]; then
                log_error "循環参照を検出: $task_id"
                return 1
            fi
        done

        # 訪問済みリストに追加
        visited+=("$current")

        # 親タスクを取得
        current=$(yq eval ".tasks[] | select(.id == \"$current\").parent" "$TASKS_FILE")
    done

    return 0
}

# 必須フィールドの存在チェック
validate_required_fields() {
    local task="$1"
    local required_fields=("id" "name" "status" "details")

    for field in "${required_fields[@]}"; do
        if ! echo "$task" | yq eval "has(\"$field\")" - | grep -q "true"; then
            log_error "必須フィールドがありません: $field"
            return 1
        fi
    done

    return 0
}

# 親タスクの存在チェック
validate_parent_task() {
    local parent_id="$1"
    
    if [[ "$parent_id" != "null" ]]; then
        if ! yq eval ".tasks[] | select(.id == \"$parent_id\")" "$TASKS_FILE" > /dev/null; then
            log_error "親タスクが見つかりません: $parent_id"
            return 1
        fi
    fi
    return 0
}

# タスクデータの整合性チェック
validate_task_data() {
    local task_id="$1"
    local task
    task=$(yq eval ".tasks[] | select(.id == \"$task_id\")" "$TASKS_FILE")

    # 必須フィールドのチェック
    if ! validate_required_fields "$task"; then
        return 1
    fi

    # タスクIDの形式チェック
    if ! validate_task_id_format "$task_id"; then
        return 1
    fi

    # ステータスの検証
    local status
    status=$(echo "$task" | yq eval '.status' -)
    if ! validate_task_status "$status"; then
        return 1
    fi

    # 親タスクの検証
    local parent_id
    parent_id=$(echo "$task" | yq eval '.parent' -)
    if ! validate_parent_task "$parent_id"; then
        return 1
    fi

    # 循環参照のチェック
    if ! check_circular_reference "$task_id"; then
        return 1
    fi

    return 0
}

# 全タスクデータの検証
validate_all_tasks() {
    local success=true
    local tasks
    tasks=$(yq eval '.tasks[]' "$TASKS_FILE")

    while IFS= read -r task; do
        if [[ -z "$task" ]]; then
            continue
        fi

        local task_id
        task_id=$(echo "$task" | yq eval '.id' -)
        
        if ! validate_task_data "$task_id"; then
            success=false
            log_error "タスクの検証に失敗: $task_id"
        fi
    done <<< "$tasks"

    if [[ "$success" == "true" ]]; then
        log_info "全タスクの検証が完了しました"
        return 0
    else
        log_error "タスクの検証で問題が見つかりました"
        return 1
    fi
}

# 設定ファイルの検証
validate_config() {
    # 設定ファイルの存在確認
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "設定ファイルが見つかりません: $CONFIG_FILE"
        return 1
    fi

    # YAML構文チェック
    if ! validate_yaml_syntax "$CONFIG_FILE"; then
        return 1
    fi

    # 必須設定の存在確認
    local required_settings=("current_template" "symbols" "format" "sections")
    for setting in "${required_settings[@]}"; do
        if ! yq eval "has(\"$setting\")" "$CONFIG_FILE" | grep -q "true"; then
            log_error "必須設定がありません: $setting"
            return 1
        fi
    done

    # シンボル設定の検証
    local required_symbols=("completed" "in_progress" "not_started")
    for symbol in "${required_symbols[@]}"; do
        if ! yq eval ".symbols.$symbol" "$CONFIG_FILE" > /dev/null 2>&1; then
            log_error "必須シンボルがありません: $symbol"
            return 1
        fi
    done

    return 0
}

# メイン検証関数
validate_data_integrity() {
    local check_config="${1:-true}"
    local success=true

    # タスクファイルの存在確認
    if [[ ! -f "$TASKS_FILE" ]]; then
        log_error "タスクファイルが見つかりません: $TASKS_FILE"
        return 1
    fi

    # YAML構文チェック
    if ! validate_yaml_syntax "$TASKS_FILE"; then
        return 1
    fi

    # 全タスクの検証
    if ! validate_all_tasks; then
        success=false
    fi

    # 設定ファイルの検証（オプション）
    if [[ "$check_config" == "true" ]]; then
        if ! validate_config; then
            success=false
        fi
    fi

    if [[ "$success" == "true" ]]; then
        log_info "データ整合性の検証が完了しました"
        return 0
    else
        log_error "データ整合性の検証で問題が見つかりました"
        return 1
    fi
} 