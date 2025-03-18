#!/bin/bash

# テストヘルパーの読み込み
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/test_helper.sh"

# 基本的なワークフローのテスト
test_basic_workflow() {
    # 1. タスクの作成
    assert_command_success "./task.sh add '統合テストタスク1' -d '説明1' -p high" "親タスク1の作成"
    local parent1_id
    parent1_id=$(yq eval '.tasks[0].id' tasks/tasks.yaml)
    
    # 2. サブタスクの追加
    assert_command_success "./task.sh subtask $parent1_id 'サブタスク1.1' -d '説明1.1'" "サブタスク1の作成"
    assert_command_success "./task.sh subtask $parent1_id 'サブタスク1.2' -d '説明1.2'" "サブタスク2の作成"
    
    # 3. タスク一覧の確認
    local output
    output=$(./task.sh list -f detailed)
    assert_file_contains <(echo "$output") "統合テストタスク1" "親タスクが表示されるべき"
    assert_file_contains <(echo "$output") "サブタスク1.1" "サブタスク1が表示されるべき"
    assert_file_contains <(echo "$output") "サブタスク1.2" "サブタスク2が表示されるべき"
    
    # 4. サブタスクのステータス変更
    local subtask1_id
    subtask1_id=$(yq eval '.tasks[0].subtasks[0].id' tasks/tasks.yaml)
    assert_command_success "./task.sh status $subtask1_id in_progress" "サブタスク1を進行中に変更"
    
    # 5. 親タスクのステータスが自動更新されることを確認
    output=$(./task.sh list -f detailed)
    assert_file_contains <(echo "$output") "in_progress" "親タスクのステータスが更新されるべき"
    
    # 6. テンプレートの変更
    assert_command_success "./task.sh template use default" "デフォルトテンプレートに変更"
    
    # 7. 同期の実行
    assert_command_success "./task.sh sync -f" "タスクの同期"
    assert_file_exists "tasks/project.tasks" "同期後にプロジェクトファイルが存在するべき"
    
    # 8. 2つ目のタスクの作成と完了
    assert_command_success "./task.sh add '統合テストタスク2' -d '説明2'" "親タスク2の作成"
    local parent2_id
    parent2_id=$(yq eval '.tasks[1].id' tasks/tasks.yaml)
    assert_command_success "./task.sh status $parent2_id done" "親タスク2を完了に変更"
    
    # 9. フィルタリングの確認
    # 進行中のタスク
    output=$(./task.sh list -i)
    assert_file_contains <(echo "$output") "統合テストタスク1" "進行中タスクのフィルタリング"
    
    # 完了タスク
    output=$(./task.sh list -c)
    assert_file_contains <(echo "$output") "統合テストタスク2" "完了タスクのフィルタリング"
    
    # 10. 最終同期
    assert_command_success "./task.sh sync -b -f" "バックアップを作成して同期"
    assert_file_exists "tasks/backup" "バックアップディレクトリが作成されるべき"
}

# エラー回復のテスト
test_error_recovery() {
    # 1. 無効なコマンドの実行
    assert_command_fails "./task.sh invalid_command" "無効なコマンドは失敗すべき"
    
    # 2. 無効なタスクIDでのステータス変更
    assert_command_fails "./task.sh status invalid_id done" "無効なタスクIDでのステータス変更は失敗すべき"
    
    # 3. 存在しないテンプレートの使用
    assert_command_fails "./task.sh template use nonexistent" "存在しないテンプレートの使用は失敗すべき"
    
    # 4. システムが正常に動作し続けることを確認
    assert_command_success "./task.sh list" "エラー後もリスト表示は機能するべき"
    assert_command_success "./task.sh sync -c" "エラー後も同期チェックは機能するべき"
}

# テストの実行
test_basic_workflow
test_error_recovery 