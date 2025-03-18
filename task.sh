#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# タスク管理システムのルートディレクトリを設定
export TASK_DIR="$SCRIPT_DIR"

# 共通ユーティリティの読み込み
source "${SCRIPT_DIR}/lib/utils/common.sh"

# すべてのサブコマンドの読み込み
source "${SCRIPT_DIR}/lib/commands/task_add.sh"
source "${SCRIPT_DIR}/lib/commands/task_list.sh"
source "${SCRIPT_DIR}/lib/commands/task_show.sh"
source "${SCRIPT_DIR}/lib/commands/task_edit.sh"
source "${SCRIPT_DIR}/lib/commands/task_delete.sh"
source "${SCRIPT_DIR}/lib/commands/task_template.sh"

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
            # タスク一覧表示コマンドの処理
            main "$@"
            ;;
        show)
            # タスク詳細表示コマンドの処理
            main "$@"
            ;;
        edit)
            # タスク編集コマンドの処理
            main "$@"
            ;;
        delete)
            # タスク削除コマンドの処理
            main "$@"
            ;;
        template)
            # テンプレート管理コマンドの処理
            main "$@"
            ;;
        update)
            # task_update.shのmain関数を呼び出す
            source "${SCRIPT_DIR}/lib/commands/task_update.sh"
            main "$@"
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