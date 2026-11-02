# Patched build of Beacon. Same source as upstream v1.3.52 (e098990), plus one fix:
# borneygit/agent-beacon 798efd8 reads a Pi session's RFC3339 header timestamp as a
# whole string instead of its leading year, so polled sessions no longer start in 1970
# and are no longer deleted from the local history by retention.
class Beacon < Formula
  desc "Open-source endpoint agent for local AI runtime telemetry (patched build)"
  homepage "https://github.com/borneygit/agent-beacon"
  url "https://github.com/borneygit/agent-beacon/archive/798efd8c7674a3787386cfb9177a517eaf5d5163.tar.gz"
  version "1.3.52-fix1"
  sha256 "7e604b3533ecbb0791e38d41ddc1ad725be42685730bbe54dc474e39461eaac6"
  license "MIT"

  depends_on "go" => :build
  depends_on "asymptote-labs/tap/beacon-vector" if OS.mac?

  # beacon-otelcol is a large generated OpenTelemetry distribution whose code is unchanged
  # by the patch, so the upstream release binary is installed rather than rebuilt here.
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
    cli_dir = buildpath/"cli/beacon"

    # cli/beacon embeds the hooks binary, so hooks is built and placed first.
    system "go", "build", "-trimpath", "-o", "beacon-hooks", ".", chdir: hooks_dir.to_s
    cp hooks_dir/"beacon-hooks", cli_dir/"internal/embedded/hooks.bin"
    system "go", "build", "-trimpath", "-o", "beacon", ".", chdir: cli_dir.to_s

    bin.install cli_dir/"beacon"
    bin.install hooks_dir/"beacon-hooks"
    resource("otelcol").stage { bin.install "beacon-otelcol" }
  end

  def caveats
    <<~EOS
      This is a patched Beacon 1.3.52 (borneygit/agent-beacon 798efd8):
      a Pi session header's timestamp is read whole, so polled sessions keep their real
      start time instead of 1970 and survive the local history's retention.

      The patch is not upstream, so check "beacon version" after any "brew upgrade":
      asymptote-labs/tap ships an unpatched beacon under the same name, and a newer
      upstream version sorts above 1.3.52-fix1.
    EOS
  end

  test do
    system "#{bin}/beacon", "version"
  end
end
