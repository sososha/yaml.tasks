#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 色付きの出力用関数
print_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

# システム要件のチェック
check_requirements() {
    print_info "システム要件をチェックしています..."
    
    # bashのバージョンチェック
    if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
        print_error "Bash 4.0以上が必要です"
        return 1
    fi
    
    # Homebrewのチェック（macOS用）
    if [[ "$(uname)" == "Darwin" ]] && ! command -v brew &> /dev/null; then
        print_error "Homebrewがインストールされていません"
        echo "以下のコマンドでHomebrewをインストールしてください："
        echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        return 1
    fi
    
    return 0
}

# 依存関係のインストール
install_dependencies() {
    print_info "依存関係をインストールしています..."
    
    # yqのインストール
    if ! command -v yq &> /dev/null; then
        if [[ "$(uname)" == "Darwin" ]]; then
            brew install yq
        elif [[ "$(uname)" == "Linux" ]]; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y wget
                YQ_VERSION="v4.40.5"
                YQ_BINARY="yq_linux_amd64"
                wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz" -O - |\
                tar xz && sudo mv ${YQ_BINARY} /usr/local/bin/yq
            elif command -v yum &> /dev/null; then
                sudo yum install -y wget
                YQ_VERSION="v4.40.5"
                YQ_BINARY="yq_linux_amd64"
                wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz" -O - |\
                tar xz && sudo mv ${YQ_BINARY} /usr/local/bin/yq
            else
                print_error "対応していないLinuxディストリビューションです"
                return 1
            fi
        else
            print_error "対応していないOSです"
            return 1
        fi
    fi
    
    print_success "依存関係のインストールが完了しました"
    return 0
}

# 必要なディレクトリの作成
create_directories() {
    print_info "必要なディレクトリを作成しています..."
    
    mkdir -p "${SCRIPT_DIR}/tasks/"{backups,templates,config}
    
    if [[ ! -f "${SCRIPT_DIR}/tasks/config/template_config.yaml" ]]; then
        cp "${SCRIPT_DIR}/config/template_config.yaml.example" "${SCRIPT_DIR}/tasks/config/template_config.yaml"
    fi
    
    if [[ ! -f "${SCRIPT_DIR}/tasks/tasks.yaml" ]]; then
        echo "tasks: []" > "${SCRIPT_DIR}/tasks/tasks.yaml"
    fi
    
    print_success "ディレクトリの作成が完了しました"
    return 0
}

# シンボリックリンクの作成
create_symlink() {
    print_info "コマンドのシンボリックリンクを作成しています..."
    
    # ユーザーのbinディレクトリを確認/作成
    local user_bin_dir="${HOME}/.local/bin"
    if [[ ! -d "$user_bin_dir" ]]; then
        mkdir -p "$user_bin_dir"
    fi
    
    # libディレクトリのシンボリックリンクを作成
    if [[ ! -d "${user_bin_dir}/lib" ]]; then
        ln -sf "${SCRIPT_DIR}/lib" "${user_bin_dir}/lib"
    fi
    
    # PATHに追加されているか確認
    if [[ ":$PATH:" != *":$user_bin_dir:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.zshrc"
    fi
    
    # シンボリックリンクの作成
    ln -sf "${SCRIPT_DIR}/task.sh" "${user_bin_dir}/task"
    chmod +x "${SCRIPT_DIR}/task.sh"
    
    print_success "シンボリックリンクの作成が完了しました"
    return 0
}

# メイン処理
main() {
    print_info "タスク管理システムのインストールを開始します..."
    
    # システム要件のチェック
    if ! check_requirements; then
        print_error "システム要件を満たしていません"
        return 1
    fi
    
    # 依存関係のインストール
    if ! install_dependencies; then
        print_error "依存関係のインストールに失敗しました"
        return 1
    fi
    
    # ディレクトリの作成
    if ! create_directories; then
        print_error "ディレクトリの作成に失敗しました"
        return 1
    fi
    
    # シンボリックリンクの作成
    if ! create_symlink; then
        print_error "シンボリックリンクの作成に失敗しました"
        return 1
    fi
    
    print_success "インストールが完了しました"
    print_info "シェルを再起動するか、以下のコマンドを実行してください："
    echo "source ~/.bashrc # または source ~/.zshrc"
    
    return 0
}

# スクリプトの実行
main "$@" 