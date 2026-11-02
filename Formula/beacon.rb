# Patched build of Beacon: upstream v1.3.52 (e098990) plus one fix.
#
# borneygit/agent-beacon 798efd8 reads a Pi session's RFC3339 header timestamp as a whole
# string. Before it, the leading "2026" was read as epoch seconds, so session.started
# became 1970-01-01T00:33:46Z, every polled session's trace started in 1970, and the local
# history's retention deleted those sessions on the next ingest.
class Beacon < Formula
  desc "Open-source endpoint agent for local AI runtime telemetry (patched build)"
  homepage "https://github.com/borneygit/agent-beacon"
  url "https://github.com/borneygit/agent-beacon/archive/798efd8c7674a3787386cfb9177a517eaf5d5163.tar.gz"
  version "1.3.52-fix1"
  sha256 "7e604b3533ecbb0791e38d41ddc1ad725be42685730bbe54dc474e39461eaac6"
  license "MIT"

  depends_on "go" => :build
  depends_on "asymptote-labs/tap/beacon-vector" if OS.mac?

  # beacon-otelcol is a large generated OpenTelemetry distribution whose code the patch does
  # not touch, so the upstream release binary is installed instead of rebuilding it here.
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

    # The project's own Makefile builds the hooks binary and embeds it in the CLI, which is
    # the order the CLI needs. The version stamped into the binary is upstream's, so version
    # comparisons and the self-updater's health check keep working; the commit names the build.
    system "sh", "-c", "cd cli/beacon && make build VERSION=1.3.52 GIT_COMMIT=798efd8"

    bin.install "cli/beacon/beacon"
    bin.install "cli/beacon-hooks/beacon-hooks"
    resource("otelcol").stage { bin.install "beacon-otelcol" }
  end

  def caveats
    <<~EOS
      Patched build: Beacon 1.3.52 with borneygit/agent-beacon 798efd8, which keeps a Pi
      session's real start time so polled sessions stay in the local history.

      Not upstream, so check the build after any "brew upgrade": asymptote-labs/tap ships an
      unpatched beacon under the same name, and a newer upstream version sorts above this one.
      "beacon version" prints the commit this build came from.
    EOS
  end

  test do
    assert_match "1.3.52", shell_output("#{bin}/beacon version")
  end
end
