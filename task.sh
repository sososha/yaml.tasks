#!/bin/bash

# タスク管理システムのメインスクリプト

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
TASK_DIR="$(pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# 共通ユーティリティの読み込み
source "${LIB_DIR}/utils/common.sh"
source "${LIB_DIR}/utils/validators.sh"

# バージョン情報
VERSION="0.1.0"

# ヘルプメッセージの表示
show_help() {
    cat << EOF
Task Management System v${VERSION}

Usage:
    task <command> [options] [arguments]

Commands:
    start       Initialize the task management system
    init        Re-initialize the system (preserves existing data)
    add         Add new task(s)
    delete      Delete task(s)
    subtask     Add subtask(s) to an existing task
    status      Change task status
    list        List all tasks
    template    Manage task templates
    sync        Synchronize task data and display
    sort        Sort tasks
    validate    Validate task data integrity
    edit        Edit an existing task
    help        Show this help message

Options:
    -h, --help     Show this help message
    -v, --version  Show version information

For more information about a command:
    task help <command>
EOF
}

# バージョン情報の表示
show_version() {
    echo "Task Management System v${VERSION}"
}

# コマンドの実行
execute_command() {
    local command="$1"
    shift
    
    case "$command" in
        "start")
            source "${LIB_DIR}/commands/task_start.sh"
            main "$@"
            ;;
        "init")
            source "${LIB_DIR}/commands/task_init.sh"
            main "$@"
            ;;
        "add")
            source "${LIB_DIR}/commands/task_add.sh"
            main "$@"
            ;;
        "delete")
            source "${LIB_DIR}/commands/task_delete.sh"
            main "$@"
            ;;
        "subtask")
            source "${LIB_DIR}/commands/task_subtask.sh"
            main "$@"
            ;;
        "status")
            source "${LIB_DIR}/commands/task_status.sh"
            main "$@"
            ;;
        "list")
            source "${LIB_DIR}/commands/task_list.sh"
            main "$@"
            ;;
        "template")
            source "${LIB_DIR}/commands/task_template.sh"
            main "$@"
            ;;
        "sync")
            source "${LIB_DIR}/commands/task_sync.sh"
            main "$@"
            ;;
        "sort")
            source "${LIB_DIR}/commands/task_sort.sh"
            main "$@"
            ;;
        "validate")
            source "${LIB_DIR}/commands/task_validate.sh"
            main "$@"
            ;;
        "edit")
            source "${LIB_DIR}/commands/task_edit.sh"
            main "$@"
            ;;
        "help")
            if [[ $# -eq 0 ]]; then
                show_help
            else
                source "${LIB_DIR}/commands/task_help.sh"
                main "$@"
            fi
            ;;
        *)
            echo "Error: Unknown command '$command'"
            echo "Run 'task help' for usage information"
            exit 1
            ;;
    esac
}

# メイン処理
main() {
    # 引数がない場合はヘルプを表示
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    # オプションの処理
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        *)
            execute_command "$@"
            ;;
    esac
}

# スクリプトの実行
main "$@" 