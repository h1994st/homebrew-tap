class Rllvm < Formula
  desc "Compiler wrappers for building whole-program LLVM bitcode files"
  homepage "https://shengtuo.me/rllvm/"
  url "https://github.com/h1994st/rllvm/releases/download/v0.4.6/source.tar.gz"
  sha256 "f9cf3c966e817d3d54cfaa70ca8a5973a0b81ac65178e11a4f5a972fd9b0ee53"
  license "Apache-2.0"
  head "https://github.com/h1994st/rllvm.git", branch: "main"

  bottle do
    root_url "https://github.com/h1994st/homebrew-tap/releases/download/rllvm-0.4.4"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "2737ff7ca2adce3bf99dc274c4845cb042954975dac2a7421a86688c10256b0b"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "5cc3d50209266ea93389595bd1b0ac83aac86a076e0cc32803efa83c51260fb9"
    sha256 cellar: :any,                 x86_64_linux:  "2f61f93041357a5f81d444ee3aa0939dd8048ca6669fcb05804c8af5014d402f"
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
