# .config/i3/config
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

set $mod Mod4
font pango:Fira Code, FontAwesome 10

floating_modifier $mod

bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

bindsym $mod+Prior workspace prev
bindsym $mod+Next exec bash -c "i3-msg workspace \$((`i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).name'`+1))"

bindsym $mod+i split h
bindsym $mod+o split v
bindsym $mod+p focus parent

bindsym $mod+f fullscreen

bindsym $mod+w kill

bindsym $mod+s layout toggle split

bindsym $mod+Shift+space floating toggle

#bindsym $mod+space focus mode_toggle

bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6
bindsym $mod+7 workspace $ws7
bindsym $mod+8 workspace $ws8
bindsym $mod+9 workspace $ws9
bindsym $mod+0 workspace $ws10

bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6
bindsym $mod+Shift+7 move container to workspace $ws7
bindsym $mod+Shift+8 move container to workspace $ws8
bindsym $mod+Shift+9 move container to workspace $ws9
bindsym $mod+Shift+0 move container to workspace $ws10

bindsym $mod+Shift+s move workspace to output left

bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart

workspace_auto_back_and_forth yes

mode "resize" {
  bindsym h resize shrink width 10 px or 10 ppt
  bindsym j resize grow height 10 px or 10 ppt
  bindsym k resize shrink height 10 px or 10 ppt
  bindsym l resize grow width 10 px or 10 ppt

  bindsym Return mode "default"
  bindsym Escape mode "default"
}

# Make the currently focused window a scratchpad
# bindsym $mod+Shift+minus move scratchpad

# Show the first scratchpad window
bindsym $mod+space scratchpad show

bindsym $mod+r mode "resize"

new_window pixel 0

gaps outer 0
gaps inner 20

smart_borders on

popup_during_fullscreen leave_fullscreen

for_window [class="Pinentry"] floating enable
for_window [title="(?i)authy"] floating enable
for_window [title="(?i)Starting Unity"] floating enable
for_window [title="Buddy List"] floating enable
for_window [title="Husky Mail - Sylpheed(?i)"] move scratchpad
