#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 共通ユーティリティをインポート
source "${SCRIPT_DIR}/utils/common.sh"
source "${SCRIPT_DIR}/utils/validators.sh"
source "${SCRIPT_DIR}/core/yaml_processor.sh"

# ヘルプメッセージの表示
show_add_help() {
    cat << EOF
使用法: task add [オプション]

タスクを追加します。

オプション:
  -n, --name <名前>        タスク名（必須）
  -d, --description <説明> タスクの説明
  -c, --concerns <懸念事項> タスクの懸念事項
  -p, --parent <タスクID>   親タスクのID
  --prefix <プレフィックス> タスクIDのプレフィックス（デフォルト: TA）
  --start-num <開始番号>   タスクID番号の開始値（デフォルト: 自動）
  -h, --help               このヘルプを表示

例:
  task add -n "新機能の実装"
  task add -n "UI改善" -d "ボタンのデザインを修正" -c "ブランドガイドラインの遵守"
  task add -n "サブタスク" -p TA01
  task add -n "プロジェクトA用タスク" --prefix "PA"
EOF
}

# プロジェクト設定ファイルからデフォルト設定を読み込む
load_project_config() {
    local config_file="${TASK_DIR}/tasks/config/project_config.yaml"
    
    # 設定ファイルが存在しない場合はデフォルト値を作成
    if [[ ! -f "$config_file" ]]; then
        mkdir -p "$(dirname "$config_file")"
        cat > "$config_file" << EOF
# タスク管理の設定
prefix: "TA"  # タスクIDのプレフィックス
auto_numbering: true  # 自動採番を行うかどうか
start_number: 1  # 自動採番の開始番号
EOF
        log_debug "デフォルトのプロジェクト設定ファイルを作成しました: $config_file"
    fi
    
    # 設定値を読み込む
    if command -v yq &>/dev/null; then
        PREFIX=$(yq eval '.prefix // "TA"' "$config_file")
        AUTO_NUMBERING=$(yq eval '.auto_numbering // true' "$config_file")
        START_NUMBER=$(yq eval '.start_number // 1' "$config_file")
    else
        # yqが使えない場合はデフォルト値を使用
        PREFIX="TA"
        AUTO_NUMBERING=true
        START_NUMBER=1
    fi
}

# 指定されたプレフィックスでタスクIDを生成
generate_task_id() {
    local prefix="$1"
    local tasks_file="${TASK_DIR}/tasks/tasks.yaml"
    local next_number=1
    
    if [[ ! -f "$tasks_file" ]]; then
        echo "tasks: []" > "$tasks_file"
    fi
    
    # 既存のタスクIDから最大の番号を見つける
    if [[ -s "$tasks_file" ]]; then
        # 指定のプレフィックスに一致するIDのみを抽出
        local max_id
        max_id=$(grep -o "${prefix}[0-9]\+" "$tasks_file" | sed "s/${prefix}//" | sort -n | tail -1)
        
        if [[ -n "$max_id" ]]; then
            next_number=$((max_id + 1))
        fi
    fi
    
    # 指定された開始番号がある場合は比較して大きい方を使用
    if [[ -n "$START_NUMBER" && "$START_NUMBER" -gt "$next_number" ]]; then
        next_number=$START_NUMBER
    fi
    
    # 2桁でゼロパディング
    printf "%s%02d" "$prefix" "$next_number"
}

