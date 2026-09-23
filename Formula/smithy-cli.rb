require_relative "../ConfigProvider/config_provider"

class SmithyCli < Formula
  CONFIG = ConfigProvider.new("smithy-cli").freeze

  desc "Smithy CLI - A CLI for building, validating, querying, and iterating on Smithy models"
  homepage "https://smithy.io"
  version CONFIG.version

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

  def post_install
    # brew relocates dylibs and assigns different ids, which is problematic since
    # we package a runtime image ourselves
    if OS.mac?
      Dir["#{libexec}/lib/**/*.dylib"].each do |dylib|
        chmod 0664, dylib
        MachO::Tools.change_dylib_id(dylib, "@rpath/#{File.basename(dylib)}")
        # we also need to resign the dylibs, so that their ad-hoc signatures are not invalid
        MachO.codesign!(dylib)
        chmod 0444, dylib
      end
    end
    # call warmup command to generate the jsa
    system "#{bin}/#{CONFIG.bin}" + " warmup"
  end

  test do
    assert_path_exists lib/"#{CONFIG.bin}.jsa"
    assert_match CONFIG.version, shell_output("#{bin}/#{CONFIG.bin} --version")
    assert_match "Usage: #{CONFIG.bin}", shell_output("#{bin}/#{CONFIG.bin} --help")
  end
end
