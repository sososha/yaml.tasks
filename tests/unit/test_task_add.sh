#!/bin/bash

# テストヘルパーの読み込み
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/test_helper.sh"

# タスク追加のテスト
test_add_task() {
    # 基本的なタスク追加のテスト
    assert_command_success "./task.sh add 'テストタスク1'" "基本的なタスク追加"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].title' "テストタスク1" "タスクタイトルの確認"
    
    # 説明付きのタスク追加のテスト
    assert_command_success "./task.sh add 'テストタスク2' -d '説明文'" "説明付きのタスク追加"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[1].description' "説明文" "タスク説明の確認"
    
    # 優先度付きのタスク追加のテスト
    assert_command_success "./task.sh add 'テストタスク3' -p high" "優先度付きのタスク追加"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[2].priority' "high" "タスク優先度の確認"
    
    # 期限付きのタスク追加のテスト
    assert_command_success "./task.sh add 'テストタスク4' -D '2024-12-31'" "期限付きのタスク追加"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[3].due_date' "2024-12-31" "タスク期限の確認"
    
    # 複数オプション付きのタスク追加のテスト
    assert_command_success "./task.sh add 'テストタスク5' -d '説明文' -p high -D '2024-12-31'" "複数オプション付きのタスク追加"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[4].title' "テストタスク5" "複合タスクのタイトル確認"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[4].description' "説明文" "複合タスクの説明確認"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[4].priority' "high" "複合タスクの優先度確認"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[4].due_date' "2024-12-31" "複合タスクの期限確認"
}

# エラーケースのテスト
test_add_task_errors() {
    # タイトルなしのテスト
    assert_command_fails "./task.sh add" "タイトルなしの追加は失敗すべき"
    
    # 無効な優先度のテスト
    assert_command_fails "./task.sh add 'エラータスク' -p invalid" "無効な優先度は失敗すべき"
    
    # 無効な日付形式のテスト
    assert_command_fails "./task.sh add 'エラータスク' -D 'invalid-date'" "無効な日付形式は失敗すべき"
}

# テストの実行
test_add_task
test_add_task_errors 