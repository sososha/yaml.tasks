#!/bin/bash

# テストヘルパーの読み込み
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/test_helper.sh"

# 同期状態チェックのテスト
test_check_sync_status() {
    # 初期状態のチェック
    local output
    output=$(./task.sh sync -c)
    assert_equals "0" "$?" "同期状態チェックが成功すべき"
    assert_file_contains <(echo "$output") "同期が必要です" "初期状態では同期が必要と表示されるべき"
}

# 同期実行のテスト
test_perform_sync() {
    # テスト用のタスクを作成
    assert_command_success "./task.sh add 'テストタスク1'" "テスト用タスクの作成"
    
    # 強制同期の実行
    assert_command_success "./task.sh sync -f" "強制同期の実行"
    
    # 同期後のファイル存在確認
    assert_file_exists "tasks/project.tasks" "同期後にproject.tasksファイルが存在するべき"
    
    # 同期ハッシュの確認
    assert_file_exists "config/last_sync" "同期ハッシュファイルが存在するべき"
    
    # 再度同期状態をチェック
    local output
    output=$(./task.sh sync -c)
    assert_file_contains <(echo "$output") "同期済みです" "同期後は同期済みと表示されるべき"
}

# バックアップ作成のテスト
test_create_backup() {
    # バックアップ付きで同期を実行
    assert_command_success "./task.sh sync -b" "バックアップ付き同期の実行"
    
    # バックアップファイルの存在確認
    local backup_files
    backup_files=$(find tasks/backup -name "tasks_*.yaml" 2>/dev/null)
    assert_equals "0" "$?" "バックアップファイルの検索が成功すべき"
    assert_file_contains <(echo "$backup_files") "tasks_" "バックアップファイルが作成されるべき"
    
    backup_files=$(find tasks/backup -name "project_*.tasks" 2>/dev/null)
    assert_equals "0" "$?" "バックアップファイルの検索が成功すべき"
    assert_file_contains <(echo "$backup_files") "project_" "プロジェクトファイルのバックアップが作成されるべき"
}

# タスクファイル変更後の同期テスト
test_sync_after_changes() {
    # タスクの追加
    assert_command_success "./task.sh add 'テストタスク2'" "新しいタスクの追加"
    
    # 同期状態のチェック
    local output
    output=$(./task.sh sync -c)
    assert_file_contains <(echo "$output") "同期が必要です" "タスク追加後は同期が必要と表示されるべき"
    
    # 同期の実行
    assert_command_success "./task.sh sync -f" "変更後の同期実行"
    
    # 同期後の状態チェック
    output=$(./task.sh sync -c)
    assert_file_contains <(echo "$output") "同期済みです" "再同期後は同期済みと表示されるべき"
}

# エラーケースのテスト
test_sync_errors() {
    # タスクファイルが存在しない場合
    mv tasks/tasks.yaml tasks/tasks.yaml.bak
    assert_command_fails "./task.sh sync" "タスクファイルが存在しない場合は失敗すべき"
    mv tasks/tasks.yaml.bak tasks/tasks.yaml
    
    # 無効なオプションの組み合わせ
    assert_command_fails "./task.sh sync -c -f" "チェックと強制オプションの組み合わせは失敗すべき"
}

# テストの実行
test_check_sync_status
test_perform_sync
test_create_backup
test_sync_after_changes
test_sync_errors 