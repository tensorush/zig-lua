const std = @import("std");

pub fn build(b: *std.Build) std.zig.system.NativeTargetInfo.DetectError!void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const version = .{ .major = 5, .minor = 4, .patch = 6 };
    const target_info = try std.zig.system.NativeTargetInfo.detect(target);

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addStaticLibrary(.{
        .name = "lua",
        .version = version,
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib.addCSourceFiles(&(CORE_FILES ++ LIB_FILES), &.{});

    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);
    b.default_step.dependOn(lib_step);

    // Lua interpreter
    const lua_step = b.step("lua", "Install Lua interpreter");

    const lua = b.addExecutable(.{
        .name = "lua",
        .version = version,
        .root_source_file = std.Build.FileSource.relative(LUA_DIR ++ "lua.c"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lua.defineCMacro(switch (target_info.target.os.tag) {
        .linux => "LUA_USE_LINUX",
        .macos => "LUA_USE_MACOSX",
        .windows => "", // will be automatically defined in lua/luaconf.h
        .ios => "LUA_USE_IOS",
        else => "LUA_USE_POSIX",
    }, null);
    lua.defineCMacro("LUA_USE_CTYPE", null);
    lua.defineCMacro("LUA_USE_APICHECK", null);
    lua.defineCMacro("LUA_USE_READLINE", null);
    lua.addCSourceFiles(&(CORE_FILES ++ LIB_FILES), &FLAGS);
    lua.linkSystemLibrary("readline");

    const lua_install = b.addInstallArtifact(lua, .{ .dest_dir = .{ .override = .{ .custom = "../" ++ LUA_DIR } } });
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
            .optimize = optimize,
            .link_libc = true,
        });
        test_lib.addCSourceFiles(&(CORE_FILES ++ LIB_FILES ++ .{TEST_LIB_FILE}), &test_flags);
        if (test_lib.name.len > 1) {
            if (test_lib.name[0] == '1') {
                test_lib.addCSourceFile(.{ .file = .{ .path = TEST_LIB_FILES[0] }, .flags = &test_flags });
            } else if (test_lib.name[1] == '1') {
                test_lib.addCSourceFile(.{ .file = .{ .path = TEST_LIB_FILES[1] }, .flags = &test_flags });
            }
        }
        test_lib.addIncludePath(.{ .path = LUA_DIR });
        test_lib.force_pic = true;

        const test_lib_install = b.addInstallArtifact(test_lib, .{ .dest_dir = .{ .override = .{ .custom = "../" ++ TEST_LIBS_DIR } } });
        lua_run.step.dependOn(&test_lib_install.step);
    }

    tests_step.dependOn(&lua_run.step);
    b.default_step.dependOn(tests_step);
}

const LUA_DIR = "lua/";

const CORE_FILES = .{
    LUA_DIR ++ "lapi.c",
    LUA_DIR ++ "lcode.c",
    LUA_DIR ++ "lctype.c",
    LUA_DIR ++ "ldebug.c",
    LUA_DIR ++ "ldo.c",
    LUA_DIR ++ "ldump.c",
    LUA_DIR ++ "lfunc.c",
    LUA_DIR ++ "lgc.c",
    LUA_DIR ++ "llex.c",
    LUA_DIR ++ "lmem.c",
    LUA_DIR ++ "lobject.c",
    LUA_DIR ++ "lopcodes.c",
    LUA_DIR ++ "lparser.c",
    LUA_DIR ++ "lstate.c",
    LUA_DIR ++ "lstring.c",
    LUA_DIR ++ "ltable.c",
    LUA_DIR ++ "ltests.c",
    LUA_DIR ++ "ltm.c",
    LUA_DIR ++ "lundump.c",
    LUA_DIR ++ "lvm.c",
    LUA_DIR ++ "lzio.c",
};

const LIB_FILES = .{
    LUA_DIR ++ "lauxlib.c",
    LUA_DIR ++ "lbaselib.c",
    LUA_DIR ++ "lcorolib.c",
    LUA_DIR ++ "ldblib.c",
    LUA_DIR ++ "linit.c",
    LUA_DIR ++ "liolib.c",
    LUA_DIR ++ "lmathlib.c",
    LUA_DIR ++ "loadlib.c",
    LUA_DIR ++ "loslib.c",
    LUA_DIR ++ "lstrlib.c",
    LUA_DIR ++ "ltablib.c",
    LUA_DIR ++ "lutf8lib.c",
};

const TEST_LIBS_DIR = LUA_DIR ++ "testes/libs/";

const TEST_LIB_FILES = .{
    TEST_LIBS_DIR ++ "lib1.c",
    TEST_LIBS_DIR ++ "lib2.c",
    TEST_LIBS_DIR ++ "lib11.c",
    TEST_LIBS_DIR ++ "lib21.c",
    TEST_LIBS_DIR ++ "lib22.c",
};

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
