#!/bin/bash

# uninstallコマンドのヘルプを表示
show_uninstall_help() {
    cat << EOF
使用法: task uninstall [オプション]

タスク管理システムをアンインストールします。

オプション:
  -f, --force     確認なしで強制的にアンインストール
  -k, --keep-data タスクデータを保持する
  -h, --help      このヘルプを表示

説明:
  このコマンドはタスク管理システムをシステムからアンインストールします。
  デフォルトでは、インストールされたファイルとタスクデータが削除されます。
  タスクデータを残したい場合は、--keep-dataオプションを使用してください。
EOF
}

# メイン関数
main() {
    local force=0
    local keep_data=0

    # 引数の解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force=1
                shift
                ;;
            -k|--keep-data)
                keep_data=1
                shift
                ;;
            -h|--help)
                show_uninstall_help
                return 0
                ;;
            *)
                log_error "不明なオプション: $1"
                show_uninstall_help
                return 1
                ;;
        esac
    done

    # インストールディレクトリの確認
    INSTALL_BIN="${HOME}/.local/bin"
    
    if [[ ! -f "${INSTALL_BIN}/task" ]]; then
        log_error "タスク管理システムがインストールされていません"
        return 1
    fi

    # 確認プロンプト（--forceオプションが指定されていない場合）
    if [[ $force -eq 0 ]]; then
        echo "タスク管理システムをアンインストールします"
        if [[ $keep_data -eq 0 ]]; then
            echo "警告: すべてのタスクデータも削除されます"
        fi
        
        read -p "続行しますか？ (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "アンインストールがキャンセルされました"
            return 0
        fi
    fi

    # アンインストール処理を実行
    echo "タスク管理システムをアンインストールしています..."
    
    # 実行ファイルとライブラリを削除
    rm -f "${INSTALL_BIN}/task"
    rm -rf "${INSTALL_BIN}/lib/commands/task_*.sh"
    rm -rf "${INSTALL_BIN}/lib/utils/common.sh"
    rm -rf "${INSTALL_BIN}/lib/core"
    
    # ディレクトリが空になったら削除
    rmdir "${INSTALL_BIN}/lib/commands" 2>/dev/null || true
    rmdir "${INSTALL_BIN}/lib/utils" 2>/dev/null || true
    rmdir "${INSTALL_BIN}/lib" 2>/dev/null || true
    
    # 設定ファイルを削除
    rm -rf "${INSTALL_BIN}/config" 2>/dev/null || true
    
    # タスクデータの削除（--keep-dataオプションが指定されていない場合）
    if [[ $keep_data -eq 0 ]]; then
        rm -rf "${INSTALL_BIN}/tasks" 2>/dev/null || true
    else
        echo "タスクデータは保持されました: ${INSTALL_BIN}/tasks"
    fi
    
    echo "タスク管理システムが正常にアンインストールされました"
    return 0
} 