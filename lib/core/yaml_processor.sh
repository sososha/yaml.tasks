#!/bin/bash
# YAMLデータ操作モジュール

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

# YAMLからタスクデータを読み込む
load_tasks() {
    initialize_yaml
    
    # yqを使用してタスクデータを取得
    local tasks_json=$(yq eval -o=json '.tasks' "$TASKS_YAML_FILE")
    echo "$tasks_json"
}

# タスクデータをYAMLに保存
save_tasks() {
    local tasks_json="$1"
    
    # 一時ファイルを作成
    local temp_file=$(mktemp)
    
    # 新しいタスクデータでYAMLを更新
    echo '{"tasks": '"$tasks_json"'}' | yq eval -P '.' - > "$temp_file"
    
    # 元のファイルを置き換え
    mv "$temp_file" "$TASKS_YAML_FILE"
    
    echo "タスクデータを保存しました"
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

# タスクのステータスを更新
update_task_status() {
    local task_id="$1"
    local new_status="$2"
    
    # 現在のタスクデータを読み込む
    local tasks_json=$(load_tasks)
    
    # タスクのステータスを更新
    local updated_tasks_json=$(echo "$tasks_json" | jq 'map(if .id == "'"$task_id"'" then .status = "'"$new_status"'" else . end)')
    
    # 更新したデータを保存
    save_tasks "$updated_tasks_json"
    
    echo "タスク $task_id のステータスを $new_status に更新しました"
}

# IDでタスクを取得
get_task_by_id() {
    local task_id="$1"
    local tasks_json=$(load_tasks)
    
    # タスクを検索
    local task=$(echo "$tasks_json" | jq '.[] | select(.id == "'"$task_id"'")')
    
    echo "$task"
}

# 親IDに基づいて子タスクを取得
get_child_tasks() {
    local parent_id="$1"
    local tasks_json=$(load_tasks)
    
    # 子タスクを検索
    local child_tasks=$(echo "$tasks_json" | jq '[.[] | select(.parent == "'"$parent_id"'")]')
    
    echo "$child_tasks"
}

# 新しいタスクIDを生成
generate_task_id() {
    local tasks_json="$1"
    
    # 既存のIDを取得
    local ids=$(echo "$tasks_json" | jq -r '.[].id')
    
    # IDの最大値を取得
    local max_id=0
    local prefix=""
    
    if [ -z "$ids" ]; then
        # タスクが存在しない場合は最初のIDを返す
        echo "PA01"
        return
    fi
    
    # 既存のIDから最大値を見つける
    while read -r id; do
        if [[ -z "$id" ]]; then
            continue
        fi
        
        # IDのプレフィックスと数値部分を分離
        local id_prefix="${id:0:2}"
        local id_number="${id:2}"
        
        # 数値部分を10進数として扱う
        id_number=$((10#$id_number))
        
        # プレフィックスが同じ場合は数値を比較
        if [[ "$id_prefix" == "$prefix" && $id_number -gt $max_id ]]; then
            max_id=$id_number
        elif [[ -z "$prefix" ]]; then
            # 初回の場合はプレフィックスを設定
            prefix="$id_prefix"
            max_id=$id_number
        fi
    done <<< "$ids"
    
    # 次のIDを生成
    local next_id=$((max_id + 1))
    printf "%s%02d" "$prefix" "$next_id"
}

# タスクの存在確認
task_exists() {
    local task_id="$1"
    local task=$(get_task_by_id "$task_id")
    
    if [ -z "$task" ]; then
        return 1
    else
        return 0
    fi
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
