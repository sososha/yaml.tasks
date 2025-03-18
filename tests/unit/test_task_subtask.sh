#!/bin/bash

# テストヘルパーの読み込み
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/test_helper.sh"

# サブタスク追加のテスト
test_add_subtask() {
    # 親タスクの作成
    assert_command_success "./task.sh add '親タスク1'" "親タスクの作成"
    local parent_id
    parent_id=$(yq eval '.tasks[0].id' tasks/tasks.yaml)
    
    # 基本的なサブタスク追加のテスト
    assert_command_success "./task.sh subtask $parent_id 'サブタスク1'" "基本的なサブタスク追加"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].subtasks[0].title' "サブタスク1" "サブタスクタイトルの確認"
    
    # 説明付きのサブタスク追加のテスト
    assert_command_success "./task.sh subtask $parent_id 'サブタスク2' -d '説明文'" "説明付きのサブタスク追加"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].subtasks[1].description' "説明文" "サブタスク説明の確認"
    
    # 優先度付きのサブタスク追加のテスト
    assert_command_success "./task.sh subtask $parent_id 'サブタスク3' -p high" "優先度付きのサブタスク追加"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].subtasks[2].priority' "high" "サブタスク優先度の確認"
    
    # 期限付きのサブタスク追加のテスト
    assert_command_success "./task.sh subtask $parent_id 'サブタスク4' -D '2024-12-31'" "期限付きのサブタスク追加"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].subtasks[3].due_date' "2024-12-31" "サブタスク期限の確認"
    
    # 複数オプション付きのサブタスク追加のテスト
    assert_command_success "./task.sh subtask $parent_id 'サブタスク5' -d '説明文' -p high -D '2024-12-31'" "複数オプション付きのサブタスク追加"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].subtasks[4].title' "サブタスク5" "複合サブタスクのタイトル確認"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].subtasks[4].description' "説明文" "複合サブタスクの説明確認"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].subtasks[4].priority' "high" "複合サブタスクの優先度確認"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].subtasks[4].due_date' "2024-12-31" "複合サブタスクの期限確認"
}

# エラーケースのテスト
test_add_subtask_errors() {
    # 親タスクの作成
    assert_command_success "./task.sh add '親タスク2'" "エラーテスト用の親タスク作成"
    local parent_id
    parent_id=$(yq eval '.tasks[1].id' tasks/tasks.yaml)
    
    # 親タスクIDなしのテスト
    assert_command_fails "./task.sh subtask" "親タスクIDなしの追加は失敗すべき"
    
    # 無効な親タスクIDのテスト
    assert_command_fails "./task.sh subtask invalid-id 'サブタスク'" "無効な親タスクIDは失敗すべき"
    
    # タイトルなしのテスト
    assert_command_fails "./task.sh subtask $parent_id" "タイトルなしの追加は失敗すべき"
    
    # 無効な優先度のテスト
    assert_command_fails "./task.sh subtask $parent_id 'エラーサブタスク' -p invalid" "無効な優先度は失敗すべき"
    
    # 無効な日付形式のテスト
    assert_command_fails "./task.sh subtask $parent_id 'エラーサブタスク' -D 'invalid-date'" "無効な日付形式は失敗すべき"
}

# テストの実行
test_add_subtask
test_add_subtask_errors 