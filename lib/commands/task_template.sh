#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 共通のユーティリティをインポート
source "${SCRIPT_DIR}/utils/common.sh"
source "${SCRIPT_DIR}/core/template_engine.sh"

# ヘルプメッセージの表示
show_template_help() {
    cat << EOF
Usage: task template [options]
Manage task list templates.

Options:
  -l, --list               List available templates
  -s, --show [name]        Show template content
  -u, --use <name>         Use specified template
  -c, --create <name>      Create new template
  -h, --help               Show this help message

Examples:
  task template --list
  task template --show
  task template --show detailed
  task template --use minimal
  task template --create custom
EOF
}

# テンプレート一覧の表示
list_templates() {
    local current_template
    current_template=$(get_current_template)
    
    echo "利用可能なテンプレート:"
    for template in "${TEMPLATES_DIR}"/*.template; do
        local template_name
        template_name=$(basename "$template" .template)
        if [[ "$template_name" == "$current_template" ]]; then
            echo "* ${template_name} (現在使用中)"
        else
            echo "  ${template_name}"
        fi
    done
}

# テンプレートの内容を表示
show_template() {
    local template_name="$1"
    local template_file
    
    if [[ -z "$template_name" ]]; then
        template_name=$(get_current_template)
        template_file="${TEMPLATES_DIR}/${template_name}.template"
        echo "現在のテンプレート (${template_name}):"
    else
        template_file="${TEMPLATES_DIR}/${template_name}.template"
        echo "テンプレート ${template_name}:"
    fi
    
    if [[ ! -f "$template_file" ]]; then
        log_error "テンプレートが見つかりません: ${template_name}"
        return 1
    fi
    
    echo
    cat "$template_file"
}

# テンプレートを使用する
use_template() {
    local template_name="$1"
    local template_file="${TEMPLATES_DIR}/${template_name}.template"
    
    if [[ ! -f "$template_file" ]]; then
        log_error "テンプレートが見つかりません: ${template_name}"
        return 1
    fi
    
    # 現在のテンプレートと同じ場合は確認
    local current_template
    current_template=$(get_current_template)
    if [[ "$template_name" == "$current_template" ]]; then
        log_info "既に ${template_name} テンプレートを使用しています"
        return 0
    fi
    
    # テンプレート設定を更新
    if update_template_config "current_template" "$template_name"; then
        log_info "テンプレートを ${template_name} に変更しました"
        
        # タスクファイルを再生成
        if generate_task_file_from_template; then
            log_info "タスクファイルを再生成しました"
            return 0
        else
            log_error "タスクファイルの再生成に失敗しました"
            return 1
        fi
    else
        log_error "テンプレート設定の更新に失敗しました"
        return 1
    fi
}

# 新しいテンプレートを作成
create_template() {
    local template_name="$1"
    local template_file="${TEMPLATES_DIR}/${template_name}.template"
    
    if [[ -f "$template_file" ]]; then
        log_error "テンプレートはすでに存在します: ${template_name}"
        return 1
    fi
    
    # テンプレートディレクトリを確認
    mkdir -p "${TEMPLATES_DIR}"
    
    # デフォルトテンプレートをコピー
    local default_template="${TEMPLATES_DIR}/default.template"
    if [[ ! -f "$default_template" ]]; then
        create_default_template
    fi
    
    cp "$default_template" "$template_file"
    
    if [[ $? -eq 0 ]]; then
        log_info "新しいテンプレートを作成しました: ${template_name}"
        echo "テンプレートを編集するには: ${template_file}"
        return 0
    else
        log_error "テンプレートの作成に失敗しました"
        return 1
    fi
}

# メイン処理
main() {
    # 引数がない場合はヘルプを表示
    if [[ $# -eq 0 ]]; then
        show_template_help
        return 0
    fi
    
    # 引数の解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--list)
                list_templates
                return $?
                ;;
            -s|--show)
                if [[ -n "$2" && "$2" != -* ]]; then
                    show_template "$2"
                    shift
                else
                    show_template
                fi
                return $?
                ;;
            -u|--use)
                if [[ -z "$2" || "$2" == -* ]]; then
                    log_error "テンプレート名を指定してください"
                    show_template_help
                    return 1
                fi
                use_template "$2"
                shift
                return $?
                ;;
            -c|--create)
                if [[ -z "$2" || "$2" == -* ]]; then
                    log_error "テンプレート名を指定してください"
                    show_template_help
                    return 1
                fi
                create_template "$2"
                shift
                return $?
                ;;
            -h|--help)
                show_template_help
                return 0
                ;;
            *)
                log_error "不明なオプション: $1"
                show_template_help
                return 1
                ;;
        esac
        shift
    done
    
    return 0
}

# スクリプトとして実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 