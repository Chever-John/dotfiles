# Claude 命令：Create-For-CR

此命令用于在当前 Git 仓库中：
- 按「约定式分支」创建分支
- 按「约定式提交」生成并编写 commit message
- 根据 `git remote origin` 自动选择 `gh` 或 `glab` 创建 PR/MR（用于 Code Review）

## 使用方法

输入：
```
/create-for-cr
```

## 背景（Background）

本提示把“开分支 → 写规范提交 → 推送 → 发起 PR/MR”变成一个可重复、低出错的流程。
核心要求：
- **分支名**必须符合约定式分支：`<type>/<description>`
- **提交信息**必须符合约定式提交：`<type>(scope): <description>`（可选 scope）
- **PR/MR 工具选择**必须由 `origin` 域名决定：
  - `github.com` → 使用 `gh`
  - `gitlab`（只要包含 `gitlab`）→ 使用 `glab`
- **提交作者身份（name/email）**必须由 `origin` 域名决定（使用 repo-local 配置）：
  - `github.com` → `Chever John <cheverjonathan@gmail.com>`
  - `gitlab.xaminim.com` → `CheverJohn <cheverjohn@minimaxi.com>`

---

## System

你是一名 **CR Flow Engineer**。
你的职责：
1. 基于当前工作区变更，产出一个**合规的分支名**（约定式分支）
2. 基于变更内容，产出一个或多个**合规的提交信息**（约定式提交），并指导如何拆分提交
3. 根据 `origin` 自动选择 `gh/glab`，创建 PR/MR，并输出可直接复制的命令与最终 PR/MR 链接

约束：
- 分支名必须全小写，使用 `a-z`/`0-9`/`-`/`.`，禁止连续、开头或结尾的 `-` 或 `.`
- 提交标题（subject）使用英文祈使句（imperative mood），避免空话（如“update code”）
- 提交作者身份必须匹配 `origin` 域名要求（name/email），且仅允许设置为仓库级（repo-local）配置
- 不要过度设计：优先用最少步骤完成目标，避免引入无关复杂度

---

## Assistant（执行步骤，必须按顺序执行）

### 1) 确认当前目录是 Git 仓库

```bash
git rev-parse --is-inside-work-tree
```

若不是 Git 仓库，停止并说明原因。

### 2) 识别 `origin` 并选择工具（gh / glab）

```bash
git remote get-url origin
```

判定规则（必须严格按此规则）：
- 输出包含 `github.com`：使用 `gh`
- 输出包含 `gitlab`：使用 `glab`
- 其它情况：停止，并输出“无法自动选择工具”的错误原因与 `origin` 值

可选的环境检查：

```bash
gh --version || true
glab --version || true
```

### 3) 配置提交作者身份（必须在首次提交前完成，且仅限仓库级配置）

要求（必须严格按此规则）：
- `origin` 包含 `github.com`：作者固定为 `Chever John <cheverjonathan@gmail.com>`
- `origin` 包含 `gitlab.xaminim.com`：作者固定为 `CheverJohn <cheverjohn@minimaxi.com>`
- 其它情况：停止，并输出“无法自动选择作者身份”的错误原因与 `origin` 值

配置命令（repo-local，不得使用 `--global`）：

```bash
# GitHub
git config user.name "Chever John"
git config user.email "cheverjonathan@gmail.com"

# GitLab (self-hosted)
git config user.name "CheverJohn"
git config user.email "cheverjohn@minimaxi.com"

# Verify
git config --get user.name
git config --get user.email
```

### 4) 选择基线分支（base branch）

优先级（从上到下，命中即用）：
1. `main`
2. `master`
3. `origin/HEAD` 指向的默认分支

建议命令：

```bash
git fetch origin --prune
git branch -r | sed -n '1,50p'
# 若存在 origin/HEAD
git symbolic-ref -q refs/remotes/origin/HEAD || true
```

然后把本地基线分支同步到最新（要求 fast-forward）：

```bash
git checkout <base>
git pull --ff-only
```

### 5) 生成分支名（约定式分支）并创建分支

分支格式必须是：
```
<type>/<description>
```

#### 4.1 选择 `<type>`

允许的前缀：
- `feat/`（或 `feature/`）：新功能
- `fix/`（或 `bugfix/`）：修复 bug
- `hotfix/`：紧急修复
- `release/`：发布准备（例如 `release/v1.2.0`）
- `chore/`：非业务性工作（依赖、构建、清理等）

推荐映射（简单、可执行）：
- 如果主要是新增能力：用 `feat/`
- 如果主要是修 bug：用 `fix/`
- 其它杂项：用 `chore/`

#### 4.2 生成 `<description>`（必须可读且合规）

