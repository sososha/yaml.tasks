#!/bin/bash

# 共通ユーティリティ関数

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログレベル
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# デフォルトのログレベル
CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO

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

# エラーハンドリング関数
handle_error() {
    local error_message=$1
    local exit_code=${2:-1}
    log $LOG_LEVEL_ERROR "$error_message"
    exit $exit_code
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
    # タスク管理システムのルートディレクトリ（未設定の場合のみ設定）
    if [[ -z "$TASK_DIR" ]]; then
        export TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    fi
    
    # 各種ディレクトリパスの設定
    export TASKS_DIR="${TASK_DIR}/tasks"
    export TEMPLATES_DIR="${TASKS_DIR}/templates"
    export CONFIG_DIR="${TASKS_DIR}/config"
    export LIB_DIR="${TASK_DIR}/lib"
    
    log $LOG_LEVEL_DEBUG "Environment setup completed"
    log $LOG_LEVEL_DEBUG "TASK_DIR: ${TASK_DIR}"
}

# 初期化時に環境をセットアップ
setup_environment 