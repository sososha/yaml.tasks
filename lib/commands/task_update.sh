#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 共通ユーティリティをインポート
source "${SCRIPT_DIR}/utils/common.sh"

# デフォルトの設定
DEFAULT_REPO="https://github.com/sososha/yaml.tasks.git"
DEFAULT_BRANCH="main"
TEMP_DIR="/tmp/task.sh_update"

# ヘルプメッセージの表示
show_update_help() {
    cat << EOF
使用法: task update [オプション]

タスク管理システムを最新バージョンに更新します。

オプション:
  -r, --repo <URL>       GitHubリポジトリのURL（デフォルト: ${DEFAULT_REPO}）
  -b, --branch <ブランチ> 使用するブランチ名（デフォルト: ${DEFAULT_BRANCH}）
  -f, --force            確認なしで更新を実行
  -h, --help             このヘルプを表示

例:
  task update
  task update --force
  task update --repo https://github.com/yourusername/yaml.tasks.git
EOF
}

# 更新処理を実行
update_task_system() {
    local repo_url="$1"
    local branch="$2"
    local force="$3"
    
    # 一時ディレクトリの準備
    rm -rf "$TEMP_DIR" &>/dev/null
    mkdir -p "$TEMP_DIR"
    
    log_info "タスク管理システムの更新を開始します..."
    
    # 確認（forceオプションがない場合）
    if [[ "$force" != "true" ]]; then
        read -p "タスク管理システムを更新します。続行しますか？ (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "更新をキャンセルしました。"
            return 0
        fi
    fi
    
    # Gitリポジトリのクローン
    log_info "最新のコードを取得しています..."
    if ! git clone --depth 1 --branch "$branch" "$repo_url" "$TEMP_DIR"; then
        log_error "リポジトリのクローンに失敗しました: $repo_url"
        return 1
    fi
    
    # インストールスクリプトの実行
    log_info "更新をインストールしています..."
    if [[ -f "$TEMP_DIR/install.sh" ]]; then
        chmod +x "$TEMP_DIR/install.sh"
        if ! "$TEMP_DIR/install.sh"; then
            log_error "インストールスクリプトの実行に失敗しました"
            return 1
        fi
    else
        log_error "インストールスクリプトが見つかりません"
        return 1
    fi
    
    # 後片付け
    rm -rf "$TEMP_DIR" &>/dev/null
    
    log_info "タスク管理システムが正常に更新されました！"
    return 0
}

# メイン処理
main() {
    local repo_url="$DEFAULT_REPO"
    local branch="$DEFAULT_BRANCH"
    local force=false
    
    # 引数がない場合はヘルプを表示
    if [[ $# -eq 0 ]]; then
        update_task_system "$repo_url" "$branch" "$force"
        return $?
    fi
    
    # 引数の解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--repo)
                repo_url="$2"
                shift 2
                ;;
            -b|--branch)
                branch="$2"
                shift 2
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -h|--help)
                show_update_help
                return 0
                ;;
            *)
                log_error "不明なオプション: $1"
                show_update_help
                return 1
                ;;
        esac
    done
    
    # 更新を実行
    update_task_system "$repo_url" "$branch" "$force"
    return $?
}

# スクリプトとして実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 