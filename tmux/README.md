# Tmux

Everyone should have a tmux:)

## Tmux Popup Pane

## Tmux list keys

我运行 `tmux list-keys` 会出现下面很多的结果。那么根据

### 按键表（Key Tables）

tmux 中的按键绑定根据不同的模式被组织到不同的表中 [1](https://www.seanh.cc/2020/12/28/binding-keys-in-tmux/):

- **-T prefix**: 需要先按前缀键（默认为 Ctrl+b）后再按的按键
- **-T root**: 直接按即可生效的按键（不需要前缀）
- **-T copy-mode**: 在复制模式下使用的 emacs 风格按键
- **-T copy-mode-vi**: 在复制模式下使用的 vi 风格按键
- **-T edit-mode-vi**: 编辑模式下的 vi 风格按键

### 功能分类

#### 会话管理 (Session Management)

- 创建、重命名会话: `prefix + $` 重命名当前会话
- 切换会话: `prefix + (` 切换到上一个会话，`prefix + )` 切换到下一个会话
- 分离会话: `prefix + d` 从当前会话分离

#### 窗口管理 (Window Management)

- 创建窗口: `prefix + c` 在当前路径创建新窗口 [3](https://gist.github.com/MohamedAlaa/2961058)
- 切换窗口: `prefix + n` 下一个窗口，`prefix + p` 上一个窗口，`prefix + 0-9` 切换到指定窗口
- 重命名窗口: `prefix + ,` 重命名当前窗口
- 查找窗口: `prefix + f` 查找窗口
- 关闭窗口: `prefix + &` 关闭当前窗口
- 窗口布局: `prefix + Space` 切换窗口布局

#### 面板管理 (Pane Management)

- 分割面板: `prefix + "` 水平分割，`prefix + %` 垂直分割 [5](https://www.redhat.com/en/blog/introduction-tmux-linux)
- 导航面板: `prefix + h/j/k/l` 在左/下/上/右面板之间移动
- 调整大小: `prefix + H/J/K/L` 调整面板大小
- 关闭面板: `prefix + x` 关闭当前面板
- 切换布局: `prefix + Space` 切换面板布局
- 缩放面板: `prefix + z` 最大化/还原当前面板

#### 复制模式操作 (Copy Mode)

- 进入复制模式: `prefix + [`
- 文本选择: 在 copy-mode-vi 中使用 `v` 开始选择，`V` 选择整行
- 复制文本: 在选择后使用 `y` 复制到系统剪贴板
- 搜索: `/` 向前搜索，`?` 向后搜索，`n` 继续搜索

#### 缓冲区管理 (Buffer Management)

- 列出缓冲区: `prefix + #` 列出所有缓冲区
- 粘贴缓冲区: `prefix + ]` 粘贴最近的缓冲区内容

#### 命令和控制 (Command and Control)

- 执行命令: `prefix + :` 打开命令提示符
- 显示帮助: `prefix + ?` 列出所有按键绑定
- 重新加载配置: `prefix + r` 重新加载 tmux 配置文件
- 时钟模式: `prefix + t` 显示时钟

#### 鼠标操作 (Mouse Operations)

- 选择面板: MouseDown1Pane 点击选择面板
- 选择窗口: MouseDown1Status 点击状态栏选择窗口
- 调整面板大小: MouseDrag1Border 拖动边界调整面板大小
- 上下文菜单: MouseDown3Pane 右键点击打开上下文菜单

```shell
dotfilesgit:(chore/update-alacritty-to-change-tmux-windows*)$ tmux list-keys
bind-key    -T copy-mode    Escape                 send-keys -X cancel
bind-key    -T copy-mode    Space                  send-keys -X page-down
bind-key    -T copy-mode    !                      send-keys -X copy-pipe-and-cancel "tr -d '\n' | reattach-to-user-namespace pbcopy"
bind-key    -T copy-mode    ,                      send-keys -X jump-reverse
bind-key    -T copy-mode    \;                     send-keys -X jump-again
bind-key    -T copy-mode    F                      command-prompt -1 -p "(jump backward)" { send-keys -X jump-backward "%%" }
bind-key    -T copy-mode    N                      send-keys -X search-reverse
bind-key    -T copy-mode    P                      send-keys -X toggle-position
bind-key    -T copy-mode    R                      send-keys -X rectangle-toggle
bind-key    -T copy-mode    T                      command-prompt -1 -p "(jump to backward)" { send-keys -X jump-to-backward "%%" }
bind-key    -T copy-mode    X                      send-keys -X set-mark
bind-key    -T copy-mode    Y                      send-keys -X copy-pipe-and-cancel "tmux paste-buffer -p"
bind-key    -T copy-mode    f                      command-prompt -1 -p "(jump forward)" { send-keys -X jump-forward "%%" }
bind-key    -T copy-mode    g                      command-prompt -p "(goto line)" { send-keys -X goto-line "%%" }
bind-key    -T copy-mode    n                      send-keys -X search-again
bind-key    -T copy-mode    o                      send-keys -X copy-pipe-and-cancel "sed s/##/####/g | xargs -I {} tmux run-shell -b 'cd #{pane_current_path}; open \"{}\" > /dev/null'"
bind-key    -T copy-mode    q                      send-keys -X cancel
bind-key    -T copy-mode    r                      send-keys -X refresh-from-pane
bind-key    -T copy-mode    t                      send-keys -X copy-pipe-and-cancel tmux-vocab
bind-key    -T copy-mode    y                      send-keys -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy"
bind-key    -T copy-mode    MouseDown1Pane         select-pane
bind-key    -T copy-mode    MouseDrag1Pane         select-pane \; send-keys -X begin-selection
bind-key    -T copy-mode    MouseDragEnd1Pane      send-keys -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy"
bind-key    -T copy-mode    WheelUpPane            select-pane \; send-keys -X -N 5 scroll-up
bind-key    -T copy-mode    WheelDownPane          select-pane \; send-keys -X -N 5 scroll-down
bind-key    -T copy-mode    DoubleClick1Pane       select-pane \; send-keys -X select-word \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel
bind-key    -T copy-mode    TripleClick1Pane       select-pane \; send-keys -X select-line \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel
bind-key    -T copy-mode    Home                   send-keys -X start-of-line
bind-key    -T copy-mode    End                    send-keys -X end-of-line
bind-key    -T copy-mode    NPage                  send-keys -X page-down
bind-key    -T copy-mode    PPage                  send-keys -X page-up
bind-key    -T copy-mode    Up                     send-keys -X cursor-up
bind-key    -T copy-mode    Down                   send-keys -X cursor-down
bind-key    -T copy-mode    Left                   send-keys -X cursor-left
bind-key    -T copy-mode    Right                  send-keys -X cursor-right
bind-key    -T copy-mode    M-1                    command-prompt -N -I 1 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode    M-2                    command-prompt -N -I 2 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode    M-3                    command-prompt -N -I 3 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode    M-4                    command-prompt -N -I 4 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode    M-5                    command-prompt -N -I 5 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode    M-6                    command-prompt -N -I 6 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode    M-7                    command-prompt -N -I 7 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode    M-8                    command-prompt -N -I 8 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode    M-9                    command-prompt -N -I 9 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode    M-<                    send-keys -X history-top
bind-key    -T copy-mode    M->                    send-keys -X history-bottom
bind-key    -T copy-mode    M-R                    send-keys -X top-line
bind-key    -T copy-mode    M-b                    send-keys -X previous-word
bind-key    -T copy-mode    M-f                    send-keys -X next-word-end
bind-key    -T copy-mode    M-m                    send-keys -X back-to-indentation
bind-key    -T copy-mode    M-r                    send-keys -X middle-line
bind-key    -T copy-mode    M-v                    send-keys -X page-up
bind-key    -T copy-mode    M-w                    send-keys -X copy-pipe-and-cancel
bind-key    -T copy-mode    M-x                    send-keys -X jump-to-mark
bind-key    -T copy-mode    M-y                    send-keys -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy; tmux paste-buffer -p"
bind-key    -T copy-mode    "M-{"                  send-keys -X previous-paragraph
bind-key    -T copy-mode    "M-}"                  send-keys -X next-paragraph
bind-key    -T copy-mode    M-Up                   send-keys -X halfpage-up
bind-key    -T copy-mode    M-Down                 send-keys -X halfpage-down
bind-key    -T copy-mode    C-Space                send-keys -X begin-selection
bind-key    -T copy-mode    C-a                    send-keys -X start-of-line
bind-key    -T copy-mode    C-b                    send-keys -X cursor-left
bind-key    -T copy-mode    C-c                    send-keys -X cancel
bind-key    -T copy-mode    C-e                    send-keys -X end-of-line
bind-key    -T copy-mode    C-f                    send-keys -X cursor-right
bind-key    -T copy-mode    C-g                    send-keys -X clear-selection
bind-key    -T copy-mode    C-k                    send-keys -X copy-pipe-end-of-line-and-cancel
bind-key    -T copy-mode    C-n                    send-keys -X cursor-down
bind-key    -T copy-mode    C-o                    send-keys -X copy-pipe-and-cancel "sed s/##/####/g | xargs -I {} tmux send-keys 'vi -- \"{}\"'; tmux send-keys 'C-m'"
bind-key    -T copy-mode    C-p                    send-keys -X cursor-up
bind-key    -T copy-mode    C-r                    command-prompt -i -I "#{pane_search_string}" -T search -p "(search up)" { send-keys -X search-backward-incremental "%%" }
bind-key    -T copy-mode    C-s                    command-prompt -i -I "#{pane_search_string}" -T search -p "(search down)" { send-keys -X search-forward-incremental "%%" }
bind-key    -T copy-mode    C-v                    send-keys -X page-down
bind-key    -T copy-mode    C-w                    send-keys -X copy-pipe-and-cancel
bind-key    -T copy-mode    C-Up                   send-keys -X scroll-up
bind-key    -T copy-mode    C-Down                 send-keys -X scroll-down
bind-key    -T copy-mode    C-M-b                  send-keys -X previous-matching-bracket
bind-key    -T copy-mode    C-M-f                  send-keys -X next-matching-bracket
bind-key    -T copy-mode-vi Escape                 send-keys -X clear-selection
bind-key    -T copy-mode-vi !                      send-keys -X copy-pipe-and-cancel "tr -d '\n' | reattach-to-user-namespace pbcopy"
bind-key    -T copy-mode-vi \#                     send-keys -FX search-backward "#{copy_cursor_word}"
bind-key    -T copy-mode-vi \$                     send-keys -X end-of-line
bind-key    -T copy-mode-vi \%                     send-keys -X next-matching-bracket
bind-key    -T copy-mode-vi *                      send-keys -FX search-forward "#{copy_cursor_word}"
bind-key    -T copy-mode-vi ,                      send-keys -X jump-reverse
bind-key    -T copy-mode-vi /                      command-prompt -T search -p "(search down)" { send-keys -X search-forward "%%" }
bind-key    -T copy-mode-vi 0                      send-keys -X start-of-line
bind-key    -T copy-mode-vi 1                      command-prompt -N -I 1 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode-vi 2                      command-prompt -N -I 2 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode-vi 3                      command-prompt -N -I 3 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode-vi 4                      command-prompt -N -I 4 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode-vi 5                      command-prompt -N -I 5 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode-vi 6                      command-prompt -N -I 6 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode-vi 7                      command-prompt -N -I 7 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode-vi 8                      command-prompt -N -I 8 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode-vi 9                      command-prompt -N -I 9 -p (repeat) { send-keys -N "%%" }
bind-key    -T copy-mode-vi :                      command-prompt -p "(goto line)" { send-keys -X goto-line "%%" }
bind-key    -T copy-mode-vi \;                     send-keys -X jump-again
bind-key    -T copy-mode-vi ?                      command-prompt -T search -p "(search up)" { send-keys -X search-backward "%%" }
bind-key    -T copy-mode-vi A                      send-keys -X append-selection-and-cancel
bind-key    -T copy-mode-vi B                      send-keys -X previous-space
bind-key    -T copy-mode-vi D                      send-keys -X copy-pipe-end-of-line-and-cancel
bind-key    -T copy-mode-vi E                      send-keys -X next-space-end
bind-key    -T copy-mode-vi F                      command-prompt -1 -p "(jump backward)" { send-keys -X jump-backward "%%" }
bind-key    -T copy-mode-vi G                      send-keys -X history-bottom
bind-key    -T copy-mode-vi H                      send-keys -X top-line
bind-key    -T copy-mode-vi J                      send-keys -X scroll-down
bind-key    -T copy-mode-vi K                      send-keys -X scroll-up
bind-key    -T copy-mode-vi L                      send-keys -X bottom-line
bind-key    -T copy-mode-vi M                      send-keys -X middle-line
bind-key    -T copy-mode-vi N                      send-keys -X search-reverse
bind-key    -T copy-mode-vi P                      send-keys -X toggle-position
bind-key    -T copy-mode-vi T                      command-prompt -1 -p "(jump to backward)" { send-keys -X jump-to-backward "%%" }
bind-key    -T copy-mode-vi V                      send-keys -X select-line
bind-key    -T copy-mode-vi W                      send-keys -X next-space
bind-key    -T copy-mode-vi X                      send-keys -X set-mark
bind-key    -T copy-mode-vi Y                      send-keys -X copy-pipe-and-cancel "tmux paste-buffer -p"
bind-key    -T copy-mode-vi ^                      send-keys -X back-to-indentation
bind-key    -T copy-mode-vi b                      send-keys -X previous-word
bind-key    -T copy-mode-vi e                      send-keys -X next-word-end
bind-key    -T copy-mode-vi f                      command-prompt -1 -p "(jump forward)" { send-keys -X jump-forward "%%" }
bind-key    -T copy-mode-vi g                      send-keys -X history-top
bind-key    -T copy-mode-vi h                      send-keys -X cursor-left
bind-key    -T copy-mode-vi j                      send-keys -X cursor-down
bind-key    -T copy-mode-vi k                      send-keys -X cursor-up
bind-key    -T copy-mode-vi l                      send-keys -X cursor-right
bind-key    -T copy-mode-vi n                      send-keys -X search-again
bind-key    -T copy-mode-vi o                      send-keys -X copy-pipe-and-cancel "sed s/##/####/g | xargs -I {} tmux run-shell -b 'cd #{pane_current_path}; open \"{}\" > /dev/null'"
bind-key    -T copy-mode-vi q                      send-keys -X cancel
bind-key    -T copy-mode-vi r                      send-keys -X refresh-from-pane
bind-key    -T copy-mode-vi t                      send-keys -X copy-pipe-and-cancel tmux-vocab
bind-key    -T copy-mode-vi v                      send-keys -X begin-selection
bind-key    -T copy-mode-vi w                      send-keys -X next-word
bind-key    -T copy-mode-vi y                      send-keys -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy"
bind-key    -T copy-mode-vi z                      send-keys -X scroll-middle
bind-key    -T copy-mode-vi \{                     send-keys -X previous-paragraph
bind-key    -T copy-mode-vi \}                     send-keys -X next-paragraph
bind-key    -T copy-mode-vi MouseDown1Pane         select-pane
bind-key    -T copy-mode-vi MouseDrag1Pane         select-pane \; send-keys -X begin-selection
bind-key    -T copy-mode-vi MouseDragEnd1Pane      send-keys -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy"
bind-key    -T copy-mode-vi WheelUpPane            select-pane \; send-keys -X -N 5 scroll-up
bind-key    -T copy-mode-vi WheelDownPane          select-pane \; send-keys -X -N 5 scroll-down
bind-key    -T copy-mode-vi DoubleClick1Pane       select-pane \; send-keys -X select-word \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel
bind-key    -T copy-mode-vi TripleClick1Pane       select-pane \; send-keys -X select-line \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel
bind-key    -T copy-mode-vi BSpace                 send-keys -X cursor-left
bind-key    -T copy-mode-vi Home                   send-keys -X start-of-line
bind-key    -T copy-mode-vi End                    send-keys -X end-of-line
bind-key    -T copy-mode-vi NPage                  send-keys -X page-down
bind-key    -T copy-mode-vi PPage                  send-keys -X page-up
bind-key    -T copy-mode-vi Up                     send-keys -X cursor-up
bind-key    -T copy-mode-vi Down                   send-keys -X cursor-down
bind-key    -T copy-mode-vi Left                   send-keys -X cursor-left
bind-key    -T copy-mode-vi Right                  send-keys -X cursor-right
bind-key    -T copy-mode-vi M-x                    send-keys -X jump-to-mark
bind-key    -T copy-mode-vi M-y                    send-keys -X copy-pipe-and-cancel "reattach-to-user-namespace pbcopy; tmux paste-buffer -p"
bind-key    -T copy-mode-vi C-b                    send-keys -X page-up
bind-key    -T copy-mode-vi C-c                    send-keys -X cancel
bind-key    -T copy-mode-vi C-d                    send-keys -X halfpage-down
bind-key    -T copy-mode-vi C-e                    send-keys -X scroll-down
bind-key    -T copy-mode-vi C-f                    send-keys -X page-down
bind-key    -T copy-mode-vi C-h                    send-keys -X cursor-left
bind-key    -T copy-mode-vi C-j                    send-keys -X copy-pipe-and-cancel
bind-key    -T copy-mode-vi C-o                    send-keys -X copy-pipe-and-cancel "sed s/##/####/g | xargs -I {} tmux send-keys 'vi -- \"{}\"'; tmux send-keys 'C-m'"
bind-key    -T copy-mode-vi C-u                    send-keys -X halfpage-up
bind-key    -T copy-mode-vi C-v                    send-keys -X rectangle-toggle
bind-key    -T copy-mode-vi C-y                    send-keys -X scroll-up
bind-key    -T copy-mode-vi C-Up                   send-keys -X scroll-up
bind-key    -T copy-mode-vi C-Down                 send-keys -X scroll-down
bind-key    -T edit-mode-vi Up                     send-keys -X history-up
bind-key    -T edit-mode-vi Down                   send-keys -X history-down
bind-key    -T prefix       Space                  next-layout
bind-key    -T prefix       !                      break-pane
bind-key    -T prefix       \"                     split-window
bind-key    -T prefix       \#                     list-buffers
bind-key    -T prefix       \$                     command-prompt -I "#S" { rename-session "%%" }
bind-key    -T prefix       \%                     split-window -h
bind-key    -T prefix       &                      kill-window
bind-key    -T prefix       \'                     command-prompt -T window-target -p index { select-window -t ":%%" }
bind-key    -T prefix       (                      switch-client -p
bind-key    -T prefix       )                      switch-client -n
bind-key    -T prefix       ,                      command-prompt -I "#W" { rename-window "%%" }
bind-key    -T prefix       -                      display-popup -E -b rounded -d "#{pane_current_path}" "tmux-commands | xargs -r tmux split-window -v -c \"#{pane_current_path}\""
bind-key    -T prefix       .                      command-prompt -T target { move-window -t "%%" }
bind-key    -T prefix       /                      copy-mode \; send-keys ?
bind-key    -T prefix       0                      select-window -t :=0
bind-key    -T prefix       1                      select-window -t :=1
bind-key    -T prefix       2                      select-window -t :=2
bind-key    -T prefix       3                      select-window -t :=3
bind-key    -T prefix       4                      select-window -t :=4
bind-key    -T prefix       5                      select-window -t :=5
bind-key    -T prefix       6                      select-window -t :=6
bind-key    -T prefix       7                      select-window -t :=7
bind-key    -T prefix       8                      select-window -t :=8
bind-key    -T prefix       9                      select-window -t :=9
bind-key    -T prefix       :                      command-prompt
bind-key    -T prefix       \;                     last-pane
bind-key    -T prefix       <                      display-menu -T "#[align=centre]#{window_index}:#{window_name}" -x W -y W "#{?#{>:#{session_windows},1},,-}Swap Left" l { swap-window -t :-1 } "#{?#{>:#{session_windows},1},,-}Swap Right" r { swap-window -t :+1 } "#{?pane_marked_set,,-}Swap Marked" s { swap-window } '' Kill X { kill-window } Respawn R { respawn-window -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } Rename n { command-prompt -F -I "#W" { rename-window -t "#{window_id}" "%%" } } '' "New After" w { new-window -a } "New At End" W { new-window }
bind-key    -T prefix       =                      choose-buffer -Z
bind-key    -T prefix       >                      display-menu -T "#[align=centre]#{pane_index} (#{pane_id})" -x P -y P "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Top,}" < { send-keys -X history-top } "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Bottom,}" > { send-keys -X history-bottom } '' "#{?mouse_word,Search For #[underscore]#{=/9/...:mouse_word},}" C-r { if-shell -F "#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}" "copy-mode -t=" ; send-keys -X -t = search-backward "#{q:mouse_word}" } "#{?mouse_word,Type #[underscore]#{=/9/...:mouse_word},}" C-y { copy-mode -q ; send-keys -l "#{q:mouse_word}" } "#{?mouse_word,Copy #[underscore]#{=/9/...:mouse_word},}" c { copy-mode -q ; set-buffer "#{q:mouse_word}" } "#{?mouse_line,Copy Line,}" l { copy-mode -q ; set-buffer "#{q:mouse_line}" } '' "#{?mouse_hyperlink,Type #[underscore]#{=/9/...:mouse_hyperlink},}" C-h { copy-mode -q ; send-keys -l "#{q:mouse_hyperlink}" } "#{?mouse_hyperlink,Copy #[underscore]#{=/9/...:mouse_hyperlink},}" h { copy-mode -q ; set-buffer "#{q:mouse_hyperlink}" } '' "Horizontal Split" h { split-window -h } "Vertical Split" v { split-window -v } '' "#{?#{>:#{window_panes},1},,-}Swap Up" u { swap-pane -U } "#{?#{>:#{window_panes},1},,-}Swap Down" d { swap-pane -D } "#{?pane_marked_set,,-}Swap Marked" s { swap-pane } '' Kill X { kill-pane } Respawn R { respawn-pane -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } "#{?#{>:#{window_panes},1},,-}#{?window_zoomed_flag,Unzoom,Zoom}" z { resize-pane -Z }
bind-key    -T prefix       ?                      list-keys -N
bind-key    -T prefix       A                      display-menu -T "#[align=centre fg=orange] Commands " -x R -y P "Synchronize Panes" s "set-window-option synchronize-panes" "Rename Tab" , "command-prompt -I \"#W\" { rename-window \"%%\" }" "Run Tmux Command" : command-prompt
bind-key    -T prefix       C                      display-popup -E -b rounded -d "#{pane_current_path}" "tmux-commands | xargs -r tmux new-window -c \"#{pane_current_path}\""
bind-key    -T prefix       D                      choose-client -Z
bind-key    -T prefix       E                      display-popup -E -b rounded -d "#{pane_current_path}" "tmux-project commands | xargs -r tmux-run -t right run --"
bind-key    -T prefix       G                      display-popup -E -b rounded -d "#{pane_current_path}" -h "90%" -w "85%" -x C -y C "tmux-grep | xargs -r tmux-helix open"
bind-key -r -T prefix       H                      resize-pane -L 5
bind-key    -T prefix       I                      run-shell /opt/homebrew/opt/tpm/share/tpm/bindings/install_plugins
bind-key -r -T prefix       J                      resize-pane -D 5
bind-key -r -T prefix       K                      resize-pane -U 5
bind-key -r -T prefix       L                      resize-pane -R 5
bind-key    -T prefix       M                      select-pane -M
bind-key    -T prefix       P                      display-popup -E -T "#[fg=orange]❀ Panes" -b rounded tmux-panes
bind-key    -T prefix       R                      run-shell " \t\t\ttmux source-file /Users/cheverjohn/.tmux.conf > /dev/null; \t\t\ttmux display-message 'Sourced /Users/cheverjohn/.tmux.conf!'"
bind-key    -T prefix       S                      display-popup -E -T "#[fg=orange]❀ Sessions" -b rounded tmux-sessions
bind-key    -T prefix       U                      run-shell /opt/homebrew/opt/tpm/share/tpm/bindings/update_plugins
bind-key    -T prefix       X                      kill-pane -a
bind-key    -T prefix       Y                      run-shell -b /Users/cheverjohn/.tmux/plugins/tmux-yank/scripts/copy_pane_pwd.sh
bind-key    -T prefix       [                      copy-mode
bind-key    -T prefix       ]                      paste-buffer -p
bind-key    -T prefix       ^                      last-window
bind-key    -T prefix       c                      new-window -c "#{pane_current_path}"
bind-key    -T prefix       d                      detach-client
bind-key    -T prefix       f                      command-prompt { find-window -Z "%%" }
bind-key -r -T prefix       h                      select-pane -L
bind-key    -T prefix       i                      display-message
bind-key -r -T prefix       j                      select-pane -D
bind-key -r -T prefix       k                      select-pane -U
bind-key -r -T prefix       l                      select-pane -R
bind-key    -T prefix       m                      select-pane -m
bind-key    -T prefix       n                      next-window
bind-key    -T prefix       o                      select-pane -t :.+
bind-key    -T prefix       p                      previous-window
bind-key    -T prefix       q                      display-panes
bind-key    -T prefix       r                      source-file /Users/cheverjohn/.tmux.conf \; display-message Reloaded!!!
bind-key    -T prefix       s                      split-window -v -c "#{?pane_path,#{s@^file.//@@:pane_path},#{pane_current_path}}" -l 30
bind-key    -T prefix       t                      clock-mode
bind-key    -T prefix       v                      split-window -h -c "#{?pane_path,#{s@^file.//@@:pane_path},#{pane_current_path}}" -l 100
bind-key    -T prefix       w                      choose-tree -Zw
bind-key    -T prefix       x                      kill-pane
bind-key    -T prefix       y                      run-shell -b /Users/cheverjohn/.tmux/plugins/tmux-yank/scripts/copy_line.sh
bind-key    -T prefix       z                      resize-pane -Z
bind-key    -T prefix       \{                     swap-pane -U
bind-key    -T prefix       |                      display-popup -E -b rounded -d "#{pane_current_path}" "tmux-commands | xargs -r tmux split-window -h -c \"#{pane_current_path}\""
bind-key    -T prefix       \}                     swap-pane -D
bind-key    -T prefix       \~                     show-messages
bind-key -r -T prefix       DC                     refresh-client -c
bind-key    -T prefix       PPage                  copy-mode -u
bind-key -r -T prefix       Up                     select-pane -U
bind-key -r -T prefix       Down                   select-pane -D
bind-key -r -T prefix       Left                   select-pane -L
bind-key -r -T prefix       Right                  select-pane -R
bind-key    -T prefix       M-1                    join-pane -t :1 \; display-message "Merged to window 1"
bind-key    -T prefix       M-2                    join-pane -t :2 \; display-message "Merged to window 2"
bind-key    -T prefix       M-3                    join-pane -t :3 \; display-message "Merged to window 3"
bind-key    -T prefix       M-4                    join-pane -t :4 \; display-message "Merged to window 4"
bind-key    -T prefix       M-5                    join-pane -t :5 \; display-message "Merged to window 5"
bind-key    -T prefix       M-6                    join-pane -t :6
bind-key    -T prefix       M-7                    join-pane -t :7
bind-key    -T prefix       M-8                    join-pane -t :8
bind-key    -T prefix       M-9                    join-pane -t :9
bind-key    -T prefix       M-n                    next-window -a
bind-key    -T prefix       M-o                    rotate-window -D
bind-key    -T prefix       M-p                    previous-window -a
bind-key    -T prefix       M-u                    run-shell /opt/homebrew/opt/tpm/share/tpm/bindings/clean_plugins
bind-key -r -T prefix       M-Up                   resize-pane -U 5
bind-key -r -T prefix       M-Down                 resize-pane -D 5
bind-key -r -T prefix       M-Left                 resize-pane -L 5
bind-key -r -T prefix       M-Right                resize-pane -R 5
bind-key    -T prefix       C-f                    send-prefix
bind-key    -T prefix       C-n                    next-window
bind-key    -T prefix       C-o                    rotate-window
bind-key    -T prefix       C-p                    previous-window
bind-key    -T prefix       C-z                    suspend-client
bind-key -r -T prefix       C-Up                   resize-pane -U
bind-key -r -T prefix       C-Down                 resize-pane -D
bind-key -r -T prefix       C-Left                 resize-pane -L
bind-key -r -T prefix       C-Right                resize-pane -R
bind-key -r -T prefix       S-Up                   refresh-client -U 10
bind-key -r -T prefix       S-Down                 refresh-client -D 10
bind-key -r -T prefix       S-Left                 refresh-client -L 10
bind-key -r -T prefix       S-Right                refresh-client -R 10
bind-key    -T root         MouseDown1Pane         select-pane -t = \; send-keys -M
bind-key    -T root         MouseDown1Status       select-window -t =
bind-key    -T root         MouseDown2Pane         select-pane -t = \; if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" { send-keys -M } { paste-buffer -p }
bind-key    -T root         MouseDown3Pane         if-shell -F -t = "#{||:#{mouse_any_flag},#{&&:#{pane_in_mode},#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}}}" { select-pane -t = ; send-keys -M } { display-menu -T "#[align=centre]#{pane_index} (#{pane_id})" -t = -x M -y M "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Top,}" < { send-keys -X history-top } "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Bottom,}" > { send-keys -X history-bottom } '' "#{?mouse_word,Search For #[underscore]#{=/9/...:mouse_word},}" C-r { if-shell -F "#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}" "copy-mode -t=" ; send-keys -X -t = search-backward "#{q:mouse_word}" } "#{?mouse_word,Type #[underscore]#{=/9/...:mouse_word},}" C-y { copy-mode -q ; send-keys -l "#{q:mouse_word}" } "#{?mouse_word,Copy #[underscore]#{=/9/...:mouse_word},}" c { copy-mode -q ; set-buffer "#{q:mouse_word}" } "#{?mouse_line,Copy Line,}" l { copy-mode -q ; set-buffer "#{q:mouse_line}" } '' "#{?mouse_hyperlink,Type #[underscore]#{=/9/...:mouse_hyperlink},}" C-h { copy-mode -q ; send-keys -l "#{q:mouse_hyperlink}" } "#{?mouse_hyperlink,Copy #[underscore]#{=/9/...:mouse_hyperlink},}" h { copy-mode -q ; set-buffer "#{q:mouse_hyperlink}" } '' "Horizontal Split" h { split-window -h } "Vertical Split" v { split-window -v } '' "#{?#{>:#{window_panes},1},,-}Swap Up" u { swap-pane -U } "#{?#{>:#{window_panes},1},,-}Swap Down" d { swap-pane -D } "#{?pane_marked_set,,-}Swap Marked" s { swap-pane } '' Kill X { kill-pane } Respawn R { respawn-pane -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } "#{?#{>:#{window_panes},1},,-}#{?window_zoomed_flag,Unzoom,Zoom}" z { resize-pane -Z } }
bind-key    -T root         MouseDown3Status       display-menu -T "#[align=centre]#{window_index}:#{window_name}" -t = -x W -y W "#{?#{>:#{session_windows},1},,-}Swap Left" l { swap-window -t :-1 } "#{?#{>:#{session_windows},1},,-}Swap Right" r { swap-window -t :+1 } "#{?pane_marked_set,,-}Swap Marked" s { swap-window } '' Kill X { kill-window } Respawn R { respawn-window -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } Rename n { command-prompt -F -I "#W" { rename-window -t "#{window_id}" "%%" } } '' "New After" w { new-window -a } "New At End" W { new-window }
bind-key    -T root         MouseDown3StatusLeft   display-menu -T "#[align=centre]#{session_name}" -t = -x M -y W Next n { switch-client -n } Previous p { switch-client -p } '' Renumber N { move-window -r } Rename n { command-prompt -I "#S" { rename-session "%%" } } '' "New Session" s { new-session } "New Window" w { new-window }
bind-key    -T root         MouseDrag1Pane         if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" { send-keys -M } { copy-mode -M }
bind-key    -T root         MouseDrag1Border       resize-pane -M
bind-key    -T root         WheelUpPane            if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" { send-keys -M } { copy-mode -e }
bind-key    -T root         WheelUpStatus          previous-window
bind-key    -T root         WheelDownStatus        next-window
bind-key    -T root         DoubleClick1Pane       select-pane -t = \; if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" { send-keys -M } { copy-mode -H ; send-keys -X select-word ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel }
bind-key    -T root         TripleClick1Pane       select-pane -t = \; if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" { send-keys -M } { copy-mode -H ; send-keys -X select-line ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel }
bind-key    -T root         M-MouseDown3Pane       display-menu -T "#[align=centre]#{pane_index} (#{pane_id})" -t = -x M -y M "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Top,}" < { send-keys -X history-top } "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Bottom,}" > { send-keys -X history-bottom } '' "#{?mouse_word,Search For #[underscore]#{=/9/...:mouse_word},}" C-r { if-shell -F "#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}" "copy-mode -t=" ; send-keys -X -t = search-backward "#{q:mouse_word}" } "#{?mouse_word,Type #[underscore]#{=/9/...:mouse_word},}" C-y { copy-mode -q ; send-keys -l "#{q:mouse_word}" } "#{?mouse_word,Copy #[underscore]#{=/9/...:mouse_word},}" c { copy-mode -q ; set-buffer "#{q:mouse_word}" } "#{?mouse_line,Copy Line,}" l { copy-mode -q ; set-buffer "#{q:mouse_line}" } '' "#{?mouse_hyperlink,Type #[underscore]#{=/9/...:mouse_hyperlink},}" C-h { copy-mode -q ; send-keys -l "#{q:mouse_hyperlink}" } "#{?mouse_hyperlink,Copy #[underscore]#{=/9/...:mouse_hyperlink},}" h { copy-mode -q ; set-buffer "#{q:mouse_hyperlink}" } '' "Horizontal Split" h { split-window -h } "Vertical Split" v { split-window -v } '' "#{?#{>:#{window_panes},1},,-}Swap Up" u { swap-pane -U } "#{?#{>:#{window_panes},1},,-}Swap Down" d { swap-pane -D } "#{?pane_marked_set,,-}Swap Marked" s { swap-pane } '' Kill X { kill-pane } Respawn R { respawn-pane -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } "#{?#{>:#{window_panes},1},,-}#{?window_zoomed_flag,Unzoom,Zoom}" z { resize-pane -Z }
bind-key    -T root         M-MouseDown3Status     display-menu -T "#[align=centre]#{window_index}:#{window_name}" -t = -x W -y W "#{?#{>:#{session_windows},1},,-}Swap Left" l { swap-window -t :-1 } "#{?#{>:#{session_windows},1},,-}Swap Right" r { swap-window -t :+1 } "#{?pane_marked_set,,-}Swap Marked" s { swap-window } '' Kill X { kill-window } Respawn R { respawn-window -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } Rename n { command-prompt -F -I "#W" { rename-window -t "#{window_id}" "%%" } } '' "New After" w { new-window -a } "New At End" W { new-window }
bind-key    -T root         M-MouseDown3StatusLeft display-menu -T "#[align=centre]#{session_name}" -t = -x M -y W Next n { switch-client -n } Previous p { switch-client -p } '' Renumber N { move-window -r } Rename n { command-prompt -I "#S" { rename-session "%%" } } '' "New Session" s { new-session } "New Window" w { new-window }
bind-key    -T root         C-S-Left               swap-window -t -1
bind-key    -T root         C-S-Right              swap-window -t +1
.dotfilesgit:(chore/update-alacritty-to-change-tmux-windows*)$

```

