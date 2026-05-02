# Browser Configuration Module
# ============================
# This directory contains browser configurations using a hybrid approach:
# - Declarative settings (managed by Nix) for policies, theming, and system-wide configs
# - Persistent data (NOT managed by Nix) for history, cookies, extensions, and user state
#
# IMPORTANT: Browser Data Preservation
# -------------------------------------
# Home Manager's `programs.firefox` and `programs.zen-browser` modules manage the ENTIRE
# profile directory by default. This includes ALL browser data:
#   - History
#   - Cookies and login sessions
#   - Extensions and their data
#   - Bookmarks
#   - Profile settings
#
# When you switch generations or update, Home Manager RECREATES the entire profile
# directory from scratch, wiping all your data. This is why your history, cookies,
# and extensions were lost.
#
# Solution: Hybrid Declarative/Persistent Approach
# -------------------------------------------------
# Instead of using Home Manager's `profiles` option (which manages the entire profile),
# we only use:
#   1. `programs.<browser>.policies` - System-wide policies (don't affect profile data)
#   2. `home.file` - Write specific files (userChrome.css, user.js) to the profile
#      directory WITHOUT managing the entire directory
#
# This approach:
#   ✓ Preserves history, cookies, extensions, and all user data
#   ✓ Still allows declarative theming (CSS via userChrome.css)
#   ✓ Still allows declarative settings (via user.js)
#   ✓ Browser remains stateful - install extensions, change settings freely
#   ✗ Cannot declaratively pre-install extensions or set initial bookmarks
#
# Alternative Approaches
# ----------------------
# If you want FULL declarative management (extensions, bookmarks, everything):
#   - Use `programs.firefox.profiles` or `programs.zen-browser.profiles`
#   - Accept that data will be reset on each generation switch
#   - Best for: Reproducible setups, fresh installs, shared configs
#
# If you want selective persistence (advanced):
#   - Use `impermanence` module with `home.persistence`
#   - Persist specific profile subdirectories while managing others
#   - More complex setup, see: https://github.com/nix-community/impermanence
#
# References
# ----------
# - Home Manager Firefox: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.firefox.enable
# - Zen Browser Flake: https://github.com/0xc000022070/zen-browser-flake
# - Impermanence: https://github.com/nix-community/impermanence

{
  imports = [
    ./chromium.nix
    ./firefox.nix
    ./vesktop.nix
    ./web-apps.nix
    ./zen.nix
  ];
}
