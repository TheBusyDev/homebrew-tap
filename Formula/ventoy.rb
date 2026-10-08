class Ventoy < Formula
  desc "Create bootable USB drives files with ease (maintained by TheBusyDev)"
  homepage "https://www.ventoy.net"
  url "https://github.com/ventoy/Ventoy/releases/download/v1.1.17/ventoy-1.1.17-linux.tar.gz"
  sha256 "7fb4ed08cef6a6b4d39dd19260d8c80291a78dfdf9af7d461571e23cbbc43805"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on :linux

  def install
    # Install the full unpacked release into libexec.
    libexec.install Dir["*"]

    # Expose the CLI tools to user's PATH.
    libexec.glob("*.sh").each do |script|
      script = script.basename
      exec = script.to_s.delete_suffix(".sh").downcase

      (bin/exec).write <<~EOF
        #!/bin/bash
        cd "#{libexec}" && exec ./#{script} "$@"
      EOF
      (bin/exec).chmod 0755
    end

    # Symlink architecture-specific GUI binary.
    gui_exec = ""

    if Hardware::CPU.is_32_bit?
      gui_exec = "VentoyGUI.i386"
    elsif Hardware::CPU.intel?
      gui_exec = "VentoyGUI.x86_64"
    elsif Hardware::CPU.arm?
      gui_exec = "VentoyGUI.aarch64"
    end

    (bin/"ventoygui").write <<~EOF
      #!/bin/bash
      cd "#{libexec}" && exec ./#{gui_exec} "$@"
    EOF
    (bin/"ventoygui").chmod 0755
  end

  def caveats
    <<~EOS
      You can run the Ventoy GUI by calling:
      >>> ventoygui # sudo privileges may be required.
      Other scripts are exposed to user's PATH, you can discover them by running:
      >>> compgen -c | grep "ventoy"
    EOS
  end

  test do
    assert_path_exists libexec/"VentoyGUI.i386"
    assert_path_exists libexec/"VentoyGUI.x86_64"
    assert_path_exists libexec/"VentoyGUI.aarch64"
  end
end