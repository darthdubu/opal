class Opal < Formula
  desc "AI-native terminal emulator for macOS"
  homepage "https://opal.sh"
  url "https://github.com/opal-terminal/opal/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license any_of: ["MIT", "Apache-2.0"]

  depends_on "rust" => :build
  depends_on macos: :sonoma

  def install
    # Build Rust components
    system "cargo", "build", "--release"

    # Build Swift app
    system "./build.sh"

    # Install the app bundle
    prefix.install "Opal.app"

    # Create a binary symlink for CLI access
    bin.install_symlink prefix/"Opal.app/Contents/MacOS/Opal" => "opal"
  end

  def caveats
    <<~EOS
      Opal has been installed to:
        #{prefix}/Opal.app

      To start using Opal from the command line, run:
        opal

      Or launch the app from your Applications folder.

      For first-time setup, you may want to configure your AI provider:
        opal --configure
    EOS
  end

  test do
    assert_predicate prefix/"Opal.app", :exist?
    assert_match "Opal Terminal v1.0.0", shell_output("#{bin}/opal --version")
  end
end
