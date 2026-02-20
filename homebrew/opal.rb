class Opal < Formula
  desc "A beautiful, lightning fast terminal for macOS with Liquid Glass design"
  homepage "https://github.com/opal-terminal/opal"
  url "https://github.com/opal-terminal/opal/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "TODO: Add SHA256 after first release"
  license "MIT OR Apache-2.0"
  
  depends_on "rust" => :build
  
  def install
    system "cargo", "install", "--locked", "--root", prefix
  end
  
  test do
    system "#{bin}/opal", "--version"
  end
end
