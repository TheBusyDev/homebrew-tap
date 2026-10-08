cask "ventoy" do
  arch arm: "aarch64", intel: "x86_64"
  os linux: "linux"

  version "1.1.17"
  sha256 "7fb4ed08cef6a6b4d39dd19260d8c80291a78dfdf9af7d461571e23cbbc43805"

  url "https://github.com/ventoy/Ventoy/releases/download/v#{version}/ventoy-#{version}-linux.tar.gz"
  name "ventoy"
  desc "Create bootable USB drives for ISO/WIM/IMG/VHD(x)/EFI files"
  homepage "https://www.ventoy.net/"

  livecheck do
    url :url
    strategy :github_latest
  end

  artifact "ventoygui.desktop",
           target: "#{Dir.home}/.local/share/applications/ventoygui.desktop"
  artifact "WebUI/static/img/VentoyLogo.png",
           target: "#{Dir.home}/.local/share/icons/ventoy.png"

  executables = %w[Ventoy2Disk.sh VentoyWeb.sh VentoyPlugson.sh VentoyGUI]

  executables.each do |exec|
    command_wrapper exec.delete_suffix(".sh").downcase,
                    content: <<~SH
                      #!/bin/bash
                      cd "#{staged_path}" && exec ./#{exec} "$@"
                    SH
  end

  preflight_steps do
    move_contents "ventoy-#{version}", "."
    remove "ventoy-#{version}"
    symlink "VentoyGUI.#{arch}", "VentoyGUI" # Create a symbolic link for the correct architecture.

    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file "ventoygui.desktop", <<~EOS
      [Desktop Entry]
      Name=Ventoy GUI
      Comment=Create bootable USB drives for ISO/WIM/IMG/VHD(x)/EFI files.
      Exec={{HOMEBREW_PREFIX}}/bin/ventoygui
      Icon=ventoy
      Keywords=usb;iso;bootable;
      StartupNotify=true
      Terminal=false
      Type=Application
      X-Categories=Utilities;
    EOS
  end

  caveats do
    <<~EOS
      You can run the Ventoy GUI by calling:
      >>> ventoygui # sudo privileges may be required.
      Other scripts are exposed to user's PATH, you can discover them by running:
      >>> compgen -c | grep "ventoy"
    EOS
  end
end
