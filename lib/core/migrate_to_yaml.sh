#!/bin/bash
# migrate_to_yaml.sh - 既存のタスクデータをYAML形式に変換するスクリプト

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 依存するモジュールを読み込む
source "${SCRIPT_DIR}/../core/file_utils.sh"

# 定数
TASK_FILE="${TASK_DIR}/tasks/project.tasks"
YAML_FILE="${TASK_DIR}/tasks/tasks.yaml"

# エラーメッセージを表示して終了する関数
error_exit() {
    echo "エラー: $1" >&2
    exit 1
}

# タスクファイルが存在するか確認
if [ ! -f "$TASK_FILE" ]; then
    error_exit "タスクファイルが見つかりません: $TASK_FILE"
fi

# 出力ディレクトリを作成
mkdir -p "$(dirname "$YAML_FILE")"

# YAMLファイルの初期化
echo "tasks:" > "$YAML_FILE"

# タスクセクションとタスク詳細セクションを分離
task_section=""
detail_section=""
current_section="none"

while IFS= read -r line; do
    if [[ "$line" == "# Tasks" ]]; then
        current_section="tasks"
        continue
    elif [[ "$line" == "# Details" ]]; then
        current_section="details"
        continue
    fi
    
    if [[ "$current_section" == "tasks" && -n "$line" ]]; then
        task_section+="$line"$'\n'
    elif [[ "$current_section" == "details" && -n "$line" ]]; then
        detail_section+="$line"$'\n'
    fi
done < "$TASK_FILE"

# タスク情報の解析と変換
declare -A task_details
declare -A task_parents
declare -A task_indents

# タスク詳細の解析
while IFS= read -r line; do
    if [[ "$line" =~ ^-\ ([A-Z]{2}[0-9]{2}): ]]; then
        task_id="${BASH_REMATCH[1]}"
        current_task_id="$task_id"
        task_details["$task_id"]=""
    elif [[ -n "$current_task_id" && "$line" =~ ^[[:space:]]+([^:]+)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        task_details["$current_task_id"]+="  $key: \"$value\"\n"
    fi
done <<< "$detail_section"

# タスク階層の解析
current_indent=0
parent_stack=()
last_task_at_indent=()

while IFS= read -r line; do
    if [[ "$line" =~ ^([[:space:]]*)([□✓◎▣✅])\ ([A-Z]{2}[0-9]{2})\ (.*)$ ]]; then
        indent="${BASH_REMATCH[1]}"
        status_symbol="${BASH_REMATCH[2]}"
        task_id="${BASH_REMATCH[3]}"
        task_name="${BASH_REMATCH[4]}"
        
        # ステータスの変換
        task_status="not_started"
        if [[ "$status_symbol" == "✓" || "$status_symbol" == "✅" ]]; then
            task_status="completed"
        elif [[ "$status_symbol" == "◎" || "$status_symbol" == "▣" ]]; then
            task_status="in_progress"
        fi
        
        # インデントレベルの計算
        indent_level=$((${#indent} / 2))
        task_indents["$task_id"]=$indent_level
        
        # 親タスクの特定
        if [[ $indent_level -eq 0 ]]; then
            task_parents["$task_id"]="null"
            parent_stack=()
            last_task_at_indent=()
            last_task_at_indent[0]="$task_id"
        else
            parent_level=$((indent_level - 1))
            parent_id="${last_task_at_indent[$parent_level]}"
            task_parents["$task_id"]="\"$parent_id\""
            last_task_at_indent[$indent_level]="$task_id"
        fi
        
        # タスク情報をYAMLに追加
        details="${task_details["$task_id"]}"
        if [[ -z "$details" ]]; then
            details="  content: \"\"\n  design: \"\"\n  concerns: \"\"\n  results: \"\"\n  result_concerns: \"\""
        fi
        
        cat >> "$YAML_FILE" << EOF
  - id: "$task_id"
    name: "$task_name"
    status: "$task_status"
    parent: ${task_parents["$task_id"]}
    details:
$details
EOF
    fi
done <<< "$task_section"

echo "タスクデータをYAML形式に変換しました: $YAML_FILE"

# 変換結果の表示
echo "変換されたタスク数: $(grep -c "id:" "$YAML_FILE")"
