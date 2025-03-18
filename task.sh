#!/bin/bash

# タスク管理システムのメインスクリプト

# スクリプトが存在するディレクトリの絶対パスを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 共通の設定と関数をインポート
source "${SCRIPT_DIR}/lib/utils/common.sh"
source "${SCRIPT_DIR}/lib/utils/validators.sh"

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
    subtask     Add subtask(s) to an existing task
    status      Change task status
    list        List all tasks
    template    Manage task templates
    sync        Synchronize task data and display
    sort        Sort tasks
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
    local command=$1
    shift # コマンドを削除して残りの引数を保持

    case $command in
        start)
            source "${SCRIPT_DIR}/lib/commands/task_init.sh"
            task_start "$@"
            ;;
        init)
            source "${SCRIPT_DIR}/lib/commands/task_init.sh"
            task_init "$@"
            ;;
        add)
            source "${SCRIPT_DIR}/lib/commands/task_add.sh"
            task_add "$@"
            ;;
        subtask)
            source "${SCRIPT_DIR}/lib/commands/task_subtask.sh"
            task_subtask "$@"
            ;;
        status)
            source "${SCRIPT_DIR}/lib/commands/task_status.sh"
            task_status "$@"
            ;;
        list)
            source "${SCRIPT_DIR}/lib/commands/task_list.sh"
            task_list "$@"
            ;;
        template)
            source "${SCRIPT_DIR}/lib/commands/task_template.sh"
            task_template "$@"
            ;;
        sync)
            source "${SCRIPT_DIR}/lib/commands/task_sync.sh"
            task_sync "$@"
            ;;
        sort)
            source "${SCRIPT_DIR}/lib/commands/task_sort.sh"
            task_sort "$@"
            ;;
        help)
            if [ $# -eq 0 ]; then
                show_help
            else
                # 各コマンドのヘルプを表示（未実装）
                echo "Detailed help for $1 command is not implemented yet."
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