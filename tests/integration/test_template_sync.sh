#!/bin/bash

# テストヘルパーの読み込み
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/test_helper.sh"

# テンプレートと同期の統合テスト
test_template_and_sync() {
    # 1. カスタムテンプレートの作成
    mkdir -p templates/custom
    cat > templates/custom/task_template.yaml << 'EOF'
title: "{{ title }}"
description: "{{ description }}"
priority: "{{ priority }}"
status: "{{ status }}"
custom_field: "カスタム値"
EOF
    
    # 2. テンプレートの切り替え
    assert_command_success "./task.sh template use custom" "カスタムテンプレートに切り替え"
    assert_yaml_path_equals "config/template_config.yaml" '.current_template' "custom" "テンプレート設定の確認"
    
    # 3. タスクの作成
    assert_command_success "./task.sh add 'テンプレートテスト' -d '説明文' -p high" "テスト用タスクの作成"
    
    # 4. 同期の実行
    assert_command_success "./task.sh sync -f" "強制同期の実行"
    
    # 5. 生成されたファイルの確認
    assert_file_exists "tasks/project.tasks" "プロジェクトファイルの存在確認"
    assert_file_contains "tasks/project.tasks" "カスタム値" "カスタムフィールドの確認"
    
    # 6. テンプレート設定の変更
    assert_command_success "./task.sh template config custom_field '新しい値'" "テンプレート設定の変更"
    
    # 7. 再同期
    assert_command_success "./task.sh sync -f" "設定変更後の再同期"
    assert_file_contains "tasks/project.tasks" "新しい値" "更新されたカスタムフィールドの確認"
    
    # 8. バックアップ付き同期
    assert_command_success "./task.sh sync -b -f" "バックアップ付き同期"
    assert_file_exists "tasks/backup" "バックアップディレクトリの確認"
    
    # 9. デフォルトテンプレートに戻す
    assert_command_success "./task.sh template use default" "デフォルトテンプレートに戻す"
    assert_command_success "./task.sh sync -f" "テンプレート変更後の同期"
}

# エラー回復のテスト
test_template_sync_errors() {
    # 1. 無効なテンプレートの使用
    assert_command_fails "./task.sh template use nonexistent" "存在しないテンプレートの使用"
    
    # 2. 無効な設定キー
    assert_command_fails "./task.sh template config invalid_key 'value'" "無効な設定キーの使用"
    
    # 3. 同期の整合性チェック
    # タスクファイルを直接編集
    echo "invalid yaml" > tasks/tasks.yaml
    assert_command_fails "./task.sh sync" "破損したタスクファイルの同期"
    
    # 4. システムの回復
    # タスクファイルを復元
    echo "tasks: []" > tasks/tasks.yaml
    assert_command_success "./task.sh sync -f" "システム回復後の同期"
}

# テストの実行
test_template_and_sync
test_template_sync_errors 