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
    bin.install_symlink libexec/"Ventoy2Disk.sh" => "ventoy2disk"
    bin.install_symlink libexec/"VentoyWeb.sh" => "ventoyweb"

    # Symlink architecture-specific GUI binary.
    if Hardware::CPU.intel? && Hardware::CPU.is_64_bit?
      bin.install_symlink libexec/"VentoyGUI.x86_64" => "ventoygui"
    elsif Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      bin.install_symlink libexec/"VentoyGUI.aarch64" => "ventoygui"
    end
  end

  def caveats
    <<~EOS
      Ventoy may require root privileges to run.
    EOS
  end

  test do
    assert_predicate libexec/"Ventoy2Disk.sh", :exist?
    assert_predicate libexec/"VentoyWeb.sh", :exist?
    assert_predicate libexec/"VentoyGUI.x86_64", :exist?
    assert_predicate libexec/"VentoyGUI.aarch64", :exist?
  end
end