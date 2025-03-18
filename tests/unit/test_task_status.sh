#!/bin/bash

# テストヘルパーの読み込み
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/test_helper.sh"

# ステータス変更のテスト
test_change_status() {
    # テスト用のタスクを作成
    assert_command_success "./task.sh add 'ステータステスト1'" "テスト用タスクの作成"
    local task_id
    task_id=$(yq eval '.tasks[0].id' tasks/tasks.yaml)
    
    # 進行中に変更
    assert_command_success "./task.sh status $task_id in_progress" "タスクを進行中に変更"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].status' "in_progress" "進行中ステータスの確認"
    
    # 完了に変更
    assert_command_success "./task.sh status $task_id done" "タスクを完了に変更"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].status' "done" "完了ステータスの確認"
    
    # 未着手に戻す
    assert_command_success "./task.sh status $task_id not_started" "タスクを未着手に変更"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[0].status' "not_started" "未着手ステータスの確認"
}

# サブタスクのステータス変更のテスト
test_change_subtask_status() {
    # 親タスクの作成
    assert_command_success "./task.sh add '親タスク'" "親タスクの作成"
    local parent_id
    parent_id=$(yq eval '.tasks[1].id' tasks/tasks.yaml)
    
    # サブタスクの追加
    assert_command_success "./task.sh subtask $parent_id 'サブタスク1'" "サブタスクの作成"
    local subtask_id
    subtask_id=$(yq eval '.tasks[1].subtasks[0].id' tasks/tasks.yaml)
    
    # サブタスクのステータス変更
    assert_command_success "./task.sh status $subtask_id in_progress" "サブタスクを進行中に変更"
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[1].subtasks[0].status' "in_progress" "サブタスクの進行中ステータスの確認"
    
    # 親タスクのステータスが自動更新されることを確認
    assert_yaml_path_equals "tasks/tasks.yaml" '.tasks[1].status' "in_progress" "親タスクのステータス自動更新の確認"
}

# エラーケースのテスト
test_change_status_errors() {
    # タスクIDなしのテスト
    assert_command_fails "./task.sh status" "タスクIDなしの変更は失敗すべき"
    
    # 無効なタスクIDのテスト
    assert_command_fails "./task.sh status invalid-id done" "無効なタスクIDは失敗すべき"
    
    # ステータスなしのテスト
    assert_command_fails "./task.sh status task-1" "ステータスなしの変更は失敗すべき"
    
    # 無効なステータスのテスト
    assert_command_fails "./task.sh status task-1 invalid_status" "無効なステータスは失敗すべき"
}

# テストの実行
test_change_status
test_change_subtask_status
test_change_status_errors 