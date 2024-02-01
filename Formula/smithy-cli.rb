class SmithyCli < Formula
  desc "Smithy CLI - A CLI for building, validating, querying, and iterating on Smithy models"
  homepage "https://smithy.io"


  livecheck do
    url :stable
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  # Default to macos-x86
  platform = OS.mac? ? "darwin" : "linux"
  arch = Hardware::CPU.intel? ? "x86_64" : "aarch64"

  version `curl -L -s https://github.com/smithy-lang/smithy/releases/latest/download/VERSION`.strip
  url "https://github.com/smithy-lang/smithy/releases/latest/download/smithy-cli-#{platform}-#{arch}.zip"
  sha256 `curl -L -s https://github.com/smithy-lang/smithy/releases/latest/download/smithy-cli-#{platform}-#{arch}.zip.sha256`.split(' ').first

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
    system "#{bin}/smithy" " warmup"
    puts "Successfully installed smithy: #{`#{bin}/smithy --version`}"
  end

  test do
    assert_predicate lib/smithy.jsa, :exist?
    assert_match version, shell_output("#{bin}/smithy --version")
    assert_match "Usage: smithy", shell_output("#{bin}/smithy --help")
  end

end
