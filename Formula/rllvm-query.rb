class RllvmQuery < Formula
  desc "Source-level queries over LLVM bitcode captured by rllvm"
  homepage "https://shengtuo.me/rllvm/"
  # rllvm-query ships on its own component tag, separate from the `rllvm`
  # formula's: dist announces one release per component. No release exists at
  # `rllvm-query-v0.5.1`, so this url does not resolve, and the sha256 is
  # borrowed from `rllvm.rb`'s `v0.5.1` tarball: a real digest of a real tree,
  # but not of the asset named here, which dist would pack under its own
  # archive root and so hash differently. Both are placeholders the first bump
  # replaces. Starting a version behind is deliberate: `bump.yml` skips a bump
  # whose version already matches the url, so a 0.6.0 placeholder would stay.
  url "https://github.com/h1994st/rllvm/releases/download/rllvm-query-v0.5.1/source.tar.gz"
  sha256 "83efceab29b13492cabaad1b6adcaf62680f4ef3d3944ef92a4ecef67338023c"
  license "Apache-2.0"
  head "https://github.com/h1994st/rllvm.git", branch: "main"

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
  # only `brew pr-pull` reports it. Linux reaches zlib through zlib-ng-compat
  # and links no z3.
  depends_on "zstd"
  uses_from_macos "zlib"

  on_macos do
    depends_on "z3"
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
