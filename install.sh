#!/bin/bash

# インストール先の設定
INSTALL_BIN="${HOME}/.local/bin"
INSTALL_LIB="${INSTALL_BIN}/lib"
INSTALL_CONFIG="${INSTALL_BIN}/config"

# インストール先ディレクトリの作成
mkdir -p "${INSTALL_BIN}"
mkdir -p "${INSTALL_LIB}/commands"
mkdir -p "${INSTALL_LIB}/core"
mkdir -p "${INSTALL_LIB}/utils"
mkdir -p "${INSTALL_CONFIG}"

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# taskコマンドをコピーして実行可能にする
cp "${SCRIPT_DIR}/task.sh" "${INSTALL_BIN}/task"
chmod +x "${INSTALL_BIN}/task"

# ライブラリファイルをコピー
cp -r "${SCRIPT_DIR}/lib/commands"/* "${INSTALL_LIB}/commands/"
cp -r "${SCRIPT_DIR}/lib/core"/* "${INSTALL_LIB}/core/"
cp -r "${SCRIPT_DIR}/lib/utils"/* "${INSTALL_LIB}/utils/"

# 設定ファイルをコピー
if [ -d "${SCRIPT_DIR}/config" ]; then
    cp -r "${SCRIPT_DIR}/config"/* "${INSTALL_CONFIG}/"
fi

# テンプレートディレクトリを作成
mkdir -p "${INSTALL_BIN}/tasks/templates"
mkdir -p "${INSTALL_BIN}/tasks/backups"
mkdir -p "${INSTALL_BIN}/tasks/config"

echo "インストールが完了しました"
echo "task コマンドが使えるようになりました"

# PATHの確認
if [[ ":$PATH:" != *":${INSTALL_BIN}:"* ]]; then
    echo "注意: ${INSTALL_BIN} がPATHに含まれていません"
    echo "以下のコマンドを実行するか、.bashrc や .zshrc に追加してください："
    echo "    export PATH=\"\${HOME}/.local/bin:\${PATH}\""
fi 