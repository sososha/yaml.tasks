#!/bin/bash
# YAMLデータ操作モジュール

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 共通ユーティリティの読み込み
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/validators.sh"
source "${SCRIPT_DIR}/template_engine.sh"

# タスク管理システムのルートディレクトリを設定（未定義の場合のみ）
if [[ -z "$TASK_DIR" ]]; then
    TASK_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
fi

# 依存関係の確認
if ! command -v yq &> /dev/null; then
    echo "エラー: yqコマンドが見つかりません。インストールしてください。"
    echo "brew install yq"
    exit 1
fi

# 定数
TASKS_YAML_FILE="${TASK_DIR}/tasks/tasks.yaml"
BACKUP_DIR="${TASK_DIR}/tasks/backups"

# YAMLファイルの存在確認
validate_yaml_file() {
    if [[ ! -f "$TASKS_YAML_FILE" ]]; then
        log_error "タスクファイルが見つかりません: $TASKS_YAML_FILE"
        return 1
    fi
    return 0
}

# YAMLファイルのバックアップを作成
backup_yaml_file() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/tasks_${timestamp}.yaml"
    
    # バックアップディレクトリの作成
    mkdir -p "$BACKUP_DIR"
    
    # タスクファイルの存在確認
    if [[ ! -f "$TASKS_YAML_FILE" ]]; then
        log_error "タスクファイルが見つかりません: $TASKS_YAML_FILE"
        return 1
    fi
    
    # バックアップの作成
    if ! cp "$TASKS_YAML_FILE" "$backup_file"; then
        log_error "バックアップの作成に失敗しました"
        return 1
    fi
    
    log_info "バックアップを作成しました: $backup_file"
    return 0
}

# タスクIDの生成
generate_task_id() {
    local prefix="${1:-TA}"
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"
    local next_number=1
    
    if [[ ! -f "$tasks_file" ]]; then
        echo "tasks: []" > "$tasks_file"
    fi
    
    # すべてのタスクIDから最大の番号を見つける（プレフィックスに関係なく）
    if [[ -s "$tasks_file" ]]; then
        local max_id
        max_id=$(grep -o "[A-Z0-9]*[0-9]\+" "$tasks_file" | sed "s/[^0-9]//g" | sort -n | tail -1)
        
        if [[ -n "$max_id" ]]; then
            next_number=$((max_id + 1))
        fi
    fi
    
    # 2桁でゼロパディング
    printf "%s%02d" "$prefix" "$next_number"
}

# タスクの存在確認
task_exists() {
    local task_id="$1"
    
    if ! validate_yaml_file; then
        return 1
    fi
    
    local count
    count=$(yq eval ".tasks[] | select(.id == \"$task_id\") | length" "$TASKS_YAML_FILE" 2>/dev/null)
    
    if [[ -z "$count" || "$count" -eq 0 ]]; then
        return 1
    fi
    
    return 0
}

# タスクの取得
get_task() {
    local task_id="$1"
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"
    
    if ! task_exists "$task_id"; then
        return 1
    fi
    
    yq eval ".tasks[] | select(.id == \"$task_id\")" "$tasks_file"
    return 0
}

# タスクの追加
add_task() {
    local task_id="$1"
    local name="$2"
    local description="${3:-}"
    local concerns="${4:-}"
    local parent_id="${5:-}"
    local status="${6:-not_started}"
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"
    
    # 入力検証
    if [[ -z "$task_id" ]]; then
        log_error "タスクIDは必須です"
        return 1
    fi
    
    if [[ -z "$name" ]]; then
        log_error "タスク名は必須です"
        return 1
    fi
    
    if ! validate_task_status "$status"; then
        log_error "無効なタスクステータス: $status"
        return 1
    fi
    
    # 親タスクの存在確認（指定されている場合）
    if [[ -n "$parent_id" ]]; then
        if ! task_exists "$parent_id"; then
            log_error "親タスクが見つかりません: $parent_id"
            return 1
        fi
    fi
    
    # タスクファイルの存在確認と作成
    if [[ ! -f "$tasks_file" ]]; then
        mkdir -p "$(dirname "$tasks_file")"
        echo "tasks: []" > "$tasks_file"
    fi
    
    # タスクIDの重複チェック
    if task_exists "$task_id"; then
        log_error "タスクIDが既に存在します: $task_id"
        return 1
    fi
    
    # 一時ファイルの作成
    local temp_file=$(mktemp)
    
    # 新しいタスクのYAMLを作成
    {
        echo "id: \"$task_id\""
        echo "name: \"$name\""
        echo "status: \"$status\""
        echo "created_at: \"$(date +%Y-%m-%d)\""
        echo "updated_at: \"$(date +%Y-%m-%d)\""
        if [[ -n "$parent_id" ]]; then
            echo "parent: \"$parent_id\""
        fi
        if [[ -n "$description" ]]; then
            echo "description: \"$description\""
        fi
        if [[ -n "$concerns" ]]; then
            echo "concerns: \"$concerns\""
        fi
    } > "$temp_file"
    
    # タスクを追加
    if ! yq eval -i ".tasks += [load(\"$temp_file\")]" "$tasks_file"; then
        log_error "YAMLファイルへのタスク追加に失敗しました"
        rm -f "$temp_file"
        return 1
    fi
    
    rm -f "$temp_file"
    log_info "タスクを追加しました: $task_id"
    return 0
}

