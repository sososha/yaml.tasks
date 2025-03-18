#!/bin/bash

# 共通ユーティリティの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../core/yaml_processor.sh"
source "${SCRIPT_DIR}/../core/template_engine.sh"

# ヘルプ表示
show_template_help() {
    cat << EOF
使用法: task template <サブコマンド> [オプション]

テンプレートの操作を行います。

サブコマンド:
    use <テンプレート名>     使用するテンプレートを切り替え
    config <キー> <値>       テンプレート設定を変更
    list                     利用可能なテンプレート一覧を表示
    show [テンプレート名]    テンプレートの内容を表示
    generate                 現在の設定でタスクファイルを再生成
    help                     このヘルプを表示

オプション:
    -f, --force             確認なしで実行
    -h, --help             このヘルプを表示

例:
    task template use detailed
    task template config "symbols.completed" "✅"
    task template config "format.indent_char" "    "
    task template list
    task template show default
    task template generate
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
        if [[ "$template" == "$current_template" ]]; then
            echo "* ${template_name} (現在使用中)"
        else
            echo "  ${template_name}"
        fi
    done
}

# テンプレートの内容表示
show_template() {
    local template_name="$1"
    local template_file
    
    if [[ -z "$template_name" ]]; then
        template_file=$(get_current_template)
        template_name=$(basename "$template_file" .template)
        echo "現在のテンプレート (${template_name}):"
    else
        template_file="${TEMPLATES_DIR}/${template_name}.template"
        echo "テンプレート ${template_name}:"
    fi
    
    if [[ -f "$template_file" ]]; then
        echo "---"
        cat "$template_file"
        echo "---"
    else
        log_error "テンプレートが見つかりません: ${template_name}"
        return 1
    fi
}

# テンプレートの使用
use_template() {
    local template_name="$1"
    local force="$2"
    local template_file="${TEMPLATES_DIR}/${template_name}.template"
    
    # テンプレートの存在確認
    if [[ ! -f "$template_file" ]]; then
        log_error "テンプレートが見つかりません: ${template_name}"
        return 1
    fi
    
    # 現在のテンプレートと同じ場合は確認
    local current_template
    current_template=$(get_current_template)
    if [[ "$template_file" == "$current_template" ]]; then
        log_info "既に ${template_name} テンプレートを使用しています"
        return 0
    fi
    
    # 確認プロンプト
    if [[ "$force" != "true" ]]; then
        read -p "テンプレートを ${template_name} に変更しますか？ (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "テンプレートの変更をキャンセルしました"
            return 0
        fi
    fi
    
    # テンプレートの更新
    if update_template_config "current_template" "$template_name"; then
        log_info "テンプレートを ${template_name} に変更しました"
        generate_task_file_from_template
    else
        log_error "テンプレートの変更に失敗しました"
        return 1
    fi
}

# 設定の変更
update_config() {
    local key="$1"
    local value="$2"
    local force="$3"
    
    # 現在の値を取得
    local current_value
    current_value=$(yq eval ".$key" "$CONFIG_FILE")
    
    # 現在の値と同じ場合は確認
    if [[ "$current_value" == "$value" ]]; then
        log_info "設定 ${key} は既に ${value} に設定されています"
        return 0
    fi
    
    # 確認プロンプト
    if [[ "$force" != "true" ]]; then
        read -p "設定 ${key} を ${value} に変更しますか？ (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "設定の変更をキャンセルしました"
            return 0
        fi
    fi
    
    # 設定の更新
    if update_template_config "$key" "$value"; then
        log_info "設定 ${key} を ${value} に変更しました"
        generate_task_file_from_template
    else
        log_error "設定の変更に失敗しました"
        return 1
    fi
}

# メイン処理
main() {
    local force="false"
    
    # 引数がない場合はヘルプを表示
    if [[ $# -eq 0 ]]; then
        show_template_help
        return 0
    fi
    
    # サブコマンドの取得
    local subcommand="$1"
    shift
    
    # オプションの解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_template_help
                return 0
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    # サブコマンドの実行
    case "$subcommand" in
        use)
            if [[ -z "$1" ]]; then
                log_error "テンプレート名を指定してください"
                return 1
            fi
            use_template "$1" "$force"
            ;;
        config)
            if [[ -z "$1" || -z "$2" ]]; then
                log_error "設定キーと値を指定してください"
                return 1
            fi
            update_config "$1" "$2" "$force"
            ;;
        list)
            list_templates
            ;;
        show)
            show_template "$1"
            ;;
        generate)
            generate_task_file_from_template
            log_info "タスクファイルを再生成しました"
            ;;
        help)
            show_template_help
            ;;
        *)
            log_error "不明なサブコマンド: $subcommand"
            show_template_help
            return 1
            ;;
    esac
    
    return $?
}

# スクリプトとして実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 