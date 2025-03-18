#!/bin/bash

# 共通ユーティリティの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../core/yaml_processor.sh"
source "${SCRIPT_DIR}/../core/template_engine.sh"

# ヘルプ表示
show_sync_help() {
    cat << EOF
使用法: task sync [オプション]

タスクデータと表示ファイルを同期します。

オプション:
    -c, --check        同期状態のチェックのみ実行
    -f, --force       確認なしで同期を実行
    -b, --backup      同期前にバックアップを作成
    -h, --help        このヘルプを表示

例:
    task sync
    task sync --check
    task sync --force
    task sync --backup
EOF
}

# 同期状態のチェック
check_sync_status() {
    local tasks_file_hash
    local project_tasks_hash
    
    # 各ファイルのハッシュを計算
    if [[ -f "$TASKS_FILE" ]]; then
        tasks_file_hash=$(sha256sum "$TASKS_FILE" | cut -d' ' -f1)
    else
        log_error "タスクデータファイルが見つかりません: $TASKS_FILE"
        return 1
    fi
    
    if [[ -f "$PROJECT_TASKS_FILE" ]]; then
        project_tasks_hash=$(sha256sum "$PROJECT_TASKS_FILE" | cut -d' ' -f1)
    else
        log_info "プロジェクトタスクファイルが存在しません: $PROJECT_TASKS_FILE"
        return 1
    fi
    
    # 最後の同期ハッシュを取得
    local last_sync_hash
    if [[ -f "${CONFIG_DIR}/last_sync" ]]; then
        last_sync_hash=$(cat "${CONFIG_DIR}/last_sync")
    else
        log_info "前回の同期情報が見つかりません"
        return 1
    fi
    
    # 同期状態をチェック
    if [[ "$tasks_file_hash" != "$last_sync_hash" ]]; then
        log_info "タスクデータに変更があります"
        return 1
    elif [[ "$project_tasks_hash" != "$last_sync_hash" ]]; then
        log_info "表示ファイルに変更があります"
        return 1
    else
        log_info "タスクデータと表示ファイルは同期しています"
        return 0
    fi
}

# バックアップの作成
create_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    # タスクデータのバックアップ
    if [[ -f "$TASKS_FILE" ]]; then
        cp "$TASKS_FILE" "${TASKS_FILE}.${timestamp}.bak"
        log_info "タスクデータのバックアップを作成しました: ${TASKS_FILE}.${timestamp}.bak"
    fi
    
    # プロジェクトタスクファイルのバックアップ
    if [[ -f "$PROJECT_TASKS_FILE" ]]; then
        cp "$PROJECT_TASKS_FILE" "${PROJECT_TASKS_FILE}.${timestamp}.bak"
        log_info "表示ファイルのバックアップを作成しました: ${PROJECT_TASKS_FILE}.${timestamp}.bak"
    fi
}

# 同期の実行
perform_sync() {
    local force="$1"
    local backup="$2"
    
    # 同期状態をチェック
    if check_sync_status; then
        log_info "同期は不要です"
        return 0
    fi
    
    # 確認プロンプト
    if [[ "$force" != "true" ]]; then
        read -p "タスクデータと表示ファイルを同期しますか？ (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "同期をキャンセルしました"
            return 0
        fi
    fi
    
    # バックアップの作成
    if [[ "$backup" == "true" ]]; then
        create_backup
    fi
    
    # タスクファイルの再生成
    if generate_task_file_from_template; then
        # 同期ハッシュの更新
        sha256sum "$TASKS_FILE" | cut -d' ' -f1 > "${CONFIG_DIR}/last_sync"
        log_info "同期が完了しました"
        return 0
    else
        log_error "同期に失敗しました"
        return 1
    fi
}

# メイン処理
main() {
    local check_only="false"
    local force="false"
    local backup="false"
    
    # 引数の解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_sync_help
                return 0
                ;;
            -c|--check)
                check_only="true"
                shift
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            -b|--backup)
                backup="true"
                shift
                ;;
            *)
                log_error "不明な引数: $1"
                show_sync_help
                return 1
                ;;
        esac
    done
    
    # チェックのみの場合
    if [[ "$check_only" == "true" ]]; then
        check_sync_status
        return $?
    fi
    
    # 同期の実行
    perform_sync "$force" "$backup"
    return $?
}

# スクリプトとして実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 