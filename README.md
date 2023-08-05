## :lizard: :crescent_moon: **zig lua**

[![CI][ci-shield]][ci-url]
[![License][license-shield]][license-url]

### Zig build of the [Lua repository](https://github.com/lua/lua) created by [Roberto Ierusalimschy](https://github.com/roberto-ieru).

#### :rocket: Usage

1. Add `lua` as a dependency in your `build.zig.zon`.

    <details>

    <summary><code>build.zig.zon</code> example</summary>

    ```zig
    .{
        .name = "<name_of_your_package>",
        .version = "<version_of_your_package>",
        .dependencies = .{
            .lua = .{
                .url = "https://github.com/tensorush/zig-lua/archive/<git_tag_or_commit_hash>.tar.gz",
                .hash = "<package_hash>",
            },
        },
    }
    ```

    Set `<package_hash>` to `12200000000000000000000000000000000000000000000000000000000000000000`, and Zig will provide the correct found value in an error message.

    </details>

2. Add `lua` as a module in your `build.zig`.

    <details>

    <summary><code>build.zig</code> example</summary>

    ```zig
    const lua = b.dependency("lua", .{});
    exe.addModule("lua", lua.artifact("lua"));
    ```

    </details>

<!-- MARKDOWN LINKS -->

[ci-shield]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-lua/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/zig-lua/blob/main/.github/workflows/ci.yaml
[license-shield]: https://img.shields.io/github/license/tensorush/zig-lua.svg?style=for-the-badge&labelColor=black
[license-url]: https://github.com/tensorush/zig-lua/blob/main/LICENSE.md
