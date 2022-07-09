{ config, pkgs, lib, ... }:

let

in {
  imports = [
    "${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/3bf48d3587d3f34f745a19ebc968b002ef5b5c5a.tar.gz" }/raspberry-pi/4"
    "${fetchTarball "https://github.com/musnix/musnix/archive/7fb04384544fa2e68bf5e71869760674656b62e8.tar.gz"}"
  ];

  nix.package = pkgs.nix_2_3;
  system.stateVersion = "22.11";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    hostName = "muzberry";
    wireless = {
      enable = true;
      networks."Lofoten-5Ghz".psk = "Oslo1234";
      interfaces = [ "wlan0" ];
    };
  };

  services.openssh.enable = true;

  users = {
    mutableUsers = false;
    users."ezemtsov" = {
      isNormalUser = true;
      password = "";
      extraGroups = [ "wheel" "audio" ];
    };
    defaultUserShell = pkgs.fish;
  };
  security.sudo.wheelNeedsPassword = false;

  boot = {
    kernelParams = [ "usbhid.mousepoll=0" ];
    kernelPackages = pkgs.linuxPackages_rpi4.extend (lself: lsuper: {
      kernel = lsuper.kernel.override {
        argsOverride = {
          version = "5.15.32-rt39-1.20220331";
          modDirVersion = "5.15.32-rt39";
        };
      };
    });
    kernelPatches = [
      {
        name = "rt-linux";
        patch = builtins.fetchurl {
          url = "https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/5.15/older/patch-5.15.32-rt39.patch.xz";
          sha256 = "1pd42vrrfhfan3drpaws3jcwgd7yc14fi8flb2127lw2xdfrijb8";
        };
      }
    ];
  };

  # Enable GPU acceleration
  hardware.raspberry-pi."4" = {
    fkms-3d.enable = true;
    dwc2.enable = true;
    audio.enable = true;
  };

  services.xserver = {
    enable = true;
    windowManager.i3.enable = true;
    displayManager.autoLogin = {
      enable = true;
      user = "ezemtsov";
    };
  };

  fonts = {
    fonts = with pkgs; [
      corefonts
      dejavu_fonts
      source-code-pro
    ];
  };

  documentation.enable = false;
  environment.variables = {
    TERMINAL = "termite";
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    emacs
    termite
    chromium
    (renoise.overrideAttrs (old: {
      src = fetchTarball "https://files.renoise.com/demo/Renoise_3_4_2_Demo_Linux_arm64.tar.gz";
      buildInputs = old.buildInputs ++ [ mpg123 xorg.libXtst xorg.libXinerama ];
      nativeBuildInputs = [ autoPatchelfHook ];
      meta.platform = old.meta.platform ++ [ "aarch64-linux" ];
    }))
  ];

  sound.enable = true;
  musnix.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    # config.pipewire = {
    #   "context.properties" = {
    #     "link.max-buffers" = 16;
    #     "log.level" = 2;
    #     "default.clock.rate" = 48000;
    #     "default.clock.quantum" = 32;
    #     "default.clock.mine-quantum" = 32;
    #     "default.clock.max-quantum" = 32;
    #     "core.daemon" = true;
    #     "core.name" = "pipewire-0";
    #   };
    #   "context.modules" = [
    #     {
    #       name = "libpipewire-module-rtkit";
    #       args = {
    #         "nice.level" = -15;
    #         "rt.prio" = 88;
    #         "rt.time.soft" = 200000;
    #         "rt.time.hard" = 200000;
    #       };
    #       flags = [ "ifexists" "nofail" ];
    #     }
    #     { name = "libpipewire-module-protocol-native"; }
    #     { name = "libpipewire-module-profiler"; }
    #     { name = "libpipewire-module-metadata"; }
    #     { name = "libpipewire-module-spa-device-factory"; }
    #     { name = "libpipewire-module-spa-node-factory"; }
    #     { name = "libpipewire-module-client-node"; }
    #     { name = "libpipewire-module-client-device"; }
    #     {
    #       name = "libpipewire-module-portal";
    #       flags = [ "ifexists" "nofail" ];
    #     }
    #     {
    #       name = "libpipewire-module-access";
    #       args = {};
    #     }
    #     { name = "libpipewire-module-adapter"; }
    #     { name = "libpipewire-module-link-factory"; }
    #     { name = "libpipewire-module-session-manager"; }
    #   ];
    # };
  };
}
