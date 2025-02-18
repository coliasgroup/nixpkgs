{ lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
, nix-update-script
, testers
, pulsarctl
}:

buildGoModule rec {
  pname = "pulsarctl";
  version = "2.10.3.3";

  src = fetchFromGitHub {
    owner = "streamnative";
    repo = "pulsarctl";
    rev = "v${version}";
    hash = "sha256-BOVFBIG+XKBOmLOx/IzseEArcPeriJWzn30FOERBy9s=";
  };

  vendorHash = "sha256-ao8Bxaq9LHvC6Zdd1isyMKxoTJ0MGelSPPxwgqVJcK8=";

  nativeBuildInputs = [ installShellFiles ];

  preBuild = let
    buildVars = {
      ReleaseVersion = version;
      BuildTS = "None";
      GitHash = src.rev;
      GitBranch = "None";
      GoVersion = "$(go version | egrep -o 'go[0-9]+[.][^ ]*')";
    };
    buildVarsFlags = lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "-X github.com/streamnative/pulsarctl/pkg/cmdutils.${k}=${v}") buildVars);
  in
  ''
    buildFlagsArray+=("-ldflags=${buildVarsFlags}")
  '';

  excludedPackages = [
    "./pkg/test"
    "./pkg/test/bookkeeper"
    "./pkg/test/bookkeeper/containers"
    "./pkg/test/pulsar"
    "./pkg/test/pulsar/containers"
    "./site/gen-pulsarctldocs"
    "./site/gen-pulsarctldocs/generators"
  ];

  doCheck = false;

  postInstall = ''
    installShellCompletion --cmd pulsarctl \
      --bash <($out/bin/pulsarctl completion bash) \
      --fish <($out/bin/pulsarctl completion fish) \
      --zsh <($out/bin/pulsarctl completion zsh)
  '';

  passthru = {
    updateScript = nix-update-script { };
    tests.version = testers.testVersion {
      package = pulsarctl;
      command = "pulsarctl --version";
      version = "v${version}";
    };
  };

  meta = with lib; {
    description = " a CLI for Apache Pulsar written in Go";
    homepage = "https://github.com/streamnative/pulsarctl";
    license = with licenses; [ asl20 ];
    platforms = platforms.unix;
    maintainers = with maintainers; [ gaelreyrol ];
    mainProgram = "pulsarctl";
  };
}

