#!/bin/bash

# 共通ユーティリティ関数

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログレベルの定義
LOG_LEVEL_ERROR=0
LOG_LEVEL_WARN=1
LOG_LEVEL_INFO=2
LOG_LEVEL_DEBUG=3

# デバッグモードのフラグ（デフォルトはオフ）
DEBUG_MODE=0

# 現在のログレベルのデフォルト設定
# デバッグモードがオフの場合はINFO、オンの場合はDEBUG
if [ "$DEBUG_MODE" -eq 1 ]; then
    CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
else
    CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO
fi

# 環境変数でデバッグモードが指定されていれば優先する
if [ "${TASK_DEBUG:-0}" -eq 1 ]; then
    DEBUG_MODE=1
    CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
fi

# デバッグモードをオンにする
enable_debug_mode() {
    DEBUG_MODE=1
    CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
    export TASK_DEBUG=1
    log_debug "デバッグモードが有効になりました"
}

# デバッグモードをオフにする
disable_debug_mode() {
    DEBUG_MODE=0
    CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO
    export TASK_DEBUG=0
    echo "デバッグモードが無効になりました"
}

# デバッグモードの状態を切り替える
toggle_debug_mode() {
    if [ "$DEBUG_MODE" -eq 1 ]; then
        disable_debug_mode
    else
        enable_debug_mode
    fi
}

# デバッグログは条件付きで出力する
conditional_log_debug() {
    if [ "$DEBUG_MODE" -eq 1 ]; then
        log_debug "$@"
    fi
}

# タスク管理システムのルートディレクトリを設定
if [ -z "$TASK_DIR" ]; then
    # task.shスクリプトですでに設定されている場合は使用
    TASK_DIR="$(pwd)"
    export TASK_DIR
fi

# 作業ディレクトリ（カレントディレクトリ）
if [ -z "$CURRENT_TASKS_DIR" ]; then
    CURRENT_TASKS_DIR="$(pwd)"
    export CURRENT_TASKS_DIR
fi

# ログ出力関数
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [ $level -ge $CURRENT_LOG_LEVEL ]; then
        case $level in
            $LOG_LEVEL_DEBUG)
                echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - ${message}"
                ;;
            $LOG_LEVEL_INFO)
                echo -e "${GREEN}[INFO]${NC} ${timestamp} - ${message}"
                ;;
            $LOG_LEVEL_WARN)
                echo -e "${YELLOW}[WARN]${NC} ${timestamp} - ${message}"
                ;;
            $LOG_LEVEL_ERROR)
                echo -e "${RED}[ERROR]${NC} ${timestamp} - ${message}"
                ;;
        esac
    fi
}

# エラーメッセージを表示
log_error() {
    local message="$1"
    if [[ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_ERROR ]]; then
        echo -e "${RED}エラー:${NC} $message" >&2
    fi
}

# 警告メッセージを表示
log_warn() {
    local message="$1"
    if [[ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_WARN ]]; then
        echo -e "${YELLOW}警告:${NC} $message" >&2
    fi
}

# 情報メッセージを表示
log_info() {
    local message="$1"
    if [[ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_INFO ]]; then
        echo -e "${GREEN}情報:${NC} $message"
    fi
}

# デバッグメッセージを表示
log_debug() {
    local message="$1"
    if [[ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_DEBUG ]]; then
        echo -e "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $message" >&2
    fi
}

# エラーハンドリング
handle_error() {
    local message="$1"
    local exit_code="${2:-1}"
    log_error "$message"
    exit "$exit_code"
}

# 依存関係チェック
check_dependency() {
    local command=$1
    if ! command -v "$command" &> /dev/null; then
        handle_error "Required command '$command' is not installed."
    fi
}

# ディレクトリ作成（存在確認付き）
create_directory() {
    local dir_path=$1
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path" || handle_error "Failed to create directory: $dir_path"
        log $LOG_LEVEL_INFO "Created directory: $dir_path"
    else
        log $LOG_LEVEL_DEBUG "Directory already exists: $dir_path"
    fi
}

# ファイルのバックアップ作成
backup_file() {
    local file_path=$1
    local backup_path="${file_path}.bak"
    if [ -f "$file_path" ]; then
        cp "$file_path" "$backup_path" || handle_error "Failed to create backup: $file_path"
        log $LOG_LEVEL_INFO "Created backup: $backup_path"
    fi
}

# YAMLファイルの存在確認
check_yaml_file() {
    local file_path=$1
    if [ ! -f "$file_path" ]; then
        handle_error "YAML file not found: $file_path"
    fi
}

# 設定ファイルのロード
load_config() {
    local config_file=$1
    check_yaml_file "$config_file"
    # yqコマンドの存在確認
    check_dependency "yq"
    # 設定ファイルの読み込み（実装予定）
    log $LOG_LEVEL_DEBUG "Loading config file: $config_file"
}

# パスの正規化
normalize_path() {
    local path=$1
    echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
}

# 文字列がJSON/YAML配列形式かチェック
is_array_string() {
    local str=$1
    [[ $str == \[*\] ]]
}

# コンマ区切り文字列を配列に変換
split_string() {
    local IFS=','
    read -ra ADDR <<< "$1"
    echo "${ADDR[@]}"
}

# 配列の要素数を取得
get_array_length() {
    local array=("$@")
    echo "${#array[@]}"
}

# 配列の要素を検証
validate_array_length() {
    local array1=("$1")
    local array2=("$2")
    local name1=$3
    local name2=$4
    
    if [ "${#array1[@]}" != "${#array2[@]}" ]; then
        handle_error "Number of ${name1} (${#array1[@]}) does not match number of ${name2} (${#array2[@]})"
    fi
}

