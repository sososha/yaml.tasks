#!/bin/bash

# テストヘルパーの読み込み
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/test_helper.sh"

# テンプレート一覧表示のテスト
test_list_templates() {
    # テンプレート一覧の表示
    local output
    output=$(./task.sh template list)
    assert_equals "0" "$?" "テンプレート一覧の表示が成功すべき"
    assert_file_contains <(echo "$output") "default" "デフォルトテンプレートが表示されるべき"
}

# テンプレート内容表示のテスト
test_show_template() {
    # デフォルトテンプレートの内容表示
    local output
    output=$(./task.sh template show default)
    assert_equals "0" "$?" "テンプレート内容の表示が成功すべき"
    assert_file_contains <(echo "$output") "title:" "テンプレートにタイトルフィールドが含まれるべき"
    assert_file_contains <(echo "$output") "description:" "テンプレートに説明フィールドが含まれるべき"
}

# テンプレート使用のテスト
test_use_template() {
    # デフォルトテンプレートを使用
    assert_command_success "./task.sh template use default" "デフォルトテンプレートの使用"
    assert_yaml_path_equals "config/template_config.yaml" '.current_template' "default" "現在のテンプレートがデフォルトに設定されるべき"
    
    # カスタムテンプレートの作成とテスト
    mkdir -p templates/custom
    cat > templates/custom/task_template.yaml << 'EOF'
title: ""
description: ""
priority: high
due_date: ""
status: not_started
tags: []
custom_field: ""
EOF
    
    # カスタムテンプレートを使用
    assert_command_success "./task.sh template use custom" "カスタムテンプレートの使用"
    assert_yaml_path_equals "config/template_config.yaml" '.current_template' "custom" "現在のテンプレートがカスタムに設定されるべき"
}

# テンプレート設定のテスト
test_template_config() {
    # テンプレート設定の更新
    assert_command_success "./task.sh template config set custom_field 'test_value'" "テンプレート設定の更新"
    assert_yaml_path_equals "config/template_config.yaml" '.settings.custom_field' "test_value" "テンプレート設定が更新されるべき"
    
    # テンプレート設定の表示
    local output
    output=$(./task.sh template config show)
    assert_equals "0" "$?" "テンプレート設定の表示が成功すべき"
    assert_file_contains <(echo "$output") "custom_field: test_value" "更新された設定が表示されるべき"
}

# エラーケースのテスト
test_template_errors() {
    # 存在しないテンプレートの使用
    assert_command_fails "./task.sh template use nonexistent" "存在しないテンプレートの使用は失敗すべき"
    
    # 存在しないテンプレートの表示
    assert_command_fails "./task.sh template show nonexistent" "存在しないテンプレートの表示は失敗すべき"
    
    # 無効な設定キー
    assert_command_fails "./task.sh template config set invalid_key 'value'" "無効な設定キーは失敗すべき"
}

# テストの実行
test_list_templates
test_show_template
test_use_template
test_template_config
test_template_errors 