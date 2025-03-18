#!/bin/bash

# スクリプトのディレクトリを取得（macOS対応）
get_script_dir() {
    SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]; do
        DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    done
    echo "$( cd -P "$( dirname "$SOURCE" )" && pwd )"
}

SCRIPT_DIR="$(get_script_dir)"
TASK_DIR="$(pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

VERSION="0.1.0"

# コマンドの使い方を表示
show_help() {
    cat << HELP
Task Management System v${VERSION}

使い方:
    task <command> [options]

コマンド:
    start       タスク管理を開始（初期化）
    add         タスクを追加
    list        タスク一覧を表示
    edit        タスクを編集
    delete      タスクを削除
    help        このヘルプを表示

オプション:
    -h, --help     ヘルプを表示
    -v, --version  バージョンを表示
HELP
}

# バージョン情報を表示
show_version() {
    echo "Task Management System v${VERSION}"
}

# タスク管理の初期化
init_tasks() {
    if [ ! -d "tasks" ]; then
        mkdir -p tasks/backups
        mkdir -p tasks/templates
        echo "tasks:" > tasks/tasks.yaml
        echo "タスク管理システムを初期化しました"
    else
        echo "タスク管理システムは既に初期化されています"
    fi
}

# コマンドの実行
execute_command() {
    local command="$1"
    shift
    
    case "$command" in
        "start")
            init_tasks
            ;;
        "add")
            if [ -f "${LIB_DIR}/commands/task_add.sh" ]; then
                source "${LIB_DIR}/commands/task_add.sh"
                main "$@"
            else
                echo "エラー: コマンドの実装が見つかりません"
                exit 1
            fi
            ;;
        "list")
            if [ -f "${LIB_DIR}/commands/task_list.sh" ]; then
                source "${LIB_DIR}/commands/task_list.sh"
                main "$@"
            else
                echo "エラー: コマンドの実装が見つかりません"
                exit 1
            fi
            ;;
        "edit")
            if [ -f "${LIB_DIR}/commands/task_edit.sh" ]; then
                source "${LIB_DIR}/commands/task_edit.sh"
                main "$@"
            else
                echo "エラー: コマンドの実装が見つかりません"
                exit 1
            fi
            ;;
        "delete")
            if [ -f "${LIB_DIR}/commands/task_delete.sh" ]; then
                source "${LIB_DIR}/commands/task_delete.sh"
                main "$@"
            else
                echo "エラー: コマンドの実装が見つかりません"
                exit 1
            fi
            ;;
        *)
            echo "エラー: 不明なコマンド '$command'"
            echo "ヘルプを表示するには: task --help"
            exit 1
            ;;
    esac
}

# メイン処理
case "$1" in
    start|add|list|edit|delete)
        execute_command "$@"
        ;;
    -h|--help)
        show_help
        ;;
    -v|--version)
        show_version
        ;;
    *)
        if [ -z "$1" ]; then
            show_help
        else
            echo "エラー: 不明なコマンド '$1'"
            echo "ヘルプを表示するには: task --help"
            exit 1
        fi
        ;;
esac 