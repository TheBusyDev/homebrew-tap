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
    # Determine target architecture.
    arch = if Hardware::CPU.is_32_bit?
      "i386"
    elsif Hardware::CPU.arm?
      "aarch64"
    elsif Hardware::CPU.intel?
      "x86_64"
    else
      "mips64el"
    end

    # Remove binaries for other architectures and rename the correct GUI binary.
    Dir.glob("VentoyGUI.*").each do |file|
      rm file unless file.end_with?(arch)
    end

    Dir.glob("tool/*").each do |dir|
      rm_r dir unless dir.end_with?(arch)
    end

    mv "VentoyGUI.#{arch}", "VentoyGUI"

    # Install the unpacked release into libexec.
    libexec.install Dir["*"]

    # Expose the CLI tools to user's PATH.
    libexec.glob("Ventoy{*.sh,GUI}").each do |exec_path|
      exec = exec_path.basename
      exec_name = exec.to_s.delete_suffix(".sh").downcase

      (bin/exec_name).write <<~EOF
        #!/bin/bash
        cd "#{libexec}" && exec ./#{exec} "$@"
      EOF
      (bin/exec_name).chmod 0755
    end
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
    assert_path_exists libexec/"VentoyGUI"
  end
end
