#!/bin/bash

# 定义全局变量用于存储函数返回的多个值
ORB_SSH_SELECTOR_PROMPT=""
ORB_SSH_SELECTOR_MACHINE=""

# 函数：显示 OrbStack 机器列表并选择一个机器
select_orb_machine() {
  local machines

  # 使用 grep 和 awk 提取机器名，确保只提取 "running" 状态的机器
  machines=$(orbctl list | grep "running" | awk '{print $1}')

  if [[ -z "$machines" ]]; then
    echo "没有正在运行的 OrbStack 机器。"
    return 1
  fi

  local machine_array
  IFS=$'\n' read -rd '' -a machine_array <<< "$machines"

  # 显示机器列表供用户选择
  echo "请选择要登录的 OrbStack 机器："
  select machine in "${machine_array[@]}"; do
    if [[ -n "$machine" ]]; then
      # 使用 REPLY 变量获取选择的机器名在 machine_array 数组中的索引
      local selected_index=$REPLY

      # 使用索引获取实际的机器名
      local selected_machine="${machine_array[selected_index-1]}"

      # 设置全局变量
      ORB_SSH_SELECTOR_PROMPT="请选择要登录的 OrbStack 机器： $machine"
      ORB_SSH_SELECTOR_MACHINE="$selected_machine"

      echo "$ORB_SSH_SELECTOR_MACHINE" # 函数的标准输出仍然是机器名，保持兼容性
      return 0
    else
      echo "无效的选择，请重试。"
    fi
  done

  # 如果没有选择任何机器，则返回 1
  return 1
}

# 主程序
select_orb_machine

# 检查 select_orb_machine 函数的返回值
if [[ "$?" -ne "0" ]]; then
  echo "未能选择 OrbStack 机器。"
  exit 1
fi

# 从全局变量获取选择的机器名
selected_machine="$ORB_SSH_SELECTOR_MACHINE"
selected_prompt="$ORB_SSH_SELECTOR_PROMPT"

echo "Prompt: $selected_prompt"
echo "Machine: $selected_machine"

if [[ -n "$selected_machine" ]]; then
  # 使用 SSH 登录到选择的机器
  ssh "root@${selected_machine}@orb"
else
  echo "未能选择 OrbStack 机器。"
  exit 1
fi

exit 0