# スクリプトの実行に必要な環境変数の設定
setup_environment() {
    # 環境変数を初期設定
    _set_environment_paths
    
    log $LOG_LEVEL_DEBUG "Environment setup completed"
    log $LOG_LEVEL_DEBUG "TASK_DIR: ${TASK_DIR}"
    log $LOG_LEVEL_DEBUG "CURRENT_TASKS_DIR: ${CURRENT_TASKS_DIR}"
    log $LOG_LEVEL_DEBUG "TASKS_DIR: ${TASKS_DIR}"
}

# 環境変数パスの設定（内部関数）
_set_environment_paths() {
    # カレントディレクトリにtasksフォルダが存在する場合はそれを優先
    if [ -d "${CURRENT_TASKS_DIR}/tasks" ]; then
        export TASKS_DIR="${CURRENT_TASKS_DIR}/tasks"
    else
        export TASKS_DIR="${TASK_DIR}/tasks"
    fi
    
    export TEMPLATES_DIR="${TASKS_DIR}/templates"
    export CONFIG_DIR="${TASKS_DIR}/config"
    export LIB_DIR="${TASK_DIR}/lib"
}

# 環境変数を再評価する関数（コマンド実行前に呼び出す）
refresh_environment() {
    # カレントディレクトリを更新
    CURRENT_TASKS_DIR="$(pwd)"
    export CURRENT_TASKS_DIR
    
    # 環境変数パスを再設定
    _set_environment_paths
    
    log $LOG_LEVEL_DEBUG "Environment refreshed"
    log $LOG_LEVEL_DEBUG "CURRENT_TASKS_DIR: ${CURRENT_TASKS_DIR}"
    log $LOG_LEVEL_DEBUG "TASKS_DIR: ${TASKS_DIR}"
}

# 指定されたディレクトリに対して環境変数を設定する関数
set_environment_for_dir() {
    local target_dir="$1"
    
    # 指定ディレクトリを一時的に作業ディレクトリとして設定
    local old_dir="$CURRENT_TASKS_DIR"
    CURRENT_TASKS_DIR="$target_dir"
    export CURRENT_TASKS_DIR
    
    # 環境変数を更新
    _set_environment_paths
    
    log $LOG_LEVEL_DEBUG "Environment set for directory: $target_dir"
    log $LOG_LEVEL_DEBUG "TASKS_DIR: ${TASKS_DIR}"
    
    # 元の作業ディレクトリを復元
    CURRENT_TASKS_DIR="$old_dir"
    export CURRENT_TASKS_DIR
}

# 初期化時に環境をセットアップ
setup_environment 

# ファイルの存在確認
ensure_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        handle_error "ファイルが見つかりません: $file"
    fi
}

# ディレクトリの存在確認
ensure_directory_exists() {
    local directory="$1"
    if [[ ! -d "$directory" ]]; then
        handle_error "ディレクトリが見つかりません: $directory"
    fi
}

# コマンドの存在確認
ensure_command_exists() {
    local command="$1"
    if ! command -v "$command" &> /dev/null; then
        handle_error "必要なコマンドが見つかりません: $command"
    fi
}

# バックアップの作成
create_backup() {
    local source="$1"
    local backup="${source}.bak"
    if ! cp "$source" "$backup"; then
        handle_error "バックアップの作成に失敗しました: $source"
    fi
    log_info "バックアップを作成しました: $backup"
}

# タイムスタンプの生成
generate_timestamp() {
    date "+%Y%m%d_%H%M%S"
}

# 一時ファイルの作成
create_temp_file() {
    local prefix="${1:-temp}"
    local temp_file
    temp_file=$(mktemp "/tmp/${prefix}.XXXXXX")
    echo "$temp_file"
}

# 一時ディレクトリの作成
create_temp_directory() {
    local prefix="${1:-temp}"
    local temp_dir
    temp_dir=$(mktemp -d "/tmp/${prefix}.XXXXXX")
    echo "$temp_dir"
}

# クリーンアップ処理
cleanup() {
    local target="$1"
    if [[ -e "$target" ]]; then
        rm -rf "$target"
    fi
}

# 文字列のトリム
trim_string() {
    local string="$1"
    echo "$string" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# 配列の結合
join_array() {
    local delimiter="$1"
    shift
    local array=("$@")
    local result=""
    
    for ((i=0; i<${#array[@]}; i++)); do
        if [[ $i -gt 0 ]]; then
            result+="$delimiter"
        fi
        result+="${array[i]}"
    done
    
    echo "$result"
}

# YAMLファイルの検証
validate_yaml() {
    local file="$1"
    if ! yq eval '.' "$file" &> /dev/null; then
        handle_error "無効なYAMLファイルです: $file"
    fi
}

# 設定の読み込み
load_config() {
    local config_file="$1"
    ensure_file_exists "$config_file"
    validate_yaml "$config_file"
    yq eval '.' "$config_file"
}

# 設定の更新
update_config() {
    local config_file="$1"
    local key="$2"
    local value="$3"
    
    ensure_file_exists "$config_file"
    if ! yq eval ".$key = \"$value\"" -i "$config_file"; then
        handle_error "設定の更新に失敗しました: $key"
    fi
}

# ロック機能
LOCK_FILE="/tmp/task_manager.lock"

acquire_lock() {
    if ! mkdir "$LOCK_FILE" 2>/dev/null; then
        handle_error "別のプロセスが実行中です"
    fi
    trap 'rm -rf "$LOCK_FILE"' EXIT
}

release_lock() {
    rm -rf "$LOCK_FILE"
} 