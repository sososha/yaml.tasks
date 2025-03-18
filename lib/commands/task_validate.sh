#!/bin/bash

# 共通ユーティリティの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../core/data_validator.sh"

# ヘルプ表示
show_validate_help() {
    cat << EOF
使用法: task validate [オプション]

タスクデータの整合性を検証します。

オプション:
    -d, --data-only    タスクデータのみを検証（設定ファイルの検証をスキップ）
    -q, --quiet        エラーのみを表示
    -h, --help        このヘルプを表示

例:
    task validate
    task validate --data-only
    task validate --quiet
EOF
}

# メイン処理
main() {
    local check_config=true
    local quiet=false

    # オプションの解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_validate_help
                return 0
                ;;
            -d|--data-only)
                check_config=false
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            *)
                log_error "不明なオプション: $1"
                show_validate_help
                return 1
                ;;
        esac
    done

    # 検証の実行
    if [[ "$quiet" == "true" ]]; then
        if validate_data_integrity "$check_config" > /dev/null; then
            return 0
        else
            return 1
        fi
    else
        validate_data_integrity "$check_config"
        return $?
    fi
}

# スクリプトとして実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 