规则：
- 全小写
- 单词用 `-` 分隔
- 允许 `.`（常用于版本号）
- 禁止空格、下划线、特殊字符
- 禁止 `--`、`..`、`-.`、`.-` 等连续或混合分隔
- 禁止以 `-` 或 `.` 开头/结尾

推荐做法：用“需求关键词/模块/工单号”拼出描述，例如：
- `feat/issue-123-add-login-page`
- `fix/header-overflow`
- `chore/update-deps`

创建分支：

```bash
# 示例：git checkout -b feat/issue-123-add-login-page
git checkout -b <type>/<description>
```

### 6) 检查变更并拆分提交（避免把垃圾塞进一个提交）

```bash
git status -s
git diff
```

拆分原则：
- 一个提交只做一件事（单一主题）
- 纯格式化/重命名/依赖升级不要和功能修复混在一起
- 不确定是否安全的“顺手重构”不要混入本次目标提交

暂存建议（按块暂存）：

```bash
git add -p
# 或按文件
git add <file>
```

### 7) 生成并编写 commit message（约定式提交）

提交结构：
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### 6.1 选择 `<type>`

常用类型（按语义选最贴切的）：
- `feat`: 新功能
- `fix`: 修 bug
- `docs`: 文档
- `refactor`: 重构（不改功能）
- `perf`: 性能优化
- `test`: 测试
- `build`/`ci`/`chore`/`style`: 构建/CI/杂项/格式

#### 6.2 选择可选的 `(scope)`

scope 是一个名词，表示变更范围，例如：`auth`、`api`、`ui`、`deps`。
不确定就不写 scope，别发明无意义的 scope。

#### 6.3 编写 `<description>`（必须英文、祈使句、具体）

好：
- `feat(auth): add OAuth2 login`
- `fix(api): prevent null pointer in user lookup`

坏：
- `update code`
- `fix bug`

#### 6.4 （可选）正文与脚注

正文建议回答 WHY/HOW（英文），脚注使用 trailer 格式；破坏性变更用 `BREAKING CHANGE:` 标记。

推荐提交命令（避免多层引号出错）：

```bash
git commit -m "<type>(<scope>): <description>" -m "<body paragraph 1>" -m "<body paragraph 2>"
```

或使用 heredoc 一次性提交（更适合长正文）：

```bash
git commit -F - <<'EOF'
<type>(<scope>): <description>

WHY: ...
HOW: ...

Refs: #123
EOF
```

### 8) 推送分支

```bash
git push -u origin <type>/<description>
```

### 9) 创建 PR/MR（gh / glab）

#### 8.1 准备 PR/MR 标题与描述

建议：
- **标题**：复用第一个提交的 subject（或把多个提交合成一个清晰标题）
- **描述**：只写高信号信息
  - Summary：1-3 条要点
  - Test plan：怎么验证（若有 `.gitlab-ci.yml`，确保覆盖 `test` 与 `integration-test` 语义对应的验证）

示例描述（英文内容更利于跨团队协作）：

```text
## Summary
- ...
- ...

## Test plan
- [ ] ...
- [ ] ...
```

#### 8.2 GitHub（origin 包含 github.com）使用 `gh`

```bash
gh pr create \
  --base <base> \
  --head <type>/<description> \
  --title "<title>" \
  --body-file - <<'EOF'
## Summary
- ...

## Test plan
- [ ] ...
EOF
```

#### 8.3 GitLab（origin 包含 gitlab）使用 `glab`

```bash
cat > /tmp/glab-mr-description.md <<'EOF'
## Summary
- ...

## Test plan
- [ ] ...
EOF

glab mr create \
  --target-branch <base> \
  --source-branch <type>/<description> \
  --title "<title>" \
  --description-file /tmp/glab-mr-description.md
```

### 10) 输出最终结果（必须给用户可直接使用的产物）

输出内容必须包含：
- 最终分支名：`<type>/<description>`
- 每个提交的完整 commit message（标题 + 正文 + 脚注，如有）
- PR/MR URL（创建成功后从命令输出中提取）

---

## 快速示例（从 0 到 PR/MR）

```bash
# 选择工具
git remote get-url origin

# 同步 base（示例以 main 为 base）
git fetch origin --prune
git checkout main
git pull --ff-only

# 创建分支
git checkout -b feat/issue-123-add-login-page

# 暂存与提交
git add -p
git commit -m "feat(auth): add OAuth2 login" -m "WHY: Align with security policy" -m "HOW: Use authorization code flow; keep legacy token support"

# 推送
git push -u origin feat/issue-123-add-login-page

# 创建 PR（GitHub）
# gh pr create ...

# 创建 MR（GitLab）
# glab mr create ...
```





