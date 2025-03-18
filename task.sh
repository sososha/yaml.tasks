#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# タスク管理システムのルートディレクトリを設定
export TASK_DIR="$SCRIPT_DIR"

# 共通パスの検索
find_module_path() {
    local module_name="$1"
    local search_paths=(
        "${SCRIPT_DIR}/lib/${module_name}"
        "${SCRIPT_DIR}/${module_name}"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
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
    "commands/task_add.sh"
    "commands/task_list.sh"
    "commands/task_show.sh"
    "commands/task_edit.sh"
    "commands/task_delete.sh"
    "commands/task_template.sh"
    "commands/task_update.sh"
    "commands/task_uninstall.sh"
)

for cmd in "${COMMANDS[@]}"; do
    CMD_PATH=$(find_module_path "$cmd")
    if [[ -n "$CMD_PATH" ]]; then
        source "$CMD_PATH"
    else
        log_debug "オプション: $cmd が見つかりません"
    fi
done

# ヘルプメッセージの表示
show_help() {
    cat << EOF
使用法: task <コマンド> [オプション]

タスク管理システム

コマンド:
  add       タスクの追加
  list      タスクの一覧表示
  show      タスクの詳細表示
  edit      タスクの編集
  delete    タスクの削除
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

    # 第一引数をコマンドとして処理
    local command="$1"
    shift

    case "$command" in
        add)
            # タスク追加コマンドの処理
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
            
            # 引数を再構築して task_add.sh に渡す
            local args=()
            [[ -n "$task_name" ]] && args+=(-n "$task_name")
            [[ -n "$description" ]] && args+=(-d "$description")
            [[ -n "$concerns" ]] && args+=(-c "$concerns")
            [[ -n "$parent_id" ]] && args+=(-p "$parent_id")
            [[ -n "$custom_prefix" ]] && args+=(--prefix "$custom_prefix")
            [[ -n "$start_num" ]] && args+=(--start-num "$start_num")
            
            main "${args[@]}"
            ;;
        list)
            # task_list.shのmain関数を呼び出す
            main "$@"
            ;;
        show)
            # task_show.shのmain関数を呼び出す
            main "$@"
            ;;
        edit)
            # task_edit.shのmain関数を呼び出す
            main "$@"
            ;;
        delete)
            # task_delete.shのmain関数を呼び出す
            main "$@"
            ;;
        template)
            # task_template.shのmain関数を呼び出す
            main "$@"
            ;;
        update)
            # task_update.shのmain関数を呼び出す
            UPDATE_PATH=$(find_module_path "commands/task_update.sh")
            if [[ -n "$UPDATE_PATH" ]]; then
                source "$UPDATE_PATH"
                main "$@"
            else
                log_error "更新機能が見つかりません"
                return 1
            fi
            ;;
        uninstall)
            # task_uninstall.shのmain関数を呼び出す
            UNINSTALL_PATH=$(find_module_path "commands/task_uninstall.sh")
            if [[ -n "$UNINSTALL_PATH" ]]; then
                source "$UNINSTALL_PATH"
                main "$@"
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