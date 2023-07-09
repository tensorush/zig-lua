const std = @import("std");

pub fn build(b: *std.Build) std.zig.system.NativeTargetInfo.DetectError!void {
    const target = b.standardTargetOptions(.{});
    const version = .{ .major = 5, .minor = 4, .patch = 6 };
    const target_info = try std.zig.system.NativeTargetInfo.detect(target);

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib_flags = FLAGS ++ .{switch (target_info.target.os.tag) {
        .linux => "-DLUA_USE_LINUX",
        .macos => "-DLUA_USE_MACOSX",
        .windows => "-DLUA_USE_WINDOWS",
        .ios => "-DLUA_USE_IOS",
        else => "-DLUA_USE_POSIX",
    }};

    const lib = b.addStaticLibrary(.{
        .name = "lua",
        .version = version,
        .target = target,
        .optimize = .Debug,
        .link_libc = true,
    });
    lib.addCSourceFiles(&(CORE_FILES ++ LIB_FILES), &lib_flags);
    lib.linkSystemLibrary("readline");

    const lib_install = b.addInstallArtifact(lib);
    lib_step.dependOn(&lib_install.step);
    b.default_step.dependOn(lib_step);

    // Lua interpreter
    const lua_step = b.step("lua", "Install Lua interpreter");

    const lua = b.addExecutable(.{
        .name = "lua",
        .version = version,
        .target = target,
        .optimize = .Debug,
        .link_libc = true,
    });
    lua.addCSourceFiles(&(.{"lua/lua.c"} ++ CORE_FILES ++ LIB_FILES), &lib_flags);
    lua.linkSystemLibrary("readline");

    const lua_install = b.addInstallArtifact(lua);
    lua_step.dependOn(&lua_install.step);
    b.default_step.dependOn(lua_step);

    // Tests
    const tests_step = b.step("test", "Run tests");
    tests_step.dependOn(&lua_install.step);

    const test_flags = .{ "-Wall", "-std=gnu99", "-O2" };

    inline for (TEST_LIB_FILES) |TEST_LIB_FILE| {
        var name = std.fs.path.stem(TEST_LIB_FILE)[3..];
        if (name.len > 1 and name[1] == '2') {
            name = "2-v2";
        }
        const test_lib = b.addSharedLibrary(.{
            .name = name,
            .target = target,
            .optimize = .Debug,
            .link_libc = true,
        });
        test_lib.addCSourceFiles(&(.{"lua/lua.c"} ++ CORE_FILES ++ LIB_FILES ++ .{TEST_LIB_FILE}), &test_flags);
        if (test_lib.name.len > 1) {
            if (test_lib.name[0] == '1') {
                test_lib.addCSourceFile(TEST_LIB_FILES[0], &test_flags);
            } else if (test_lib.name[1] == '1') {
                test_lib.addCSourceFile(TEST_LIB_FILES[1], &test_flags);
            }
        }
        test_lib.addIncludePath("lua");
        test_lib.force_pic = true;

        const test_lib_install = b.addInstallArtifact(test_lib);
        tests_step.dependOn(&test_lib_install.step);
    }

    b.default_step.dependOn(tests_step);
}

const FLAGS = .{
    "-Wall",
    "-O2",
    "-Wfatal-errors",
    "-Wextra",
    "-Wshadow",
    "-Wundef",
    "-Wwrite-strings",
    "-Wredundant-decls",
    "-Wdisabled-optimization",
    "-Wdouble-promotion",
    "-Wmissing-declarations",
    "-Wdeclaration-after-statement",
    "-Wmissing-prototypes",
    "-Wnested-externs",
    "-Wstrict-prototypes",
    "-Wc++-compat",
    "-Wold-style-definition",
    "-std=c99",
    "-DLUA_USE_READLINE",
    "-fno-stack-protector",
    "-fno-common",
    "-march=native",
};

const CORE_FILES = .{
    "lua/lapi.c",
    "lua/lcode.c",
    "lua/lctype.c",
    "lua/ldebug.c",
    "lua/ldo.c",
    "lua/ldump.c",
    "lua/lfunc.c",
    "lua/lgc.c",
    "lua/llex.c",
    "lua/lmem.c",
    "lua/lobject.c",
    "lua/lopcodes.c",
    "lua/lparser.c",
    "lua/lstate.c",
    "lua/lstring.c",
    "lua/ltable.c",
    "lua/ltests.c",
    "lua/ltm.c",
    "lua/lundump.c",
    "lua/lvm.c",
    "lua/lzio.c",
};

const LIB_FILES = .{
    "lua/lauxlib.c",
    "lua/lbaselib.c",
    "lua/lcorolib.c",
    "lua/ldblib.c",
    "lua/linit.c",
    "lua/liolib.c",
    "lua/lmathlib.c",
    "lua/loadlib.c",
    "lua/loslib.c",
    "lua/lstrlib.c",
    "lua/ltablib.c",
    "lua/lutf8lib.c",
};

const TEST_LIB_FILES = .{
    "lua/testes/libs/lib1.c",
    "lua/testes/libs/lib2.c",
    "lua/testes/libs/lib11.c",
    "lua/testes/libs/lib21.c",
    "lua/testes/libs/lib22.c",
};
