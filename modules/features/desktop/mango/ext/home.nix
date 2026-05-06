# modules/features/desktop/mango/ext/home.nix
#
# Home Manager configuration for the mango-ext compositor (ernestoCruz05 fork).
# Imports the mango-ext HM module, the shared mango config, and adds ext-specific
# settings (canvas, dwindle layout, tag carousel).
#
# Keybind overrides from stable:
#   SUPER+o  → toggleminimap  (was: toggleoverlay)
#   SUPER+u  → canvas_fill_viewport  (was: focuslast)
{ inputs, ... }:
{
  imports = [
    inputs.mango-ext.hmModules.mango
    ../common.nix
  ];

  wayland.windowManager.mango.settings = {
    # ── Canvas (mango-ext) ──────────────────────────────────────────────────
    # A free-form workspace where windows can be placed anywhere, zoomed, and
    # panned. Toggle minimap to see an overview, use overview_toggle for a
    # bird's-eye view, and zoom_resize to scale windows in/out.
    bind = [
      "SUPER,o,toggleminimap,"
      "SUPER,p,canvas_overview_toggle,"
      "SUPER,z,canvas_zoom_resize,0.7"
      "SUPER,x,canvas_zoom_resize,1.3"
      "SUPER,u,canvas_fill_viewport,"
      "SUPER,c,canvas_centerview,"
      # Direct layout switch to canvas (matches CTRL+SUPER+i=tile, CTRL+SUPER+l=scroller)
      "CTRL+SUPER,c,setlayout,canvas"

      # Canvas anchors: SUPER+ALT+F8-F12 to save, SUPER+F8-F12 to jump
      "SUPER+ALT,F8,canvas_anchor_set,0"
      "SUPER+ALT,F9,canvas_anchor_set,1"
      "SUPER+ALT,F10,canvas_anchor_set,2"
      "SUPER+ALT,F11,canvas_anchor_set,3"
      "SUPER+ALT,F12,canvas_anchor_set,4"
      "SUPER,F8,canvas_anchor_go,0"
      "SUPER,F9,canvas_anchor_go,1"
      "SUPER,F10,canvas_anchor_go,2"
      "SUPER,F11,canvas_anchor_go,3"
      "SUPER,F12,canvas_anchor_go,4"
    ];

    # Viewport panning: ALT+middle-mouse drag to pan the canvas viewport.
    # Window move/resize already work via SUPER+left/right click (canvas-aware).
    mousebind = [
      "ALT,btn_middle,canvas_drag_pan"
    ];

    # Scroll-wheel zoom on canvas (SUPER+scroll). These only dispatch on the
    # canvas layout; on other layouts SUPER+scroll still does tag navigation.
    axisbind = [
      "SUPER,UP,canvas_zoom_resize,1.4"
      "SUPER,DOWN,canvas_zoom_resize,0.6"
    ];

    canvas_tiling = 0;
    canvas_tiling_gap = 10;
    canvas_pan_on_kill = 1;
    canvas_anchor_animate = 1;

    # ── Dwindle layout (mango-ext) ──────────────────────────────────────────
    # A recursive split layout where new windows split the focused container.
    # Added to circle_layout so SUPER+n cycles through tile → scroller → dwindle.
    dwindle_vsplit = 0;
    dwindle_hsplit = 0;
    dwindle_preserve_split = 0;
    dwindle_smart_split = 0;
    dwindle_smart_resize = 0;
    dwindle_split_ratio = 0.5;

    # ── Tag carousel (mango-ext) ────────────────────────────────────────────
    # Carousel-like behaviour when swapping tags.
    tag_carousel = 1;

    # ── Layout cycle ─────────────────────────────────────────────────────────
    # Canvas and dwindle are mango-ext layouts. SUPER+n cycles through these.
    circle_layout = "tile,scroller,canvas,dwindle";

    # ── Input (mango-ext naming) ─────────────────────────────────────────────
    # mango-ext splits accel settings into mouse_ and trackpad_ prefixes.
    # Upstream mango uses the generic accel_profile/accel_speed for both.
    trackpad_accel_profile = 2;
    trackpad_accel_speed = 0.0;
  };
}
