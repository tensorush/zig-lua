const std = @import("std");

pub fn build(b: *std.Build) std.zig.system.NativeTargetInfo.DetectError!void {
    const target = b.standardTargetOptions(.{});
    const version = .{ .major = 5, .minor = 4, .patch = 6 };
    const target_info = try std.zig.system.NativeTargetInfo.detect(target);

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addStaticLibrary(.{
        .name = "lua",
        .version = version,
        .target = target,
        .optimize = .ReleaseSafe,
        .link_libc = true,
    });
    lib.addCSourceFiles(&(CORE_FILES ++ LIB_FILES), &.{});

    const lib_install = b.addInstallArtifact(lib);
    lib_step.dependOn(&lib_install.step);
    b.default_step.dependOn(lib_step);

    // Lua interpreter
    const lua_step = b.step("lua", "Install Lua interpreter");

    const lua = b.addExecutable(.{
        .name = "lua",
        .version = version,
        .root_source_file = std.Build.FileSource.relative("lua/lua.c"),
        .target = target,
        .optimize = .ReleaseFast,
        .link_libc = true,
    });
    lua.defineCMacro(switch (target_info.target.os.tag) {
        .linux => "LUA_USE_LINUX",
        .macos => "LUA_USE_MACOSX",
        .windows => "", // will be automatically defined in lua/luaconf.h
        .ios => "LUA_USE_IOS",
        else => "LUA_USE_POSIX",
    }, null);
    lua.defineCMacro("LUA_USE_READLINE", null);
    lua.addCSourceFiles(&(CORE_FILES ++ LIB_FILES), &FLAGS);
    lua.linkSystemLibrary("readline");

    const lua_install = b.addInstallArtifact(lua);
    lua_install.dest_dir = .{ .custom = "../lua" };
    lua_step.dependOn(&lua_install.step);
    b.default_step.dependOn(lua_step);

    // Tests (Linux-only)
    const tests_step = b.step("test", "Run tests");

    const lua_run = b.addRunArtifact(lua);
    lua_run.addArgs(&.{ "-W", "all.lua" });
    lua_run.cwd = "./lua/testes";

    const test_flags = .{ "-Wall", "-std=gnu99", "-O2" };

    inline for (TEST_LIB_FILES) |TEST_LIB_FILE| {
        var name = std.fs.path.stem(TEST_LIB_FILE)[3..];
        if (name.len > 1 and name[1] == '2') {
            name = "2-v2";
        }
        const test_lib = b.addSharedLibrary(.{
            .name = name,
            .target = target,
            .optimize = .ReleaseFast,
            .link_libc = true,
        });
        test_lib.addCSourceFiles(&(CORE_FILES ++ LIB_FILES ++ .{TEST_LIB_FILE}), &test_flags);
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
        test_lib_install.dest_dir = .{ .custom = "../lua/testes/libs" };
        lua_run.step.dependOn(&test_lib_install.step);
    }

    tests_step.dependOn(&lua_run.step);
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
