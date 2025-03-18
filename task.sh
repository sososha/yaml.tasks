#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_SCRIPT_DIR="$SCRIPT_DIR"  # オリジナルの値を保存

# タスク管理システムのルートディレクトリを設定
export TASK_DIR="$SCRIPT_DIR"

# カレントディレクトリ（作業ディレクトリ）を設定
export CURRENT_TASKS_DIR="$(pwd)"

# 共通パスの検索
find_module_path() {
    local module_name="$1"
    local search_paths=(
        "${SCRIPT_DIR}/lib/${module_name}"
        "${SCRIPT_DIR}/${module_name}"
    )
    
    echo "DEBUG: Searching for module: $module_name" >&2
    echo "DEBUG: SCRIPT_DIR: $SCRIPT_DIR" >&2
    
    for path in "${search_paths[@]}"; do
        echo "DEBUG: Checking path: $path" >&2
        if [[ -f "$path" ]]; then
            echo "DEBUG: Found module at: $path" >&2
            echo "$path"
            return 0
        fi
    done
    
    echo "DEBUG: Module not found: $module_name" >&2
    echo ""
    return 1
}

# 共通ユーティリティの読み込み
COMMON_PATH=$(find_module_path "utils/common.sh")
if [[ -n "$COMMON_PATH" ]]; then
    source "$COMMON_PATH"
else
    echo "エラー: common.sh が見つかりません"
    exit 1
fi

# サブコマンドの読み込み
COMMANDS=(
    "commands/task_init.sh"      # start, initコマンド
    "commands/task_add.sh"       # addコマンド
    "commands/task_list.sh"      # listコマンド
    "commands/task_show.sh"      # showコマンド
    "commands/task_edit.sh"      # editコマンド
    "commands/task_delete.sh"    # deleteコマンド
    "commands/task_template.sh"  # templateコマンド
    "commands/task_subtask.sh"   # subtaskコマンド
    "commands/task_status.sh"    # statusコマンド
    "commands/task_sync.sh"      # syncコマンド
    "commands/task_validate.sh"  # validateコマンド
    "commands/task_update.sh"    # updateコマンド
    "commands/task_uninstall.sh" # uninstallコマンド
)

for cmd in "${COMMANDS[@]}"; do
    # 各コマンド読み込み前にSCRIPT_DIRを元の値に戻す
    SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"
    
    CMD_PATH=$(find_module_path "$cmd")
    if [[ -n "$CMD_PATH" ]]; then
        source "$CMD_PATH"
    else
        log_debug "オプション: $cmd が見つかりません"
    fi
done

# 最後にSCRIPT_DIRを元の値に戻す
SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"

# ヘルプメッセージの表示
show_help() {
    cat << EOF
使用法: task <コマンド> [オプション]

タスク管理システム

コマンド:
  start     タスク管理システムの初期化
  init      システムの再初期化（データは保持）
  add       タスクの追加
  list      タスクの一覧表示
  show      タスクの詳細表示
  edit      タスクの編集
  delete    タスクの削除
  subtask   サブタスクの追加
  status    タスクのステータス変更
  sync      タスクデータの同期
  validate  タスクデータの検証
  template  テンプレートの管理
  update    タスク管理システムの更新
  uninstall タスク管理システムのアンインストール

オプション:
  -h, --help   ヘルプの表示

詳細なヘルプは 'task <コマンド> --help' で確認できます。
EOF
}

# バージョン情報の表示
show_version() {
    echo "タスク管理システム v1.1.0"
}

