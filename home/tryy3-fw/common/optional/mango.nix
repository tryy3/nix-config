# Home-manager configuration for MangoWC.
# Pair with hosts/common/optional/mango.nix for the system-level enablement.
#
# NOTE on structure:
# Upstream config (https://github.com/DreamMaoMao/mango-config) splits config
# across `config.conf`, `env.conf`, `bind.conf`, `rule.conf`, `monitor.conf`,
# `tag.conf` via `source = ./xxx.conf;`. The mango HM module generates a single
# `~/.config/mango/config.conf` from `settings`, so we inline everything here.
# Repeating keys (`bind`, `windowrule`, `env`, etc.) are expressed as Nix lists,
# which the module emits as duplicate `key=value` lines.
{ inputs, ... }:
{
  imports = [
    inputs.mango.hmModules.mango
  ];

  wayland.windowManager.mango = {
    enable = true;
    settings = {
      # ── Effects ────────────────────────────────────────────────────────────
      blur = 0;
      blur_layer = 1;
      blur_optimized = 1;
      blur_params_num_passes = 2;
      blur_params_radius = 5;
      blur_params_noise = 0.02;
      blur_params_brightness = 0.9;
      blur_params_contrast = 0.9;
      blur_params_saturation = 1.2;

      shadows = 1;
      layer_shadows = 1;
      shadow_only_floating = 1;
      shadows_size = 12;
      shadows_blur = 15;
      shadows_position_x = 0;
      shadows_position_y = 0;
      shadowscolor = "0x000000ff";

      border_radius = 6;
      no_radius_when_single = 0;
      focused_opacity = 1.0;
      unfocused_opacity = 0.85;

      # ── Animations ────────────────────────────────────────────────────────
      animations = 1;
      layer_animations = 1;
      animation_type_open = "zoom";
      animation_type_close = "slide";
      layer_animation_type_open = "slide";
      layer_animation_type_close = "slide";
      animation_fade_in = 1;
      animation_fade_out = 1;
      tag_animation_direction = 1;
      zoom_initial_ratio = 0.4;
      zoom_end_ratio = 0.7;
      fadein_begin_opacity = 0.5;
      fadeout_begin_opacity = 0.8;
      animation_duration_move = 500;
      animation_duration_open = 400;
      animation_duration_tag = 350;
      animation_duration_close = 800;
      animation_duration_focus = 400;
      animation_curve_open = "0.46,1.0,0.29,1.1";
      animation_curve_move = "0.46,1.0,0.29,1";
      animation_curve_tag = "0.46,1.0,0.29,1";
      animation_curve_close = "0.08,0.92,0,1";
      animation_curve_focus = "0.46,1.0,0.29,1";
      animation_curve_opafadeout = "0.58,0.98,0.58,0.98";
      animation_curve_opafadein = "0.46,1.0,0.29,1";

      # ── Scroller layout ───────────────────────────────────────────────────
      scroller_structs = 20;
      scroller_default_proportion = 0.8;
      scroller_focus_center = 0;
      scroller_prefer_center = 1;
      edge_scroller_pointer_focus = 1;
      scroller_default_proportion_single = 1.0;
      scroller_proportion_preset = "0.5,0.8,1.0";

      # ── Master-stack layout ───────────────────────────────────────────────
      new_is_master = 1;
      smartgaps = 0;
      default_mfact = 0.55;
      default_nmaster = 1;

      # ── Overview ──────────────────────────────────────────────────────────
      hotarea_size = 10;
      enable_hotarea = 1;
      ov_tab_mode = 0;
      overviewgappi = 5;
      overviewgappo = 30;

      # ── Misc ──────────────────────────────────────────────────────────────
      xwayland_persistence = 1;
      syncobj_enable = 0;
      no_border_when_single = 0;
      axis_bind_apply_timeout = 100;
      focus_on_activate = 1;
      sloppyfocus = 1;
      warpcursor = 1;
      focus_cross_monitor = 0;
      focus_cross_tag = 0;
      circle_layout = "tile,scroller";
      enable_floating_snap = 1;
      snap_distance = 50;
      cursor_size = 24;
      cursor_theme = "Bibata-Modern-Ice";
      cursor_hide_timeout = 0;
      drag_tile_to_tile = 1;
      single_scratchpad = 1;

      # ── Keyboard ──────────────────────────────────────────────────────────
      repeat_rate = 25;
      repeat_delay = 600;
      numlockon = 1;
      xkb_rules_layout = "us,ru";
      # xkb_rules_options = "ctrl:nocaps";
      # xkb_rules_options = "grp:alt_altgr_toggle,caps:hyper";

      # ── Trackpad ──────────────────────────────────────────────────────────
      disable_trackpad = 0;
      tap_to_click = 1;
      tap_and_drag = 1;
      drag_lock = 1;
      mouse_natural_scrolling = 0;
      trackpad_natural_scrolling = 0;
      disable_while_typing = 1;
      left_handed = 0;
      middle_button_emulation = 0;
      swipe_min_threshold = 1;
      accel_profile = 2;
      accel_speed = 0.0;
      # scroll_button = 274;
      # scroll_method = 1;

      # ── Appearance ────────────────────────────────────────────────────────
      gappih = 5;
      gappiv = 5;
      gappoh = 15;
      gappov = 15;
      scratchpad_width_ratio = 0.8;
      scratchpad_height_ratio = 0.9;
      borderpx = 4;
      rootcolor = "0x201b14ff";
      bordercolor = "0x444444ff";
      focuscolor = "0x8BAA9Bff";
      maximizescreencolor = "0xBABD2Cff";
      urgentcolor = "0xad401fff";
      scratchpadcolor = "0xc4939dff";
      globalcolor = "0x8d64cfff";
      overlaycolor = "0x95C381ff";

      # ── env.conf ──────────────────────────────────────────────────────────
      env = [
        "GTK_IM_MODULE,fcitx"
        "QT_IM_MODULE,fcitx"
        "SDL_IM_MODULE,fcitx"
        "XMODIFIERS,@im=fcitx"
        "GLFW_IM_MODULE,ibus"
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_WAYLAND_FORCE_DPI,140"
        "QT_QPA_PLATFORM,Wayland;xcb"
      ];

      # ── monitor.conf ──────────────────────────────────────────────────────
      # monitorrule = [
      #   "name:eDP-1,width:1920,height:1080,refresh:60,x:0,y:10,scale:1,vrr:0,rr:0"
      # ];

      # ── tag.conf ──────────────────────────────────────────────────────────
      tagrule = [
        "id:1,layout_name:tile"
        "id:2,layout_name:tile"
        "id:3,layout_name:tile"
        "id:4,layout_name:tile"
        "id:5,layout_name:tile"
        "id:6,layout_name:tile"
        "id:7,layout_name:tile"
        "id:8,layout_name:tile"
        "id:9,layout_name:tile"
      ];

      # ── bind.conf ─────────────────────────────────────────────────────────
      bind = [
        # reload config
        "SUPER,r,spawn_shell,bash ~/.config/mango/scripts/config_check.sh"
        "SUPER,r,reload_config"

        # menu and terminal
        "Alt,Return,spawn,foot"
        "Alt,space,spawn,rofi -config ~/.config/mango/rofi/config.rasi -show drun"

        # exit / killclient
        "SUPER,m,quit"
        "ALT,q,killclient,"

        # switch window focus
        "SUPER,Tab,focusstack,next"
        "SUPER,u,focuslast"
        "ALT,Left,focusdir,left"
        "ALT,Right,focusdir,right"
        "ALT,Up,focusdir,up"
        "ALT,Down,focusdir,down"

        # swap window
        "SUPER+SHIFT,Up,exchange_client,up"
        "SUPER+SHIFT,Down,exchange_client,down"
        "SUPER+SHIFT,Left,exchange_client,left"
        "SUPER+SHIFT,Right,exchange_client,right"

        # movewin
        "CTRL+SHIFT,Up,movewin,+0,-50"
        "CTRL+SHIFT,Down,movewin,+0,+50"
        "CTRL+SHIFT,Left,movewin,-50,+0"
        "CTRL+SHIFT,Right,movewin,+50,+0"

        # resizewin
        "CTRL+ALT,Up,resizewin,+0,-50"
        "CTRL+ALT,Down,resizewin,+0,+50"
        "CTRL+ALT,Left,resizewin,-50,+0"
        "CTRL+ALT,Right,resizewin,+50,+0"

        # switch window status
        "SUPER,g,toggleglobal,"
        "ALT,Tab,toggleoverview,0"
        "ALT,backslash,togglefloating,"
        "ALT,a,togglemaximizescreen,"
        "ALT,f,togglefullscreen,"
        "ALT+SHIFT,f,togglefakefullscreen,"
        "SUPER,i,minimized,"
        "SUPER,o,toggleoverlay,"
        "SUPER+SHIFT,I,restore_minimized"
        "ALT,z,toggle_scratchpad"

        # scroller layout
        "ALT,e,set_proportion,1.0"
        "ALT,x,switch_proportion_preset,"

        # tile layout
        "SUPER,e,incnmaster,1"
        "SUPER,t,incnmaster,-1"
        "ALT,s,zoom,"

        # switch layout
        "CTRL+SUPER,i,setlayout,tile"
        "CTRL+SUPER,l,setlayout,scroller"
        "SUPER,n,switch_layout"

        # tag switch
        "SUPER,Left,viewtoleft,0"
        "CTRL,Left,viewtoleft_have_client,0"
        "SUPER,Right,viewtoright,0"
        "CTRL,Right,viewtoright_have_client,0"
        "CTRL+SUPER,Left,tagtoleft,0"
        "CTRL+SUPER,Right,tagtoright,0"

        "Ctrl,1,view,1,0"
        "Ctrl,2,view,2,0"
        "Ctrl,3,view,3,0"
        "Ctrl,4,view,4,0"
        "Ctrl,5,view,5,0"
        "Ctrl,6,view,6,0"
        "Ctrl,7,view,7,0"
        "Ctrl,8,view,8,0"
        "Ctrl,9,view,9,0"

        "Alt,1,tag,1,0"
        "Alt,2,tag,2,0"
        "Alt,3,tag,3,0"
        "Alt,4,tag,4,0"
        "Alt,5,tag,5,0"
        "Alt,6,tag,6,0"
        "Alt,7,tag,7,0"
        "Alt,8,tag,8,0"
        "Alt,9,tag,9,0"

        "ctrl+Super,1,toggletag,1"
        "ctrl+Super,2,toggletag,2"
        "ctrl+Super,3,toggletag,3"
        "ctrl+Super,4,toggletag,4"
        "ctrl+Super,5,toggletag,5"
        "ctrl+Super,6,toggletag,6"
        "ctrl+Super,7,toggletag,7"
        "ctrl+Super,8,toggletag,8"
        "ctrl+Super,9,toggletag,9"

        "Super,1,toggleview,1"
        "Super,2,toggleview,2"
        "Super,3,toggleview,3"
        "Super,4,toggleview,4"
        "Super,5,toggleview,5"
        "Super,6,toggleview,6"
        "Super,7,toggleview,7"
        "Super,8,toggleview,8"
        "Super,9,toggleview,9"

        # monitor switch
        "alt+shift,Left,focusmon,left"
        "alt+shift,Right,focusmon,right"
        "alt+shift,Up,focusmon,up"
        "alt+shift,Down,focusmon,down"
        "SUPER+Alt,Left,tagmon,left"
        "SUPER+Alt,Right,tagmon,right"
        "SUPER+Alt,Up,tagmon,up"
        "SUPER+Alt,Down,tagmon,down"

        # gaps
        "ALT+SHIFT,X,incgaps,1"
        "ALT+SHIFT,Z,incgaps,-1"
        "ALT+SHIFT,R,togglegaps"

        # brightness and volume
        "none,XF86AudioRaiseVolume,spawn,~/.config/mango/scripts/volume.sh up"
        "none,XF86AudioLowerVolume,spawn,~/.config/mango/scripts/volume.sh down"
        "none,XF86MonBrightnessUp,spawn,~/.config/mango/scripts/brightness.sh up"
        "none,XF86MonBrightnessDown,spawn,~/.config/mango/scripts/brightness.sh down"

        # custom app binds
        "SUPER,Return,spawn,google-chrome"
        "CTRL+SUPER,Return,spawn,foot -e yazi"
        ''CTRL+ALT,a,spawn_shell,grim -g "$(slurp -b '#2E2A1E55' -c '#fb751bff')" -t ppm - | satty -f -''
        "SUPER,h,spawn,bash ~/.config/mango/scripts/hide_waybar_mango.sh"
        "SUPER,l,spawn,swaylock -f -c 000000"
        "CTRL+ALT,backslash,spawn,swaync-client -t"
        "CTRL+ALT,BackSpace,spawn,swaync-client -C"
        "SUPER,p,spawn,bash ~/.config/mango/scripts/monitor.sh"
        "SUPER+SHIFT,p,spawn,bash ~/.config/mango/scripts/virmon.sh"
      ];

      mousebind = [
        "SUPER,btn_left,moveresize,curmove"
        "alt,btn_middle,set_proportion,0.5"
        "SUPER,btn_right,moveresize,curresize"
        "SUPER+CTRL,btn_left,minimized"
        "SUPER+CTRL,btn_right,killclient"
        "SUPER+CTRL,btn_middle,togglefullscreen"
        "NONE,btn_middle,togglemaximizescreen,0"
      ];

      axisbind = [
        "SUPER,UP,viewtoleft_have_client"
        "SUPER,DOWN,viewtoright_have_client"
        "alt,UP,focusdir,left"
        "alt,DOWN,focusdir,right"
        "shift+super,UP,exchange_client,left"
        "shift+super,DOWN,exchange_client,right"
      ];

      gesturebind = [
        "none,left,3,focusdir,left"
        "none,right,3,focusdir,right"
        "none,up,3,focusdir,up"
        "none,down,3,focusdir,down"
        "none,left,4,viewtoleft_have_client"
        "none,right,4,viewtoright_have_client"
        "none,up,4,toggleoverview,1"
        "none,down,4,toggleoverview,1"
      ];

      # ── rule.conf ─────────────────────────────────────────────────────────
      windowrule = [
        "isfloating:1,appid:xdg-desktop-portal-gtk,title:打开本地仓库"
        "isfloating:1,appid:xdg-desktop-portal-gtk,title:打开文件"

        "isfloating:1,isnosizehint:1,title:迅雷"
        "width:800,height:900,title:迅雷"

        "isfloating:1,title:Translate"
        "width:800,height:900,title:Translate"

        "globalkeybinding:ctrl+alt-o,appid:com.obsproject.Studio"
        "globalkeybinding:ctrl+alt-n,appid:com.obsproject.Studio"

        "noswallow:1,appid:flameshot"
        "isfullscreen:1,appid:flameshot"
        "animation_type_open:none,appid:flameshot"
        "animation_type_close:none,appid:flameshot"

        "noswallow:1,title:Event Tester"

        "isfloating:1,width:1500,height:900,appid:yesplaymusic"
        "animation_type_open:slide,appid:yesplaymusic"
        "animation_type_close:slide,appid:yesplaymusic"

        "isfloating:1,appid:clash-verge"
        "width:1500,height:900,appid:clash-verge"
        "animation_type_open:slide,animation_type_close:slide,appid:clash-verge"

        "isfloating:1,width:1500,height:900,appid:pot,title:Recognize"
        "animation_type_open:none,animation_type_close:none,isnoshadow:1,isnoradius:1,isnoborder:1,appid:^wps$,title:^wps$"
        "force_fakemaximize:1,appid:^wpsoffice$"

        "isfloating:1,appid:blueman-manager"
        "width:1500,height:900,appid:blueman-manager"

        "isfloating:1,title:图片查看器"
        "isfloating:1,title:预览"
        "isfloating:1,title:图片查看"
        "isfloating:1,title:选择文件"
        "isfloating:1,title:打开文件"
        "isfloating:1,appid:python3,title:qxdrag"
        "isfloating:1,title:rofi - Networks"

        "animation_type_open:zoom,title:图片查看器"
        "animation_type_open:zoom,title:图片查看"
        "animation_type_open:zoom,title:选择文件"
        "animation_type_open:zoom,title:打开文件"
        "animation_type_open:zoom,appid:python3,title:qxdrag"
        "animation_type_open:zoom,title:rofi - Networks"

        "isfloating:1,appid:Rofi"
        "isfloating:1,appid:qxdrag.py"
        "isfloating:1,appid:xfce-polkit"

        "isnoborder:1,appid:Rofi"
        "animation_type_open:slide,appid:Rofi"
        "animation_type_close:zoom,appid:Rofi"
        "animation_type_open:zoom,appid:qxdrag.py"
        "animation_type_open:zoom,appid:python3,title:qxdrag"
        "animation_type_close:zoom,appid:qxdrag.py"
        "animation_type_close:zoom,appid:python3,title:qxdrag"
        "animation_type_close:zoom,appid:^com.gabm.satty$"

        "isterm:1,appid:St"

        # These applications can only strictly adhere to the tiling size when maximized
        "force_fakemaximize:1,appid:org.gnome.SystemMonitor"
        "force_fakemaximize:1,appid:org.gnome.gThumb"
        "force_fakemaximize:1,appid:firefox"
        "force_fakemaximize:1,appid:org.telegram.desktop"
        "istagsilent:1,appid:org.telegram.desktop"

        "tags:4,appid:Google-chrome"
        "tags:3,appid:QQ"
        "tags:2,appid:mpv"
        "tags:6,appid:obs"
        "tags:5,appid:org.telegram.desktop"

        "animation_type_open:none,nofadein:1,title:wechat"
        "animation_type_close:none,nofadeout:1,title:wechat"
        "isfloating:1,isoverlay:1,isnoborder:1,isunglobal:1,width:400,height:400,offsetx:9999,offsety:9999,appid:bongo-cat,title:BongoCat"
        "isfloating:1,isoverlay:1,isnoborder:1,isunglobal:1,width:280,height:200,offsetx:9999,offsety:9999,appid:mpv,title:video0 - mpv"
        "isfloating:1,isnosizehint:1,width:1500,height:900,appid:baidunetdisk,title:百度网盘"
        "isoverlay:1,appid:^com.gabm.satty$"

        "unfocused_opacity:1.0,focused_opacity:1.0,appid:^mpv$"
        "unfocused_opacity:1.0,focused_opacity:1.0,appid:^St$"
        "unfocused_opacity:1.0,focused_opacity:1.0,appid:^foot$"
        "unfocused_opacity:1.0,focused_opacity:1.0,appid:^obsidian$"
        "unfocused_opacity:1.0,focused_opacity:1.0,appid:^Google-chrome$"
        "unfocused_opacity:1.0,focused_opacity:1.0,appid:^QQ$"
      ];

      layerrule = [
        "noblur:1,noanim:1,layer_name:selection"
        "noshadow:1,layer_name:swaync-control-center"
        "noshadow:1,layer_name:swaync-notification-window"
        "noblur:1,noanim:1,layer_name:dimland_layer"
        "animation_type_open:zoom,layer_name:launcher"
        "animation_type_close:zoom,layer_name:launcher"
        "animation_type_open:zoom,layer_name:rofi"
        "animation_type_close:zoom,layer_name:rofi"
        "noanim:1,noblur:1,noshadow:1,layer_name:hyprpicker"
        "noanim:1,layer_name:showkeys"
        "noanim:1,layer_name:wofi"
        "animation_type_open:fade,layer_name:swaync-control-center"
        "animation_type_close:fade,layer_name:swaync-control-center"
        "animation_type_open:fade,layer_name:swayosd"
        "animation_type_close:fade,layer_name:swayosd"
      ];
    };

    # autostart.sh — module wires up `exec-once=~/.config/mango/autostart.sh`
    # automatically when this is non-empty. No shebang.
    #
    # NOTE: The mango HM module ALSO prepends:
    #   dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY ...
    #   systemctl --user reset-failed && systemctl --user start mango-session.target
    # so DMS (which is `WantedBy = graphical-session.target` and pulled in by
    # mango-session.target's BindsTo) starts automatically. We don't need to
    # spawn a bar / wallpaper / notification daemon here — DMS provides those.
    #
    # Most of the upstream autostart.sh is for waybar/swaync/swaybg/fcitx5/etc.
    # which we don't have installed and DMS replaces. Keeping this minimal until
    # those tools are actually wanted.
    autostart_sh = ''
      set +e
    '';
  };
}
