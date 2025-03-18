#!/bin/bash
# YAMLデータ操作モジュール

# 共通ユーティリティの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ルートディレクトリを設定
TASK_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

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
    }
    return 0
}

# YAMLファイルのバックアップを作成
backup_yaml_file() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/tasks_${timestamp}.yaml"
    
    mkdir -p "$BACKUP_DIR"
    if ! cp "$TASKS_YAML_FILE" "$backup_file"; then
        log_error "バックアップの作成に失敗しました"
        return 1
    }
    
    log_info "バックアップを作成しました: $backup_file"
    return 0
}

# 新しいタスクIDを生成
generate_task_id() {
    local parent_id="$1"
    local prefix
    local current_max
    
    if [[ -n "$parent_id" ]]; then
        # サブタスクの場合は親タスクのIDをプレフィックスとして使用
        prefix="${parent_id}"
        current_max=$(yq eval ".tasks[] | select(.parent == \"$parent_id\") | .id" "$TASKS_YAML_FILE" | grep -o '[0-9]*$' | sort -n | tail -n 1)
    else
        # ルートタスクの場合は新しいプレフィックスを生成
        prefix="PA"
        current_max=$(yq eval '.tasks[] | select(.parent == null) | .id' "$TASKS_YAML_FILE" | grep -o '[0-9]*$' | sort -n | tail -n 1)
    fi
    
    if [[ -z "$current_max" ]]; then
        current_max=0
    fi
    
    printf "%s%02d" "$prefix" $((current_max + 1))
}

# タスクの存在確認
task_exists() {
    local task_id="$1"
    
    if yq eval ".tasks[] | select(.id == \"$task_id\")" "$TASKS_YAML_FILE" > /dev/null; then
        return 0
    fi
    return 1
}

# タスクの取得
get_task() {
    local task_id="$1"
    
    if ! task_exists "$task_id"; then
        log_error "タスクが見つかりません: $task_id"
        return 1
    fi
    
    yq eval ".tasks[] | select(.id == \"$task_id\")" "$TASKS_YAML_FILE"
    return 0
}

# タスクの追加
add_task() {
    local name="$1"
    local status="${2:-not_started}"
    local parent="${3:-null}"
    local content="${4:-}"
    local concerns="${5:-}"
    
    # 親タスクの存在確認
    if [[ -n "$parent" && "$parent" != "null" ]]; then
        if ! task_exists "$parent"; then
            log_error "親タスクが見つかりません: $parent"
            return 1
        fi
    fi
    
    # 新しいタスクIDを生成
    local new_id
    new_id=$(generate_task_id "$parent")
    
    # 一時ファイルを作成
    local temp_file
    temp_file=$(mktemp)
    
    # 新しいタスクを追加
    {
        echo "tasks:"
        yq eval '.tasks[]' "$TASKS_YAML_FILE" > "$temp_file"
        cat "$temp_file"
        echo "- id: \"$new_id\""
        echo "  name: \"$name\""
        echo "  status: \"$status\""
        if [[ -n "$parent" && "$parent" != "null" ]]; then
            echo "  parent: \"$parent\""
        else
            echo "  parent: null"
        fi
        echo "  details:"
        echo "    content: \"$content\""
        echo "    concerns: \"$concerns\""
        echo "    results: \"\""
        echo "    result_concerns: \"\""
    } > "$TASKS_YAML_FILE"
    
    rm -f "$temp_file"
    log_info "タスクを追加しました: $new_id"
    echo "$new_id"
    return 0
}

# タスクの更新
update_task() {
    local task_id="$1"
    local field="$2"
    local value="$3"
    
    if ! task_exists "$task_id"; then
        log_error "タスクが見つかりません: $task_id"
        return 1
    fi
    
    # バックアップを作成
    backup_yaml_file
    
    # フィールドを更新
    case "$field" in
        "name"|"status"|"parent")
            yq eval ".tasks[] |= select(.id == \"$task_id\").$field = \"$value\"" -i "$TASKS_YAML_FILE"
            ;;
        "content"|"concerns"|"results"|"result_concerns")
            yq eval ".tasks[] |= select(.id == \"$task_id\").details.$field = \"$value\"" -i "$TASKS_YAML_FILE"
            ;;
        *)
            log_error "不明なフィールド: $field"
            return 1
            ;;
    esac
    
    log_info "タスクを更新しました: $task_id ($field)"
    return 0
}

# タスクの削除
delete_task() {
    local task_id="$1"
    
    if ! task_exists "$task_id"; then
        log_error "タスクが見つかりません: $task_id"
        return 1
    fi
    
    # 子タスクの存在確認
    if yq eval ".tasks[] | select(.parent == \"$task_id\")" "$TASKS_YAML_FILE" > /dev/null; then
        log_error "子タスクが存在するため削除できません: $task_id"
        return 1
    fi
    
    # バックアップを作成
    backup_yaml_file
    
    # タスクを削除
    yq eval "del(.tasks[] | select(.id == \"$task_id\"))" -i "$TASKS_YAML_FILE"
    
    log_info "タスクを削除しました: $task_id"
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
        "name"|"status"|"id")
            yq eval ".tasks |= sort_by(.$sort_field)" -i "$TASKS_YAML_FILE"
            ;;
        *)
            log_error "不明なソートフィールド: $sort_field"
            return 1
            ;;
    esac

    if [[ "$sort_order" == "desc" ]]; then
        yq eval '.tasks = reverse(.tasks)' -i "$TASKS_YAML_FILE"
    fi

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
