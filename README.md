# homebrew-tap

Homebrew formulae for [h1994st](https://github.com/h1994st)'s projects.

## Usage

Tap once, then install by name:

```bash
brew tap h1994st/tap
brew install rllvm
```

Or install directly, without tapping first:

```bash
brew install h1994st/tap/rllvm
```

## Formulae

| Formula | Description |
| --- | --- |
| [`rllvm`](Formula/rllvm.rb) | Compiler wrappers for building whole-program LLVM bitcode files ([repository](https://github.com/h1994st/rllvm)) |

## Bottles

Bottles are built by [CI](.github/workflows/tests.yml) on every pull request and
[published](.github/workflows/publish.yml) to a release per version, named
`<formula>-<version>`.
Without one for your platform, Homebrew builds from source, which needs a Rust
toolchain and takes a few minutes.

## License

[Apache-2.0](LICENSE)
