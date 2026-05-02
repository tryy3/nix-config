{ inputs, ... }:
{
  imports = [ inputs.zen-browser.homeModules.twilight-official ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;

    # =========================================================================
    # POLICIES (system-wide, locked — user cannot override in about:config)
    # =========================================================================
    policies = {
      # --- Updates & Telemetry ---
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableFeedbackCommands = true;

      # --- Features ---
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DontCheckDefaultBrowser = true;

      # --- Passwords & Autofill ---
      OfferToSaveLogins = false;
      AutofillCreditCardEnabled = false;

      # --- Tracking Protection (locked, users can't weaken it) ---
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      # --- Sanitize on shutdown (cache + form data only — cookies kept so user stays logged in) ---
      SanitizeOnShutdown = {
        Cache = true;
        FormData = true;
      };

      # --- Bitwarden: force-install from AMO, pin to navbar ---
      # Extension ID from addons.mozilla.org/firefox/addon/bitwarden-password-manager/
      # NUR is not available in this flake, so we use policies instead
      ExtensionSettings = {
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
      };
    };

    # =========================================================================
    # PROFILE — fully declarative
    # IMPORTANT: Close Zen Browser before running `just rebuild` when making
    # changes to spaces, pins, containers, or keyboard shortcuts.
    # =========================================================================
    profiles.default = rec {
      id = 0;
      name = "default";
      isDefault = true;

      # =======================================================================
      # SETTINGS
      # =======================================================================
      settings = {
        # --- DMS Theming (required for userChrome.css to be loaded) ---
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # --- Tracking Protection: ETP Strict (Total Cookie Protection) ---
        # Balanced approach — strong privacy without resistFingerprinting breakage
        "browser.contentblocking.category" = "strict";
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.fingerprinting.enabled" = true;
        "privacy.trackingprotection.cryptomining.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;

        # --- Cookie isolation (partitioned, blocks 3rd-party cross-site) ---
        # 5 = dFPI (dynamic First-Party Isolation / Total Cookie Protection)
        "network.cookie.cookieBehavior" = 5;

        # --- Fingerprinting (lighter — no timezone/window rounding side-effects) ---
        "privacy.fingerprintingProtection" = true;
        "dom.battery.enabled" = false;

        # --- Telemetry (belt-and-suspenders on top of policies) ---
        "browser.discovery.enabled" = false;
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";
        "app.shield.optoutstudies.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;

        # --- Network privacy ---
        "network.dns.disablePrefetch" = true;
        "network.dns.disablePrefetchFromHTTPS" = true;
        "network.prefetch-next" = false;
        "network.http.referer.XOriginTrimmingPolicy" = 2;
        "browser.urlbar.speculativeConnect.enabled" = false;
        "beacon.enabled" = false;
        "browser.send_pings" = false;

        # --- WebRTC (prevents IP leak while keeping video calls working) ---
        "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
        "media.peerconnection.ice.default_address_only" = true;

        # --- HTTPS Only ---
        "dom.security.https_only_mode" = true;
        "dom.security.https_only_mode_send_http_background_request" = false;

        # --- URL bar (no sponsored / trending suggestions) ---
        "browser.urlbar.quicksuggest.enabled" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.trending.featureGate" = false;

        # --- New tab page (clean, no sponsored content) ---
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.topsites.contile.enabled" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

        # --- Privacy misc ---
        "browser.uitour.enabled" = false;
        "privacy.globalprivacycontrol.enabled" = true;
        "browser.contentanalysis.enabled" = false;
        "browser.translations.enable" = false;
        "browser.formfill.enable" = false;
        "browser.download.manager.addToRecentDocs" = false;
        "browser.download.start_downloads_in_tmp_dir" = true;
        "browser.aboutConfig.showWarning" = false;

        # --- Zen UI ---
        "zen.workspaces.continue-where-left-off" = true;
        "zen.welcome-screen.seen" = true;
        "zen.urlbar.behavior" = "float";
        "zen.view.compact.hide-tabbar" = true;
        "zen.view.compact.animate-sidebar" = true;
      };

      # =======================================================================
      # DMS THEME
      # =======================================================================
      userChrome = ''
        :root {
          --zen-primary-color: #004d61 !important;
          --toolbarbutton-icon-fill: #7cd2f1 !important;
          --toolbar-field-color: #f2dde2 !important;
          --tab-selected-textcolor: #7cd2f1 !important;
          --toolbar-color: #f2dde2 !important;
          --arrowpanel-color: #f2dde2 !important;
          --arrowpanel-background: #281d20 !important;
          --sidebar-text-color: #f2dde2 !important;
          --zen-main-browser-background: #1b1114 !important;
        }

        .sidebar-placesTree {
          background-color: #281d20 !important;
        }

        #zen-workspaces-button {
          background-color: #281d20 !important;
        }

        #TabsToolbar {
          background-color: #1b1114 !important;
        }

        .urlbar-background {
          background-color: #281d20 !important;
        }

        .urlbar-input::selection {
          color: #003544 !important;
          background-color: #7cd2f1 !important;
        }

        .urlbarView-url {
          color: #dcbfc6 !important;
        }

        toolbar .toolbarbutton-1 {
          &:not([disabled]) {
            &:is([open], [checked])
              > :is(
                .toolbarbutton-icon,
                .toolbarbutton-text,
                .toolbarbutton-badge-stack
              ) {
              fill: #7cd2f1
            }
          }
        }

        .identity-color-blue {
          --identity-tab-color: #95e3ff !important;
          --identity-icon-color: #95e3ff !important;
        }

        .identity-color-turquoise {
          --identity-tab-color: #7cd2f1 !important;
          --identity-icon-color: #7cd2f1 !important;
        }

        .identity-color-green {
          --identity-tab-color: #a5ffaf !important;
          --identity-icon-color: #a5ffaf !important;
        }

        .identity-color-yellow {
          --identity-tab-color: #fff9a5 !important;
          --identity-icon-color: #fff9a5 !important;
        }

        .identity-color-orange {
          --identity-tab-color: #fff672 !important;
          --identity-icon-color: #fff672 !important;
        }

        .identity-color-red {
          --identity-tab-color: #ff9fbe !important;
          --identity-icon-color: #ff9fbe !important;
        }

        .identity-color-pink {
          --identity-tab-color: #a8e8ff !important;
          --identity-icon-color: #a8e8ff !important;
        }

        .identity-color-purple {
          --identity-tab-color: #0c556f !important;
          --identity-icon-color: #0c556f !important;
        }

        #zen-appcontent-navbar-container {
          background-color: #1b1114 !important;
        }

        #PanelUI-menu-button .toolbarbutton-icon,
        #downloads-button .toolbarbutton-icon,
        #unified-extensions-button .toolbarbutton-icon {
          fill: #7cd2f1 !important;
          color: #7cd2f1 !important;
        }

        #PanelUI-menu-button .toolbarbutton-badge-stack,
        #downloads-button .toolbarbutton-badge-stack,
        #unified-extensions-button .toolbarbutton-badge-stack {
          fill: #7cd2f1 !important;
          color: #7cd2f1 !important;
        }

        toolbar .toolbarbutton-1 > .toolbarbutton-icon {
          fill: #7cd2f1 !important;
        }
      '';

      # =======================================================================
      # BOOKMARKS
      # =======================================================================
      bookmarks = {
        force = true;
        settings = [
          {
            name = "Bookmarks Toolbar";
            toolbar = true;
            bookmarks = [
              {
                name = "Reddit";
                url = "https://www.reddit.com";
                tags = [ "social" ];
              }
              {
                name = "GitHub";
                url = "https://github.com";
                tags = [ "dev" ];
              }
              {
                name = "Proton Mail";
                url = "https://mail.proton.me";
                tags = [ "mail" ];
              }
            ];
          }
        ];
      };

      # =======================================================================
      # Pins
      # =======================================================================
      pinsForce = true;
      pins = {
        "Reddit" = {
          id = "fbe8aca9-6962-45eb-a099-0e7e18e9f25d";
          workspace = spaces."Development".id;
          url = "https://www.reddit.com";
          isEssential = true;
          position = 100;
        };
        "Github" = {
          id = "5baf8821-b060-4fad-ac22-7eca8c6a8fa6";
          workspace = spaces."Development".id;
          url = "https://github.com";
          isEssential = true;
          position = 200;
        };
        "Proton Mail" = {
          id = "2fd76732-5b69-4a78-9884-e8c7923c974d";
          workspace = spaces."Development".id;
          url = "https://mail.proton.me";
          isEssential = true;
          position = 300;
        };
        "Dev Tools" = {
          id = "d85a9026-1458-4db6-b115-346746bcc692";
          isGroup = true;
          isFolderCollapsed = false;
          editedTitle = true;
          position = 400;
        };
        "NixOS Packages" = {
          id = "f8dd784e-11d7-430a-8f57-7b05ecdb4c77";
          url = "https://search.nixos.org/packages";
          folderParentId = pins."Dev Tools".id;
          position = 401;
        };
        "NixOS Options" = {
          id = "92931d60-fd40-4707-9512-a57b1a6a3919";
          url = "https://search.nixos.org/options";
          folderParentId = pins."Dev Tools".id;
          position = 402;
        };
      };

      # =======================================================================
      # SEARCH ENGINES
      # =======================================================================
      search = {
        force = true;
        default = "ddg";
        privateDefault = "ddg";
        order = [
          "ddg"
          "nix-packages"
          "nix-options"
          "hm-options"
          "google-maps"
          "google"
        ];
        engines = {
          "ddg" = {
            name = "DuckDuckGo";
            urls = [ { template = "https://duckduckgo.com/?q={searchTerms}"; } ];
            icon = "https://duckduckgo.com/favicon.ico";
            definedAliases = [
              "@ddg"
              "@duck"
            ];
          };
          "nix-packages" = {
            name = "Nix Packages";
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "https://nixos.org/favicon.png";
            definedAliases = [
              "@pkgs"
              "@np"
            ];
          };
          "nix-options" = {
            name = "Nix Options";
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "https://nixos.org/favicon.png";
            definedAliases = [
              "@opts"
              "@no"
            ];
          };
          "hm-options" = {
            name = "HM Options";
            urls = [
              {
                template = "https://home-manager-options.extranix.com/";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "https://nixos.org/favicon.png";
            definedAliases = [
              "@hm"
              "@hmo"
            ];
          };
          "google-maps" = {
            name = "Google Maps";
            urls = [
              {
                template = "https://www.google.com/maps/search/{searchTerms}";
              }
            ];
            icon = "https://maps.google.com/favicon.ico";
            definedAliases = [
              "@maps"
              "@gmaps"
            ];
          };
          "google" = {
            name = "Google";
            urls = [
              {
                template = "https://www.google.com/search?q={searchTerms}";
              }
            ];
            icon = "https://www.google.com/favicon.ico";
            definedAliases = [
              "@g"
              "@google"
            ];
          };
          # Hide Bing
          "bing".metaData.hidden = true;
        };
      };

      # =======================================================================
      # SPACES
      # NOTE: Close Zen Browser before rebuilding after changing spaces.
      # UUIDs are stable — do not regenerate them.
      # =======================================================================
      spacesForce = true;

      spaces = {
        "General" = {
          id = "c5426a5d-1f57-4a83-aee5-826bddee55f2";
          position = 1000;
          icon = "🏠";
        };
        "Development" = {
          id = "f1d46ea6-e101-43e4-b532-d604c6660284";
          position = 2000;
          icon = "💻";
        };
        "Doomscroll" = {
          id = "2f0b642f-9a66-482c-adf7-ceef7d76d9fa";
          position = 3000;
          icon = "📱";
        };
      };
    };
  };
}
