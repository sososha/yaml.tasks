#!/bin/bash

# テストヘルパーの読み込み
source "$(dirname "${BASH_SOURCE[0]}")/test_helper.sh"

# 色付きの出力用の変数
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# テスト結果のカウンター
total_tests=0
failed_tests=0

# ユニットテストの実行
echo -e "\n${YELLOW}ユニットテストの実行${NC}"
for test_file in "$TEST_DIR"/unit/test_*.sh; do
    if [[ -f "$test_file" ]]; then
        ((total_tests++))
        echo -e "\n${YELLOW}テストの実行: $(basename "$test_file")${NC}"
        
        # テスト環境のセットアップ
        setup_test_workspace
        
        # テストの実行
        if ! source "$test_file"; then
            ((failed_tests++))
            echo -e "${RED}✗ テスト失敗: $(basename "$test_file")${NC}"
        fi
        
        # テスト環境のクリーンアップ
        cleanup_test_workspace
    fi
done

# 統合テストの実行
echo -e "\n${YELLOW}統合テストの実行${NC}"
for test_file in "$TEST_DIR"/integration/test_*.sh; do
    if [[ -f "$test_file" && -s "$test_file" ]]; then  # 空でないファイルのみ実行
        ((total_tests++))
        echo -e "\n${YELLOW}テストの実行: $(basename "$test_file")${NC}"
        
        # テスト環境のセットアップ
        setup_test_workspace
        
        # テストの実行
        if ! source "$test_file"; then
            ((failed_tests++))
            echo -e "${RED}✗ テスト失敗: $(basename "$test_file")${NC}"
        fi
        
        # テスト環境のクリーンアップ
        cleanup_test_workspace
    fi
done

# テスト結果の表示
echo -e "\n${YELLOW}テスト結果${NC}"
echo "総テスト数: $total_tests"
if [[ $failed_tests -eq 0 ]]; then
    echo -e "${GREEN}全テスト成功${NC}"
else
    echo -e "${RED}失敗: $failed_tests${NC}"
fi

# 終了コードの設定
exit $failed_tests 