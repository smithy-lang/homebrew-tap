# -*- coding: utf-8 -*-
require_relative '../ConfigProvider/config_provider'

class SmithyCli < Formula
    $config_provider = ConfigProvider.new('smithy-cli')
    desc "Smithy CLI - A CLI for building, validating, querying, and iterating on Smithy models"
    homepage "https://smithy.io"
    version $config_provider.version

    # We ship a self-contained Java runtime image whose dylibs already use
    # `@rpath` install names. Homebrew would otherwise rewrite those ids to
    # absolute Cellar paths, which also invalidates their ad-hoc signatures.
    preserve_rpath

    if OS.mac?
      if Hardware::CPU.intel?
        url "#{$config_provider.root_url}-darwin-x86_64.zip"
        sha256 $config_provider.sierra_hash
      elsif Hardware::CPU.arm?
        url "#{$config_provider.root_url}-darwin-aarch64.zip"
        sha256 $config_provider.arm64_big_sur_hash
      end
    elsif OS.linux?
      if Hardware::CPU.intel?
        url "#{$config_provider.root_url}-linux-x86_64.zip"
        sha256 $config_provider.linux_hash
      elsif Hardware::CPU.arm?
        url "#{$config_provider.root_url}-linux-aarch64.zip"
        sha256 $config_provider.linux_arm_hash
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

    post_install_steps do
        # call warmup command to generate the jsa
        run "smithy", args: ["warmup"], base: :bin
    end

    test do
        assert_predicate lib/"#{$config_provider.bin}.jsa", :exist?
        assert_match $config_provider.version, shell_output("#{bin}/#{$config_provider.bin} --version")
        assert_match "Usage: #{$config_provider.bin}", shell_output("#{bin}/#{$config_provider.bin} --help")
    end
end