# タスクの更新
update_task() {
    local task_id="$1"
    local field="$2"
    local value="$3"
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"

    # タスクの存在確認
    if ! task_exists "$task_id"; then
        log_error "タスクが見つかりません: $task_id"
        return 1
    fi

    # フィールドの検証
    case "$field" in
        "name"|"status"|"description"|"concerns"|"parent")
            ;;
        *)
            log_error "不正なフィールド: $field"
            return 1
            ;;
    esac

    # バックアップの作成
    if ! backup_yaml_file; then
        log_error "バックアップの作成に失敗しました"
        return 1
    fi

    # タスクの更新
    local current_date=$(date +%Y-%m-%d)
    if yq eval -i ".tasks[] |= select(.id == \"$task_id\") |= .${field} = \"$value\" | .tasks[] |= select(.id == \"$task_id\") |= .updated_at = \"$current_date\"" "$tasks_file"; then
        return 0
    else
        log_error "タスクの更新に失敗しました"
        return 1
    fi
}

# タスクの削除
delete_task() {
    local task_id="$1"
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"
    
    # タスクの存在確認
    if ! task_exists "$task_id"; then
        log_error "Task not found: $task_id"
        return 1
    fi
    
    # タスクの削除
    if ! yq eval -i "del(.tasks[] | select(.id == \"$task_id\"))" "$tasks_file"; then
        log_error "Failed to delete task"
        return 1
    fi
    
    return 0
}

# タスクの移動（親タスクの変更）
move_task() {
    local task_id="$1"
    local new_parent="${2:-null}"
    
    if ! task_exists "$task_id"; then
        log_error "タスクが見つかりません: $task_id"
        return 1
    fi
    
    # 新しい親タスクの存在確認（nullでない場合）
    if [[ -n "$new_parent" && "$new_parent" != "null" ]]; then
        if ! task_exists "$new_parent"; then
            log_error "新しい親タスクが見つかりません: $new_parent"
            return 1
        fi
        
        # 循環参照のチェック
        local current_parent="$new_parent"
        while [[ -n "$current_parent" && "$current_parent" != "null" ]]; do
            if [[ "$current_parent" == "$task_id" ]]; then
                log_error "循環参照が検出されました"
                return 1
            fi
            current_parent=$(yq eval ".tasks[] | select(.id == \"$current_parent\").parent" "$TASKS_YAML_FILE")
        done
    fi
    
    # バックアップを作成
    backup_yaml_file
    
    # 親タスクを更新
    update_task "$task_id" "parent" "$new_parent"
    
    log_info "タスクを移動しました: $task_id -> $new_parent"
    return 0
}

# タスクの並び替え
sort_tasks() {
    local sort_field="$1"
    local sort_order="${2:-asc}"
    
    # バックアップを作成
    backup_yaml_file
    
    # ソート処理
    case "$sort_field" in
        "id"|"name"|"status")
            if [[ "$sort_order" == "desc" ]]; then
                yq eval ".tasks |= sort_by(.$sort_field) | reverse" -i "$TASKS_YAML_FILE"
            else
                yq eval ".tasks |= sort_by(.$sort_field)" -i "$TASKS_YAML_FILE"
            fi
            ;;
        *)
            log_error "不明なソートフィールド: $sort_field"
            return 1
            ;;
    esac
    
    log_info "タスクを並び替えました: $sort_field ($sort_order)"
    return 0
}

# タスクの検索
search_tasks() {
    local query="$1"
    
    yq eval ".tasks[] | select(.name | test(\"$query\", \"i\") or .details.content | test(\"$query\", \"i\"))" "$TASKS_YAML_FILE"
    return 0
}

# 子タスクの取得
get_child_tasks() {
    local parent_id="$1"
    
    if ! task_exists "$parent_id"; then
        log_error "タスクが見つかりません: $parent_id"
        return 1
    fi
    
    yq eval ".tasks[] | select(.parent == \"$parent_id\")" "$TASKS_YAML_FILE"
    return 0
}

# タスク統計の取得
get_task_stats() {
    local total=$(yq eval '.tasks | length' "$TASKS_YAML_FILE")
    local completed=$(yq eval '.tasks[] | select(.status == "completed") | length' "$TASKS_YAML_FILE")
    local in_progress=$(yq eval '.tasks[] | select(.status == "in_progress") | length' "$TASKS_YAML_FILE")
    local not_started=$(yq eval '.tasks[] | select(.status == "not_started") | length' "$TASKS_YAML_FILE")
    
    echo "タスク統計:"
    echo "  全タスク数: $total"
    echo "  完了: $completed"
    echo "  進行中: $in_progress"
    echo "  未着手: $not_started"
    
    if [[ $total -gt 0 ]]; then
        local completion_rate=$((completed * 100 / total))
        echo "  完了率: ${completion_rate}%"
    fi
    
    return 0
}

# タスクのステータス更新
update_task_status() {
    local task_id="$1"
    local new_status="$2"
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"
    
    # タスクの存在確認
    if ! task_exists "$task_id"; then
        log_error "タスクが見つかりません: $task_id"
        return 1
    fi
    
    # ステータスの検証
    if ! validate_task_status "$new_status"; then
        log_error "無効なステータスです: $new_status"
        return 1
    fi
    
    # バックアップの作成
    if ! backup_yaml_file; then
        log_error "バックアップの作成に失敗しました"
        return 1
    fi
    
    # タスクのステータスを更新
    local temp_file="${tasks_file}.tmp"
    yq eval -i ".tasks[] |= select(.id == \"$task_id\").status = \"$new_status\"" "$tasks_file"
    
    if [[ $? -eq 0 ]]; then
        log_info "更新したタスク: $task_id"
        return 0
    else
        log_error "タスクファイルの更新に失敗しました"
        return 1
    fi
}