# メインの処理
main() {
    # コマンドライン引数がない場合
    if [[ $# -eq 0 ]]; then
        show_help
        return 0
    fi

    # 現在の作業ディレクトリに基づいて環境変数を再評価
    if type refresh_environment &>/dev/null; then
        refresh_environment
    else
        log_debug "refresh_environment function not found"
    fi

    # 第一引数をコマンドとして処理
    local command="$1"
    shift

    case "$command" in
        start)
            # SCRIPT_DIRを元の値に戻す
            SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"
            
            # task_init.shのtask_start関数を呼び出す
            if type task_start >/dev/null 2>&1; then
                task_start "$@"
            else
                log_error "初期化機能が見つかりません"
                return 1
            fi
            ;;
        init)
            # SCRIPT_DIRを元の値に戻す
            SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"
            
            # task_init.shのtask_init関数を呼び出す
            if type task_init >/dev/null 2>&1; then
                task_init "$@"
            else
                log_error "再初期化機能が見つかりません"
                return 1
            fi
            ;;
        add)
            # 環境変数を再評価して、確実にカレントディレクトリを利用
            refresh_environment
            
            # SCRIPT_DIRを元の値に戻す
            SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"
            
            # task_add.shのtask_add関数を呼び出す
            ADD_PATH=$(find_module_path "commands/task_add.sh")
            echo "DEBUG: ADD_PATH: $ADD_PATH" >&2
            
            if [[ -n "$ADD_PATH" ]]; then
                echo "DEBUG: Sourcing task_add.sh from: $ADD_PATH" >&2
                source "$ADD_PATH"
                
                # 関数が読み込まれたか確認
                declare -f task_add >/dev/null 2>&1
                echo "DEBUG: task_add function exists: $?" >&2
                
                declare -f add_task >/dev/null 2>&1
                echo "DEBUG: add_task function exists: $?" >&2
                
                declare -f generate_task_id >/dev/null 2>&1
                echo "DEBUG: generate_task_id function exists: $?" >&2
                
                # 関数をエクスポートして子プロセスからも見えるようにする
                export -f task_add 2>/dev/null || true
                export -f add_task 2>/dev/null || true
                export -f generate_task_id 2>/dev/null || true
                
                # 関数が存在するか確認してから呼び出す
                if type task_add &>/dev/null; then
                    echo "DEBUG: Calling task_add function" >&2
                    task_add "$@"
                else
                    # 関数が見つからない場合は直接スクリプトのmain処理を行う
                    echo "DEBUG: task_add function not found, running fallback code" >&2
                    # タスク名などを解析する処理を追加
                    local task_name=""
                    local description=""
                    local concerns=""
                    local parent_id=""
                    local custom_prefix=""
                    local start_num=""
                    
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
                                start_num="$2"
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
                    
                    if [[ -z "$task_name" ]]; then
                        log_error "タスク名は必須です"
                        show_add_help
                        return 1
                    fi
                    
                    # ここでadd_taskを呼び出すか、別の方法でタスクを追加
                    log_error "タスク追加機能の実装が見つかりません"
                    return 1
                fi
            else
                log_error "タスク追加機能が見つかりません"
                return 1
            fi
            ;;
        list)
            # SCRIPT_DIRを元の値に戻す
            SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"
            
            # task_list.shのmain関数を呼び出す
            LIST_PATH=$(find_module_path "commands/task_list.sh")
            if [[ -n "$LIST_PATH" ]]; then
                source "$LIST_PATH"
                task_list "$@"
            else
                log_error "タスク一覧表示機能が見つかりません"
                return 1
            fi
            ;;
        show)
            # SCRIPT_DIRを元の値に戻す
            SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"
            
            # task_show.shのmain関数を呼び出す
            SHOW_PATH=$(find_module_path "commands/task_show.sh")
            if [[ -n "$SHOW_PATH" ]]; then
                source "$SHOW_PATH"
                task_show "$@"
            else
                log_error "タスク詳細表示機能が見つかりません"
                return 1
            fi
            ;;
        edit)
            # SCRIPT_DIRを元の値に戻す
            SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"
            
            # task_edit.shのmain関数を呼び出す
            EDIT_PATH=$(find_module_path "commands/task_edit.sh")
            if [[ -n "$EDIT_PATH" ]]; then
                source "$EDIT_PATH"
                task_edit "$@"
            else
                log_error "タスク編集機能が見つかりません"
                return 1
            fi
            ;;
        delete)
            # SCRIPT_DIRを元の値に戻す
            SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"
            
            # task_delete.shのmain関数を呼び出す
            DELETE_PATH=$(find_module_path "commands/task_delete.sh")
            if [[ -n "$DELETE_PATH" ]]; then
                source "$DELETE_PATH"
                task_delete "$@"
            else
                log_error "タスク削除機能が見つかりません"
                return 1
            fi
            ;;
        subtask)
            # task_subtask.shのtask_subtask関数を呼び出す
            if type task_subtask >/dev/null 2>&1; then
                task_subtask "$@"
            else
                log_error "サブタスク機能が見つかりません"
                return 1
            fi
            ;;
        status)
            # task_status.shのtask_status関数を呼び出す
            if type task_status >/dev/null 2>&1; then
                task_status "$@"
            else
                log_error "ステータス変更機能が見つかりません"
                return 1
            fi
            ;;
        sync)
            # task_sync.shのtask_sync関数を呼び出す
            if type task_sync >/dev/null 2>&1; then
                task_sync "$@"
            else
                log_error "同期機能が見つかりません"
                return 1
            fi
            ;;
        validate)
            # task_validate.shのtask_validate関数を呼び出す
            if type task_validate >/dev/null 2>&1; then
                task_validate "$@"
            else
                log_error "検証機能が見つかりません"
                return 1
            fi
            ;;
        template)
            # SCRIPT_DIRを元の値に戻す
            SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"
            
            # task_template.shのmain関数を呼び出す
            TEMPLATE_PATH=$(find_module_path "commands/task_template.sh")
            if [[ -n "$TEMPLATE_PATH" ]]; then
                source "$TEMPLATE_PATH"
                task_template "$@"
            else
                log_error "テンプレート管理機能が見つかりません"
                return 1
            fi
            ;;
        update)
            # SCRIPT_DIRを元の値に戻す
            SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"
            
            # task_update.shのmain関数を呼び出す
            UPDATE_PATH=$(find_module_path "commands/task_update.sh")
            if [[ -n "$UPDATE_PATH" ]]; then
                source "$UPDATE_PATH"
                task_update "$@"
            else
                log_error "更新機能が見つかりません"
                return 1
            fi
            ;;
        uninstall)
            # SCRIPT_DIRを元の値に戻す
            SCRIPT_DIR="$ORIGINAL_SCRIPT_DIR"
            
            # task_uninstall.shのmain関数を呼び出す
            UNINSTALL_PATH=$(find_module_path "commands/task_uninstall.sh")
            if [[ -n "$UNINSTALL_PATH" ]]; then
                source "$UNINSTALL_PATH"
                task_uninstall "$@"
            else
                log_error "アンインストール機能が見つかりません"
                return 1
            fi
            ;;
        -h|--help)
            show_help
            ;;
        -v|--version)
            show_version
            ;;
        *)
            log_error "不明なコマンド: $command"
            show_help
            return 1
            ;;
    esac

    return 0
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 