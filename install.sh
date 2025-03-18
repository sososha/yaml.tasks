#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# カラー出力の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# ログ出力関数
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# システム要件のチェック
check_requirements() {
    print_info "システム要件をチェックしています..."
    
    # Bashバージョンのチェック
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        print_error "Bash 4.0以上が必要です"
        return 1
    fi
    
    # macOSの場合はHomebrewのチェック
    if [[ "$(uname)" == "Darwin" ]]; then
        if ! command -v brew &> /dev/null; then
            print_error "Homebrewがインストールされていません"
            return 1
        fi
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
                sudo apt-get update && sudo apt-get install -y yq
            elif command -v yum &> /dev/null; then
                sudo yum install -y yq
            else
                print_error "パッケージマネージャーが見つかりません"
                return 1
            fi
        fi
    fi
    
    print_success "依存関係のインストールが完了しました"
    return 0
}

# インストールディレクトリの設定
INSTALL_DIR="${HOME}/.task"
BIN_DIR="${HOME}/.local/bin"

# 必要なディレクトリの作成とファイルのコピー
create_directories() {
    print_info "必要なディレクトリを作成しています..."
    
    # インストールディレクトリの作成
    mkdir -p "${INSTALL_DIR}"/{lib,config,tasks/{backups,templates}}
    
    # ライブラリのコピー
    cp -r "${SCRIPT_DIR}/lib"/* "${INSTALL_DIR}/lib/"
    
    # 設定ファイルのコピー
    if [[ ! -f "${INSTALL_DIR}/config/template_config.yaml" ]]; then
        cp "${SCRIPT_DIR}/config/template_config.yaml.example" "${INSTALL_DIR}/config/template_config.yaml"
    fi
    
    # タスクファイルの作成
    if [[ ! -f "${INSTALL_DIR}/tasks/tasks.yaml" ]]; then
        echo "tasks: []" > "${INSTALL_DIR}/tasks/tasks.yaml"
    fi
    
    print_success "ディレクトリの作成が完了しました"
    return 0
}

# シンボリックリンクの作成
create_symlink() {
    print_info "コマンドのシンボリックリンクを作成しています..."
    
    # binディレクトリの作成
    mkdir -p "${BIN_DIR}"
    
    # taskコマンドの作成
    cat > "${BIN_DIR}/task" << 'EOF'
#!/bin/bash

# インストールディレクトリの設定
INSTALL_DIR="${HOME}/.task"
TASK_DIR="$(pwd)"

# 共通ユーティリティの読み込み
source "${INSTALL_DIR}/lib/utils/common.sh"
source "${INSTALL_DIR}/lib/utils/validators.sh"

# バージョン情報
VERSION="0.1.0"

# ヘルプメッセージの表示
show_help() {
    cat << HELP
Task Management System v${VERSION}

Usage:
    task <command> [options] [arguments]

Commands:
    start       Initialize the task management system
    init        Re-initialize the system (preserves existing data)
    add         Add new task(s)
    delete      Delete task(s)
    subtask     Add subtask(s) to an existing task
    status      Change task status
    list        List all tasks
    template    Manage task templates
    sync        Synchronize task data and display
    sort        Sort tasks
    validate    Validate task data integrity
    edit        Edit an existing task
    help        Show this help message

Options:
    -h, --help     Show this help message
    -v, --version  Show version information

For more information about a command:
    task help <command>
HELP
}

# バージョン情報の表示
show_version() {
    echo "Task Management System v${VERSION}"
}

# コマンドの実行
execute_command() {
    local command="$1"
    shift
    
    case "$command" in
        "start")
            source "${INSTALL_DIR}/lib/commands/task_start.sh"
            main "$@"
            ;;
        "init")
            source "${INSTALL_DIR}/lib/commands/task_init.sh"
            main "$@"
            ;;
        "add")
            source "${INSTALL_DIR}/lib/commands/task_add.sh"
            main "$@"
            ;;
        "delete")
            source "${INSTALL_DIR}/lib/commands/task_delete.sh"
            main "$@"
            ;;
        "subtask")
            source "${INSTALL_DIR}/lib/commands/task_subtask.sh"
            main "$@"
            ;;
        "status")
            source "${INSTALL_DIR}/lib/commands/task_status.sh"
            main "$@"
            ;;
        "list")
            source "${INSTALL_DIR}/lib/commands/task_list.sh"
            main "$@"
            ;;
        "template")
            source "${INSTALL_DIR}/lib/commands/task_template.sh"
            main "$@"
            ;;
        "sync")
            source "${INSTALL_DIR}/lib/commands/task_sync.sh"
            main "$@"
            ;;
        "sort")
            source "${INSTALL_DIR}/lib/commands/task_sort.sh"
            main "$@"
            ;;
        "validate")
            source "${INSTALL_DIR}/lib/commands/task_validate.sh"
            main "$@"
            ;;
        "edit")
            source "${INSTALL_DIR}/lib/commands/task_edit.sh"
            main "$@"
            ;;
        "help")
            if [[ $# -eq 0 ]]; then
                show_help
            else
                source "${INSTALL_DIR}/lib/commands/task_help.sh"
                main "$@"
            fi
            ;;
        *)
            echo "Error: Unknown command '$command'"
            echo "Run 'task help' for usage information"
            exit 1
            ;;
    esac
}

# メイン処理
main() {
    # 引数がない場合はヘルプを表示
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    # オプションの処理
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        *)
            execute_command "$@"
            ;;
    esac
}

# スクリプトの実行
main "$@"
EOF
    
    # 実行権限の付与
    chmod +x "${BIN_DIR}/task"
    
    # PATHの設定
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.zshrc"
    fi
    
    print_success "シンボリックリンクの作成が完了しました"
    return 0
}

# メイン処理
main() {
    print_info "タスク管理システムのインストールを開始します..."
    
    # システム要件のチェック
    check_requirements || exit 1
    
    # 依存関係のインストール
    install_dependencies || exit 1
    
    # 必要なディレクトリの作成とファイルのコピー
    create_directories || exit 1
    
    # シンボリックリンクの作成
    create_symlink || exit 1
    
    print_success "インストールが完了しました"
    print_info "シェルを再起動するか、以下のコマンドを実行してください："
    echo "source ~/.bashrc # または source ~/.zshrc"
    
    return 0
}

# スクリプトの実行
main 