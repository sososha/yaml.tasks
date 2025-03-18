#!/bin/bash

# インストール先の設定
INSTALL_BIN="${HOME}/.local/bin"
INSTALL_LIB="${INSTALL_BIN}/lib"
INSTALL_CONFIG="${INSTALL_BIN}/config"

# インストール先ディレクトリの作成
mkdir -p "${INSTALL_BIN}"
mkdir -p "${INSTALL_LIB}"
mkdir -p "${INSTALL_CONFIG}"

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# taskコマンドをコピーして実行可能にする
cp "${SCRIPT_DIR}/task.sh" "${INSTALL_BIN}/task"
chmod +x "${INSTALL_BIN}/task"

# ライブラリファイルをコピー
cp -r "${SCRIPT_DIR}/lib"/* "${INSTALL_LIB}/"

# 設定ファイルをコピー
if [ -d "${SCRIPT_DIR}/config" ]; then
    cp -r "${SCRIPT_DIR}/config"/* "${INSTALL_CONFIG}/"
fi

# テンプレートディレクトリを作成
mkdir -p "${INSTALL_BIN}/tasks/templates"
mkdir -p "${INSTALL_BIN}/tasks/backups"

echo "インストールが完了しました"
echo "task コマンドが使えるようになりました"

# PATHの確認
if [[ ":$PATH:" != *":${INSTALL_BIN}:"* ]]; then
    echo "注意: ${INSTALL_BIN} がPATHに含まれていません"
    echo "以下のコマンドを実行するか、.bashrc や .zshrc に追加してください："
    echo "    export PATH=\"\${HOME}/.local/bin:\${PATH}\""
fi 