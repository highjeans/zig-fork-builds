{
  stdenv,
  fetchFromCodeberg,
  cmake,
  lib,
  llvmPackages_22,
  coreutils,
  ninja,
  xcbuild,
  libxml2,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "zig";
  version = "0.17.0-dev-fork";

  src = fetchFromCodeberg {
    owner = "techatrix";
    repo = "zig";
    rev = "a1ce8e2fe50116a5d1c029e56afd55d812d3f8e3";
    hash = "sha256-cSCZ2CuMKX712LB8y5l3oEmu0KlKCW/izxJB6ZVWSP8=";
  };

  nativeBuildInputs = [
    cmake
    (lib.getDev llvmPackages_22.llvm.dev)
    ninja
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    # provides xcode-select, which is required for SDK detection
    xcbuild
  ];
  buildInputs = [
    libxml2
    zlib
  ]
  ++ (with llvmPackages_22; [
    libclang
    lld
    llvm
  ]);

  cmakeFlags = [
    # file RPATH_CHANGE could not write new RPATH
    (lib.cmakeBool "CMAKE_SKIP_BUILD_RPATH" true)
    # ensure determinism in the compiler build
    (lib.cmakeFeature "ZIG_TARGET_MCPU" "baseline")
    # always link against static build of LLVM
    (lib.cmakeBool "ZIG_STATIC_LLVM" true)
    # Override the version to a version that will never exist
    (lib.cmakeFeature "ZIG_VERSION" "0.17.0-dev.fork")
  ];

  strictDeps = true;

  __structuredAttrs = true;

  # On Darwin, Zig calls std.zig.system.darwin.macos.detect during the build,
  # which parses /System/Library/CoreServices/SystemVersion.plist and
  # /System/Library/CoreServices/.SystemVersionPlatform.plist to determine the
  # OS version. This causes the build to fail during stage 3 with
  # OSVersionDetectionFail when the sandbox is enabled.
  __impureHostDeps = lib.optionals stdenv.hostPlatform.isDarwin [
    "/System/Library/CoreServices/.SystemVersionPlatform.plist"
  ];

  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache";
  '';

  postPatch =
    # Zig's build looks at /usr/bin/env to find dynamic linking info. This doesn't
    # work in Nix's sandbox. Use env from our coreutils instead.
    ''
      substituteInPlace lib/std/zig/system.zig \
        --replace-fail "/usr/bin/env" "${lib.getExe' coreutils "env"}"
    '';

  # postBuild = "stage3/bin/zig build --zig-lib=$(pwd)/stage3/lib/zig langref";

  # postInstall = ''
  #   install -Dm444 ../zig-out/doc/langref.html -t $doc/share/doc/zig-${finalAttrs.version}/html
  # '';
})
