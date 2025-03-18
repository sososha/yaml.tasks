#!/bin/bash

# テスト用の共通変数
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
TEST_WORKSPACE="/tmp/task_test_$(date +%s)"

# 色付きの出力用の変数
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# テスト用のヘルパー関数
setup_test_workspace() {
    mkdir -p "$TEST_WORKSPACE"
    cd "$TEST_WORKSPACE"
    
    # 必要なディレクトリとファイルをコピー
    mkdir -p lib/{core,commands,utils} config templates tasks
    cp -r "$PROJECT_ROOT/lib" "$TEST_WORKSPACE/"
    cp -r "$PROJECT_ROOT/config" "$TEST_WORKSPACE/"
    cp -r "$PROJECT_ROOT/templates" "$TEST_WORKSPACE/"
    cp "$PROJECT_ROOT/task.sh" "$TEST_WORKSPACE/"
    
    # テスト用の設定を初期化
    echo "current_template: default" > "$TEST_WORKSPACE/config/template_config.yaml"
    echo "tasks: []" > "$TEST_WORKSPACE/tasks/tasks.yaml"
    touch "$TEST_WORKSPACE/tasks/project.tasks"
}

cleanup_test_workspace() {
    if [[ -d "$TEST_WORKSPACE" ]]; then
        rm -rf "$TEST_WORKSPACE"
    fi
}

# アサーション関数
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓ テスト成功${NC}${message:+: $message}"
        return 0
    else
        echo -e "${RED}✗ テスト失敗${NC}${message:+: $message}"
        echo "  期待値: $expected"
        echo "  実際値: $actual"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-}"
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓ テスト成功${NC}${message:+: $message}"
        return 0
    else
        echo -e "${RED}✗ テスト失敗${NC}${message:+: $message}"
        echo "  ファイルが存在しません: $file"
        return 1
    fi
}

assert_directory_exists() {
    local directory="$1"
    local message="${2:-}"
    
    if [[ -d "$directory" ]]; then
        echo -e "${GREEN}✓ テスト成功${NC}${message:+: $message}"
        return 0
    else
        echo -e "${RED}✗ テスト失敗${NC}${message:+: $message}"
        echo "  ディレクトリが存在しません: $directory"
        return 1
    fi
}

assert_command_success() {
    local command="$1"
    local message="${2:-}"
    
    if eval "$command"; then
        echo -e "${GREEN}✓ テスト成功${NC}${message:+: $message}"
        return 0
    else
        echo -e "${RED}✗ テスト失敗${NC}${message:+: $message}"
        echo "  コマンドが失敗: $command"
        return 1
    fi
}

assert_command_fails() {
    local command="$1"
    local message="${2:-}"
    
    if ! eval "$command"; then
        echo -e "${GREEN}✓ テスト成功${NC}${message:+: $message}"
        return 0
    else
        echo -e "${RED}✗ テスト失敗${NC}${message:+: $message}"
        echo "  コマンドが成功: $command"
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local message="${3:-}"
    
    if grep -q "$pattern" "$file"; then
        echo -e "${GREEN}✓ テスト成功${NC}${message:+: $message}"
        return 0
    else
        echo -e "${RED}✗ テスト失敗${NC}${message:+: $message}"
        echo "  パターンが見つかりません: $pattern"
        echo "  ファイル: $file"
        return 1
    fi
}

assert_yaml_path_equals() {
    local file="$1"
    local path="$2"
    local expected="$3"
    local message="${4:-}"
    
    local actual
    actual=$(yq eval "$path" "$file")
    
    if [[ "$actual" == "$expected" ]]; then
        echo -e "${GREEN}✓ テスト成功${NC}${message:+: $message}"
        return 0
    else
        echo -e "${RED}✗ テスト失敗${NC}${message:+: $message}"
        echo "  YAMLパス: $path"
        echo "  期待値: $expected"
        echo "  実際値: $actual"
        return 1
    fi
}

# テストスイートの実行
run_test_suite() {
    local test_file="$1"
    local test_name
    test_name=$(basename "$test_file" .sh)
    
    echo -e "\n${YELLOW}テストスイートの実行: $test_name${NC}"
    
    # テスト環境のセットアップ
    setup_test_workspace
    
    # テストの実行
    source "$test_file"
    
    # テスト環境のクリーンアップ
    cleanup_test_workspace
}

# テストランナー
run_all_tests() {
    local failed_tests=0
    local total_tests=0
    
    # ユニットテストの実行
    echo -e "\n${YELLOW}ユニットテストの実行${NC}"
    for test_file in "$TEST_DIR"/unit/test_*.sh; do
        if [[ -f "$test_file" ]]; then
            ((total_tests++))
            if ! run_test_suite "$test_file"; then
                ((failed_tests++))
            fi
        fi
    done
    
    # 統合テストの実行
    echo -e "\n${YELLOW}統合テストの実行${NC}"
    for test_file in "$TEST_DIR"/integration/test_*.sh; do
        if [[ -f "$test_file" ]]; then
            ((total_tests++))
            if ! run_test_suite "$test_file"; then
                ((failed_tests++))
            fi
        fi
    done
    
    # テスト結果の表示
    echo -e "\n${YELLOW}テスト結果${NC}"
    echo "総テスト数: $total_tests"
    echo "失敗: $failed_tests"
    
    return $failed_tests
} 