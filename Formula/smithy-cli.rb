require_relative "../ConfigProvider/config_provider"

class SmithyCli < Formula
  CONFIG = ConfigProvider.new("smithy-cli").freeze

  desc "Smithy CLI - A CLI for building, validating, querying, and iterating on Smithy models"
  homepage "https://smithy.io"
  version CONFIG.version

  # We ship a self-contained runtime image, so keep the `@rpath` dylib ids the
  # release archives already carry instead of letting Homebrew rewrite them to
  # absolute Cellar paths (which also invalidates their ad-hoc signatures).
  preserve_rpath

  if OS.mac?
    if Hardware::CPU.intel?
      url "#{CONFIG.root_url}-darwin-x86_64.zip"
      sha256 CONFIG.sierra_hash
    elsif Hardware::CPU.arm?
      url "#{CONFIG.root_url}-darwin-aarch64.zip"
      sha256 CONFIG.arm64_big_sur_hash
    end
  elsif OS.linux?
    if Hardware::CPU.intel?
      url "#{CONFIG.root_url}-linux-x86_64.zip"
      sha256 CONFIG.linux_hash
    elsif Hardware::CPU.arm?
      url "#{CONFIG.root_url}-linux-aarch64.zip"
      sha256 CONFIG.linux_arm_hash
    end
  end

  def install
    # install everything in archive into libexec, so that
    # the contents are private to homebrew, which means it won't try
    # to symlink anything in this directory automatically
    libexec.install Dir["*"]
    # create a symlink to the private executable
    bin.install_symlink "#{libexec}/bin/smithy" => "smithy"
  end

  # call warmup command to generate the jsa
  post_install_steps do
    run "smithy", args: ["warmup"], base: :bin
  end

  test do
    assert_path_exists lib/"#{CONFIG.bin}.jsa"
    assert_match CONFIG.version, shell_output("#{bin}/#{CONFIG.bin} --version")
    assert_match "Usage: #{CONFIG.bin}", shell_output("#{bin}/#{CONFIG.bin} --help")
  end
end
