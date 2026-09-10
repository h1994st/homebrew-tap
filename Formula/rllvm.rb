class Rllvm < Formula
  desc "Compiler wrappers for building whole-program LLVM bitcode files"
  homepage "https://shengtuo.me/rllvm/"
  url "https://github.com/h1994st/rllvm/releases/download/v0.4.7/source.tar.gz"
  sha256 "1d557c5160e89887a536a32ce3a02c1ef982a68f8a91a6d09f0e0446d4e1e35a"
  license "Apache-2.0"
  head "https://github.com/h1994st/rllvm.git", branch: "main"

  bottle do
    root_url "https://github.com/h1994st/homebrew-tap/releases/download/rllvm-0.4.7"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "f30d2cca2c1785e09b333fe4b2ae96789bcdd3ee7ad62949b817360658afb737"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "6fadd04cdb447c73330e178ce9ef918a1b44ace9fc7acdd884435fdd275ee228"
    sha256 cellar: :any,                 x86_64_linux:  "1d920a8c0d2e7053535c8e93d54ff97cdcb328f484daf8bbebc50e928f3223bf"
  end

  depends_on "rust" => [:build, :test]
  depends_on "llvm" => :test

  def fetch
    system "cargo", "fetch", "--locked"
  end

  def install
    system "cargo", "install", *std_cargo_args

    completions = {
      "cc"          => "rllvm-cc",
      "cxx"         => "rllvm-cxx",
      "get-bc"      => "rllvm-get-bc",
      "init"        => "rllvm-init",
      "info"        => "rllvm-info",
      "rustc"       => "rllvm-rustc",
      "completions" => "rllvm-completions",
    }
    completions.each do |flag, exe|
      generate_completions_from_executable(bin/"rllvm-completions", "--bin", flag,
                                           base_name:              exe,
                                           shell_parameter_format: :arg)
    end
  end

  test do
    ENV.prepend_path "PATH", formula_opt_bin("llvm")

    ENV["RLLVM_CONFIG"] = testpath/"config.toml"
    system bin/"rllvm-init", "--llvm-prefix", formula_opt_prefix("llvm")
    assert_path_exists testpath/"config.toml"

    (testpath/"add.c").write <<~C
      int add(int a, int b) { return a + b; }
    C
    (testpath/"main.c").write <<~C
      int add(int, int);
      int main(void) { return add(2, 3) - 5; }
    C

    system bin/"rllvm-cc", "-c", "-o", "add.o", "add.c"
    system bin/"rllvm-cc", "-c", "-o", "main.o", "main.c"
    system bin/"rllvm-cc", "-o", "prog", "add.o", "main.o"

    system "./prog"

    system bin/"rllvm-get-bc", "prog"
    assert_path_exists testpath/"prog.bc"

    info = shell_output("#{bin}/rllvm-info --functions #{testpath}/prog.bc")
    assert_match "add", info
    assert_match "main", info

    (testpath/"lib.rs").write "pub fn answer() -> i32 { 42 }\n"
    system bin/"rllvm-rustc", formula_opt_bin("rust")/"rustc",
           "--crate-type", "lib", "--crate-name", "demo",
           "--out-dir", testpath, "lib.rs"
    assert_path_exists testpath/"libdemo.rlib"

    system bin/"rllvm-get-bc", "libdemo.rlib", "-o", "whole_demo.bc"
    assert_match "answer",
                 shell_output("#{bin}/rllvm-info --functions #{testpath}/whole_demo.bc")

    assert_match version.to_s, shell_output("#{bin}/rllvm-cc --rllvm-version")
  end
end
