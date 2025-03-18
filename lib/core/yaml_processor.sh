#!/bin/bash
# YAMLデータ操作モジュール

# 共通ユーティリティの読み込み
source "$(dirname "$0")/../utils/common.sh"

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

# YAMLファイルが存在しない場合は初期化
initialize_yaml() {
    if [ ! -f "$TASKS_YAML_FILE" ]; then
        mkdir -p "$(dirname "$TASKS_YAML_FILE")"
        cat > "$TASKS_YAML_FILE" << EOF
tasks: []
EOF
        echo "タスクデータファイルを初期化しました: $TASKS_YAML_FILE"
    fi
}

# YAMLファイルからタスクデータを読み込む
load_tasks() {
    if [[ ! -f "$TASKS_YAML_FILE" ]]; then
        log_error "タスクファイルが見つかりません: $TASKS_YAML_FILE"
        return 1
    }
    
    # YAMLファイルの構文チェック
    if ! yq eval '.' "$TASKS_YAML_FILE" > /dev/null 2>&1; then
        log_error "タスクファイルの形式が無効です: $TASKS_YAML_FILE"
        return 1
    }
    
    return 0
}

# タスクデータをYAMLファイルに保存
save_tasks() {
    local temp_file="${TASKS_YAML_FILE}.tmp"
    
    if ! yq eval '.' "$1" > "$temp_file" 2>/dev/null; then
        log_error "タスクデータの保存に失敗しました"
        rm -f "$temp_file"
        return 1
    }
    
    mv "$temp_file" "$TASKS_YAML_FILE"
    return 0
}

# 新しいタスクIDを生成
generate_task_id() {
    local prefix="T"
    local current_count=0
    
    # 既存のタスクIDの最大値を取得
    if [[ -f "$TASKS_YAML_FILE" ]]; then
        current_count=$(yq eval '.tasks[].id' "$TASKS_YAML_FILE" | grep -oE '[0-9]+' | sort -n | tail -n 1)
    fi
    
    # 新しいIDを生成（現在の最大値+1）
    printf "%s%03d" "$prefix" $((current_count + 1))
}

# YAMLファイルに新しいタスクを追加
add_task_to_yaml() {
    local id="$1"
    local name="$2"
    local status="$3"
    local details="$4"
    local concerns="$5"
    
    # 必須パラメータのチェック
    if [[ -z "$id" || -z "$name" || -z "$status" ]]; then
        log_error "必須パラメータが不足しています"
        return 1
    }
    
    # タスクデータの作成
    local task_data
    task_data=$(cat << EOF
tasks:
  - id: "$id"
    name: "$name"
    status: "$status"
    parent: null
    details:
      content: "${details:-}"
      design: ""
      concerns: "${concerns:-}"
      results: ""
      result_concerns: ""
EOF
)
    
    # 既存のタスクファイルが存在しない場合は新規作成
    if [[ ! -f "$TASKS_YAML_FILE" ]]; then
        echo "$task_data" > "$TASKS_YAML_FILE"
        return 0
    }
    
    # 既存のタスクに新しいタスクを追加
    local temp_file="${TASKS_YAML_FILE}.tmp"
    yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$TASKS_YAML_FILE" <(echo "$task_data") > "$temp_file"
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$TASKS_YAML_FILE"
        return 0
    else
        rm -f "$temp_file"
        log_error "タスクの追加に失敗しました"
        return 1
    fi
}

# タスクのステータスを更新
update_task_status() {
    local task_id="$1"
    local new_status="$2"
    
    if [[ ! -f "$TASKS_YAML_FILE" ]]; then
        log_error "タスクファイルが見つかりません"
        return 1
    }
    
    # タスクの存在確認
    if ! yq eval ".tasks[] | select(.id == \"$task_id\")" "$TASKS_YAML_FILE" > /dev/null; then
        log_error "指定されたタスクが見つかりません: $task_id"
        return 1
    }
    
    # ステータスの更新
    local temp_file="${TASKS_YAML_FILE}.tmp"
    yq eval ".tasks[] |= select(.id == \"$task_id\").status = \"$new_status\"" "$TASKS_YAML_FILE" > "$temp_file"
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$TASKS_YAML_FILE"
        return 0
    else
        rm -f "$temp_file"
        log_error "ステータスの更新に失敗しました"
        return 1
    fi
}