# メイン処理
main() {
    # カレントディレクトリにtasksフォルダが存在するか確認
    if [[ ! -d "${CURRENT_TASKS_DIR}/tasks" ]]; then
        log_error "タスク管理システムが初期化されていません。'task start'を実行してください。"
        exit 1
    fi
    
    # 引数がない場合はヘルプを表示
    if [[ $# -eq 0 ]]; then
        show_add_help
        return 0
    fi
    
    # プロジェクト設定を読み込む
    load_project_config
    
    local task_name=""
    local description=""
    local concerns=""
    local parent_id=""
    local custom_prefix="$PREFIX"
    local custom_start_num="$START_NUMBER"
    
    # 引数の解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                task_name="$2"
                shift 2
                ;;
            -d|--description)
                description="$2"
                shift 2
                ;;
            -c|--concerns)
                concerns="$2"
                shift 2
                ;;
            -p|--parent)
                parent_id="$2"
                shift 2
                ;;
            --prefix)
                custom_prefix="$2"
                shift 2
                ;;
            --start-num)
                custom_start_num="$2"
                shift 2
                ;;
            -h|--help)
                show_add_help
                return 0
                ;;
            *)
                log_error "不明なオプション: $1"
                show_add_help
                return 1
                ;;
        esac
    done
    
    # タスク名は必須
    if [[ -z "$task_name" ]]; then
        log_error "タスク名は必須です"
        show_add_help
        return 1
    fi
    
    # 親タスクの存在確認（指定された場合）
    if [[ -n "$parent_id" ]] && ! task_exists "$parent_id"; then
        log_error "親タスクが見つかりません: $parent_id"
        return 1
    fi
    
    # カンマで区切られた複数のタスク名を処理
    IFS=',' read -ra NAMES <<< "$task_name"
    local added_tasks=()
    
    for name in "${NAMES[@]}"; do
        # 先頭と末尾の空白を削除
        name=$(echo "$name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        if [[ -z "$name" ]]; then
            continue
        fi
        
        # タスクIDの生成
        START_NUMBER=$custom_start_num
        local task_id
        task_id=$(generate_task_id "$custom_prefix")
        
        # タスクの追加
        if add_task "$task_id" "$name" "$description" "$concerns" "$parent_id"; then
            log_info "タスクを追加しました: $task_id - $name"
            added_tasks+=("$task_id")
            
            # 起動番号を次に増加
            ((custom_start_num++))
        else
            log_error "タスクの追加に失敗しました: $name"
        fi
    done
    
    # 追加されたタスクが少なくとも1つ以上ある場合
    if [[ ${#added_tasks[@]} -gt 0 ]]; then
        # テンプレートの更新
        if command -v "${SCRIPT_DIR}/core/template_engine.sh" &>/dev/null; then
            source "${SCRIPT_DIR}/core/template_engine.sh"
            if ! generate_task_file_from_template; then
                log_error "タスクファイルの生成に失敗しました"
            fi
        fi
        
        # 追加されたタスクIDを返す
        echo "${added_tasks[@]}"
        return 0
    fi
    
    return 1
}

# スクリプトとして実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 

# タスクを追加
add_task() {
    local task_id="$1"
    local name="$2"
    local description="$3"
    local concerns="$4"
    local parent_id="$5"
    
    # タスクデータファイルのパス
    local tasks_file="${TASKS_DIR}/tasks.yaml"
    
    log_debug "タスクファイル: ${tasks_file}"
    
    # タスクファイルが存在しない場合は作成
    if [[ ! -f "$tasks_file" ]]; then
        echo "tasks: []" > "$tasks_file"
    fi
    
    # 新しいタスクのYAMLフォーマット
    local task_yaml=""
    task_yaml+="  - id: \"$task_id\"\n"
    task_yaml+="    name: \"$name\"\n"
    task_yaml+="    status: \"not_started\"\n"
    
    if [[ -n "$description" ]]; then
        task_yaml+="    description: \"$description\"\n"
    fi
    
    if [[ -n "$concerns" ]]; then
        task_yaml+="    concerns: \"$concerns\"\n"
    fi
    
    if [[ -n "$parent_id" ]]; then
        task_yaml+="    parent: \"$parent_id\"\n"
    fi
    
    # タスクをYAMLファイルに追加
    if [[ -s "$tasks_file" ]]; then
        # タスクが既に存在するかチェック
        if yq eval '.tasks[] | select(.id == "'"$task_id"'")' "$tasks_file" | grep -q .; then
            log_error "タスクIDが既に存在します: $task_id"
            return 1
        fi
        
        # タスクを追加
        local temp_file="$(mktemp)"
        yq eval '.tasks += [{}]' "$tasks_file" > "$temp_file"
        
        # 最後のタスクに値を設定
        local index
        index=$(yq eval '.tasks | length - 1' "$temp_file")
        
        yq eval ".tasks[$index].id = \"$task_id\"" -i "$temp_file"
        yq eval ".tasks[$index].name = \"$name\"" -i "$temp_file"
        yq eval ".tasks[$index].status = \"not_started\"" -i "$temp_file"
        
        if [[ -n "$description" ]]; then
            yq eval ".tasks[$index].description = \"$description\"" -i "$temp_file"
        fi
        
        if [[ -n "$concerns" ]]; then
            yq eval ".tasks[$index].concerns = \"$concerns\"" -i "$temp_file"
        fi
        
        if [[ -n "$parent_id" ]]; then
            yq eval ".tasks[$index].parent = \"$parent_id\"" -i "$temp_file"
        fi
        
        # 元のファイルを更新
        mv "$temp_file" "$tasks_file"
    else
        # 新規ファイルの場合
        echo -e "tasks:\n$task_yaml" > "$tasks_file"
    fi
    
    # Gitリポジトリが存在する場合はコミット
    if [[ -d "${CURRENT_TASKS_DIR}/.git" ]]; then
        (cd "${CURRENT_TASKS_DIR}" && git add "$tasks_file" && git commit -m "🆕 タスクを追加: $task_id - $name")
    fi
    
    return 0
} 