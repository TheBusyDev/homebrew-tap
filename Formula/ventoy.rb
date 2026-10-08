class Ventoy < Formula
  desc "Create bootable USB drives for ISO/WIM/IMG/VHD(x)/EFI files (maintained by TheBusyDev)"
  homepage "https://www.ventoy.net"
  url "https://github.com/ventoy/Ventoy/releases/download/v1.1.05/ventoy-1.1.05-linux.tar.gz"
  sha256 "3379c99890359dcff55aab7f7b3286f87c988d1da2fd616e6a9e305fb0a1de9e"
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
    EOS
  end

  test do
    assert_predicate libexec/"VentoyGUI.i386", :exist?
    assert_predicate libexec/"VentoyGUI.x86_64", :exist?
    assert_predicate libexec/"VentoyGUI.aarch64", :exist?
  end
end