# IDでタスクを取得
get_task_by_id() {
    local task_id="$1"
    
    if [[ ! -f "$TASKS_YAML_FILE" ]]; then
        log_error "タスクファイルが見つかりません"
        return 1
    }
    
    yq eval ".tasks[] | select(.id == \"$task_id\")" "$TASKS_YAML_FILE"
    return $?
}

# 親IDに基づいて子タスクを取得
get_child_tasks() {
    local parent_id="$1"
    
    if [[ ! -f "$TASKS_YAML_FILE" ]]; then
        log_error "タスクファイルが見つかりません"
        return 1
    }
    
    yq eval ".tasks[] | select(.parent == \"$parent_id\")" "$TASKS_YAML_FILE"
    return $?
}

# 新しいタスクを追加
add_task() {
    local name="$1"
    local status="$2"
    local content="$3"
    local design="$4"
    local concerns="$5"
    local parent="$6"
    
    # 現在のタスクデータを読み込む
    local tasks_json=$(load_tasks)
    
    # 新しいタスクIDを生成
    local new_id=$(generate_task_id "$tasks_json")
    
    # 新しいタスクのJSONを作成
    local new_task=$(cat << EOF
{
  "id": "$new_id",
  "name": "$name",
  "status": "$status",
  "parent": $([[ -z "$parent" ]] && echo "null" || echo "\"$parent\""),
  "details": {
    "content": "$content",
    "design": "$design",
    "concerns": "$concerns",
    "results": "",
    "result_concerns": ""
  }
}
EOF
)
    
    # タスクを追加
    local updated_tasks_json=$(echo "$tasks_json" | jq '. += ['"$new_task"']')
    
    # 更新したデータを保存
    save_tasks "$updated_tasks_json"
    
    echo "$new_id"
}

# タスクの削除
delete_task() {
    local task_id="$1"
    
    # 現在のタスクデータを読み込む
    local tasks_json=$(load_tasks)
    
    # タスクを削除
    local updated_tasks_json=$(echo "$tasks_json" | jq 'map(select(.id != "'"$task_id"'"))')
    
    # 更新したデータを保存
    save_tasks "$updated_tasks_json"
    
    echo "タスク $task_id を削除しました"
}

# タスクの並び替え
sort_tasks() {
    local sort_by="$1"
    local sort_order="$2"
    
    # 現在のタスクデータを読み込む
    local tasks_json=$(load_tasks)
    
    # 並び替え
    local sorted_tasks_json=""
    case "$sort_by" in
        "id")
            sorted_tasks_json=$(echo "$tasks_json" | jq 'sort_by(.id)')
            ;;
        "name")
            sorted_tasks_json=$(echo "$tasks_json" | jq 'sort_by(.name)')
            ;;
        "status")
            sorted_tasks_json=$(echo "$tasks_json" | jq 'sort_by(.status)')
            ;;
        *)
            echo "エラー: 不明な並び替え条件: $sort_by"
            return 1
            ;;
    esac
    
    # 降順の場合は反転
    if [ "$sort_order" = "desc" ]; then
        sorted_tasks_json=$(echo "$sorted_tasks_json" | jq 'reverse')
    fi
    
    # 更新したデータを保存
    save_tasks "$sorted_tasks_json"
    
    echo "タスクを $sort_by 順に並び替えました"
}

# 複数タスクの一括追加
add_multiple_tasks() {
    local names="$1"
    local statuses="$2"
    local contents="$3"
    local designs="$4"
    local concerns="$5"
    local parent="$6"
    
    # コンマで分割
    IFS=',' read -ra name_array <<< "$names"
    IFS=',' read -ra status_array <<< "$statuses"
    IFS=',' read -ra content_array <<< "$contents"
    IFS=',' read -ra design_array <<< "$designs"
    IFS=',' read -ra concern_array <<< "$concerns"
    
    # 各タスクを処理
    local added_ids=""
    for i in "${!name_array[@]}"; do
        local name="${name_array[$i]}"
        local status="${status_array[$i]:-未着手}"
        local content="${content_array[$i]:-}"
        local design="${design_array[$i]:-}"
        local concern="${concern_array[$i]:-}"
        
        # タスクを追加
        local new_id=$(add_task "$name" "$status" "$content" "$design" "$concern" "$parent")
        
        # 追加したIDを記録
        added_ids="$added_ids $new_id"
    done
    
    echo "追加したタスクID:$added_ids"
}
