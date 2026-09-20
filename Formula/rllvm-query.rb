class RllvmQuery < Formula
  desc "Source-level queries over LLVM bitcode captured by rllvm"
  homepage "https://shengtuo.me/rllvm/"
  # rllvm-query ships on its own component tag, separate from the `rllvm`
  # formula's: dist announces one release per component.
  url "https://github.com/h1994st/rllvm/releases/download/rllvm-query-v0.6.0/source.tar.gz"
  sha256 "4874d784f40d0ca1216e0cd7d195d99f65b0d70a8347b1890f221f4df30e60e4"
  license "Apache-2.0"
  head "https://github.com/h1994st/rllvm.git", branch: "main"

  bottle do
    root_url "https://github.com/h1994st/homebrew-tap/releases/download/rllvm-query-0.6.0"
    sha256 cellar: :any, arm64_sequoia: "cb2cd04b29ffec24211177aeedd8a63051d96c990125ba71be270a60f8813810"
  end

  depends_on "rust" => :build
  # Not build-only: this is the signal to rebuild when Homebrew's LLVM changes
  # major. rllvm-query links LLVM statically and can only read bitcode from the
  # major it was built against, so a stale build silently stops reading
  # catalogs produced by a newer clang.
  depends_on "llvm"

  # LLVM's own libraries, which `llvm-sys` links statically into this binary.
  # `brew linkage --test` fails a library the binary links but the formula does
  # not declare, and test-bot then discards the bottle it had already built and
  # still exits 0 -- so the tap's CI goes green with no bottle to publish, and
  # only `brew pr-pull` reports it.
  #
  # The conditions mirror homebrew-core's llvm.rb, because what that formula
  # links decides what ends up linked here. `uses_from_macos "zlib"` does not
  # stand in for the Linux entry: linkage still reported zlib-ng-compat, and
  # the x86_64_linux bottle was dropped for it.
  depends_on "zstd"

  on_system :linux, macos: :sonoma_or_newer do
    depends_on "z3"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def fetch
    system "cargo", "fetch", "--locked"
  end

  def install
    # llvm-sys names this variable after the requirement it is pinned to:
    # `llvm-sys = "231"` in crates/query/Cargo.toml. Both move together.
    ENV["LLVM_SYS_231_PREFIX"] = formula_opt_prefix("llvm")
    system "cargo", "install", *std_cargo_args(path: "crates/query")
    generate_completions_from_executable(bin/"rllvm-query", "completions")
  end

  test do
    # A catalog is the only input a query takes, and building one needs the
    # wrapper binaries from the `rllvm` formula, which this formula does not
    # depend on. So the test stops at what this binary can answer alone.

    # The claim `depends_on "llvm"` makes: the binary reads bitcode from the
    # major it linked, and that major is the keg on disk. The installed
    # version, not the declared one, which `brew update` moves while the keg
    # this binary was built against stays where it is.
    assert_equal Formula["llvm"].any_installed_version.major.to_s,
                 shell_output("#{bin}/rllvm-query --llvm-version").split(".").first

    # The completion scripts `install` generates come from the same CLI
    # definition, so a real subcommand has to appear in them.
    assert_match "indirect-targets", shell_output("#{bin}/rllvm-query completions bash")
  end
end
