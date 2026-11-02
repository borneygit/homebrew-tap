class Beacon < Formula
  desc "Open-source endpoint agent for local AI runtime telemetry (patched build)"
  homepage "https://github.com/borneygit/agent-beacon"
  url "https://github.com/borneygit/agent-beacon/archive/798efd8c7674a3787386cfb9177a517eaf5d5163.tar.gz"
  version "1.3.52-fix1-debug1"
  sha256 "7e604b3533ecbb0791e38d41ddc1ad725be42685730bbe54dc474e39461eaac6"
  license "MIT"

  depends_on "go" => :build
  depends_on "asymptote-labs/tap/beacon-vector" if OS.mac?

  resource "otelcol" do
    on_macos do
      on_arm do
        url "https://github.com/asymptote-labs/agent-beacon/releases/download/v1.3.52/beacon_1.3.52_darwin_arm64.tar.gz"
        sha256 "db44e57efb5689a6cb7677d6e614a8ce4daf93c4d2c71ab52e4502025935a3b8"
      end
    end
  end

  def install
    ENV["GOTOOLCHAIN"] = "auto"
    hooks_dir = buildpath/"cli/beacon-hooks"
    ohai "buildpath: #{buildpath}"
    ohai "hooks_dir: #{hooks_dir}"
    system "sh", "-c", "pwd; ls #{buildpath} | head -5; ls #{hooks_dir} | head -5; go env GO111MODULE GOFLAGS GOMOD"
    system "go", "build", "-trimpath", "-o", "beacon-hooks", ".", chdir: hooks_dir.to_s
    cp hooks_dir/"beacon-hooks", buildpath/"cli/beacon/internal/embedded/hooks.bin"
    system "go", "build", "-trimpath", "-o", "beacon", ".", chdir: (buildpath/"cli/beacon").to_s
    bin.install buildpath/"cli/beacon/beacon"
    bin.install hooks_dir/"beacon-hooks"
    resource("otelcol").stage { bin.install "beacon-otelcol" }
  end

  test do
    system "#{bin}/beacon", "version"
  end
end
