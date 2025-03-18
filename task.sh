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
  debug     デバッグモードの切り替え

オプション:
  -h, --help      ヘルプの表示
  -d, --debug     デバッグモードを有効化
  --no-debug      デバッグモードを無効化
  -v, --version   バージョン情報の表示

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

    # デバッグフラグの処理（共通モジュールのロード前に行う）
    for arg in "$@"; do
        case "$arg" in
            -d|--debug)
                export TASK_DEBUG=1
                ;;
            --no-debug)
                export TASK_DEBUG=0
                ;;
        esac
    done

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
            # 環境変数を再評価（カレントディレクトリのtasksを使用するため）
            refresh_environment

            # task_add.shを見つけて読み込む
            local task_add_file="${SCRIPT_DIR}/lib/commands/task_add.sh"
            if [[ -f "$task_add_file" ]]; then
                source "$task_add_file"
            fi

            # 関数をエクスポートして子プロセスからも見えるようにする
            export -f task_add add_task generate_task_id 2>/dev/null || true

            # task_add関数が存在すれば呼び出す
            if type task_add >/dev/null 2>&1; then
                # 引数を解析
                local task_name=""
                local description=""
                local concerns=""
                local parent_id=""
                local custom_prefix=""
                local start_num=""
                
                shift # "add"をシフトして残りの引数を処理
                
                while [[ $# -gt 0 ]]; do
                    case "$1" in
                        -t|--task)
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
                        *)
                            conditional_log_debug "オプション: $1 が見つかりません"
                            log_error "不明なオプション: $1"
                            return 1
                            ;;
                    esac
                done
                
                # 必須項目のチェック
                if [[ -z "$task_name" ]]; then
                    log_error "タスク名は必須です (--task)"
                    return 1
                fi
                
                # タスク追加処理を実行
                task_add "$task_name" "$description" "$concerns" "$parent_id" "$custom_prefix" "$start_num"
            else
                conditional_log_debug "refresh_environment function not found"
                log_error "タスク追加機能は実装されていません"
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
        debug)
            # デバッグモードの切り替え
            if type toggle_debug_mode &>/dev/null; then
                toggle_debug_mode
            else
                echo "デバッグ機能が見つかりません"
                return 1
            fi
            ;;
        -d|--debug)
            # デバッグモードを有効化して最初のコマンドを実行
            if type enable_debug_mode &>/dev/null; then
                enable_debug_mode
                if [[ $# -gt 0 ]]; then
                    main "$@"
                fi
            else
                echo "デバッグ機能が見つかりません"
                return 1
            fi
            ;;
        --no-debug)
            # デバッグモードを無効化して最初のコマンドを実行
            if type disable_debug_mode &>/dev/null; then
                disable_debug_mode
                if [[ $# -gt 0 ]]; then
                    main "$@"
                fi
            else
                echo "デバッグ機能が見つかりません"
                return 1
            fi
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