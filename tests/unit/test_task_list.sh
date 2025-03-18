#!/bin/bash

# テストヘルパーの読み込み
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/test_helper.sh"

# テスト用のタスクデータを準備
setup_test_tasks() {
    # 親タスクの作成
    assert_command_success "./task.sh add '親タスク1' -d '説明1' -p high -D '2024-12-31'" "親タスク1の作成"
    local parent1_id
    parent1_id=$(yq eval '.tasks[0].id' tasks/tasks.yaml)
    
    # サブタスクの追加
    assert_command_success "./task.sh subtask $parent1_id 'サブタスク1.1' -d '説明1.1'" "サブタスク1.1の作成"
    assert_command_success "./task.sh subtask $parent1_id 'サブタスク1.2' -d '説明1.2'" "サブタスク1.2の作成"
    
    # 2つ目の親タスクの作成
    assert_command_success "./task.sh add '親タスク2' -d '説明2' -p normal" "親タスク2の作成"
    local parent2_id
    parent2_id=$(yq eval '.tasks[1].id' tasks/tasks.yaml)
    
    # ステータスの変更
    assert_command_success "./task.sh status $parent1_id in_progress" "親タスク1を進行中に変更"
    assert_command_success "./task.sh status $parent2_id done" "親タスク2を完了に変更"
}

# 基本的なリスト表示のテスト
test_basic_list() {
    # 全タスクの表示
    local output
    output=$(./task.sh list)
    assert_equals "0" "$?" "基本的なリスト表示が成功すべき"
    assert_file_contains <(echo "$output") "親タスク1" "親タスク1が表示されるべき"
    assert_file_contains <(echo "$output") "親タスク2" "親タスク2が表示されるべき"
}

# フィルタリングオプションのテスト
test_list_filtering() {
    # 進行中のタスクのみ表示
    local output
    output=$(./task.sh list -i)
    assert_equals "0" "$?" "進行中タスクの表示が成功すべき"
    assert_file_contains <(echo "$output") "親タスク1" "進行中の親タスク1が表示されるべき"
    
    # 完了タスクのみ表示
    output=$(./task.sh list -c)
    assert_equals "0" "$?" "完了タスクの表示が成功すべき"
    assert_file_contains <(echo "$output") "親タスク2" "完了した親タスク2が表示されるべき"
    
    # 親タスクのみ表示
    output=$(./task.sh list -p)
    assert_equals "0" "$?" "親タスクのみの表示が成功すべき"
    assert_file_contains <(echo "$output") "親タスク1" "親タスク1が表示されるべき"
    assert_file_contains <(echo "$output") "親タスク2" "親タスク2が表示されるべき"
}

# 検索機能のテスト
test_list_search() {
    # タイトルでの検索
    local output
    output=$(./task.sh list -s "タスク1")
    assert_equals "0" "$?" "タイトル検索が成功すべき"
    assert_file_contains <(echo "$output") "親タスク1" "検索結果に親タスク1が含まれるべき"
    
    # 説明での検索
    output=$(./task.sh list -s "説明2")
    assert_equals "0" "$?" "説明文での検索が成功すべき"
    assert_file_contains <(echo "$output") "親タスク2" "検索結果に親タスク2が含まれるべき"
}

# 出力フォーマットのテスト
test_list_format() {
    # 詳細フォーマットでの表示
    local output
    output=$(./task.sh list -f detailed)
    assert_equals "0" "$?" "詳細フォーマットでの表示が成功すべき"
    assert_file_contains <(echo "$output") "説明1" "詳細表示に説明1が含まれるべき"
    assert_file_contains <(echo "$output") "high" "詳細表示に優先度が含まれるべき"
    assert_file_contains <(echo "$output") "2024-12-31" "詳細表示に期限が含まれるべき"
}

# エラーケースのテスト
test_list_errors() {
    # 無効なフォーマットオプション
    assert_command_fails "./task.sh list -f invalid" "無効なフォーマットオプションは失敗すべき"
}

# テストの実行
setup_test_tasks
test_basic_list
test_list_filtering
test_list_search
test_list_format
test_list_errors 