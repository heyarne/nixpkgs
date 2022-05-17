{
  config,
  lib,
  stdenv,
  fetchFromGitHub,
  jack2,
  makeWrapper,
  python3,
  ruby,
  sonic-pi,
  supercollider-with-sc3-plugins
}:
# with (import <nixpkgs> ){};
let
  # see https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md for details
  oscpy = python3.pkgs.buildPythonPackage rec {
    pname = "oscpy";
    version = "0.6.0";
    src = python3.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-ByilpyZnMsnWRjAGPThJEdXWrkdEFrebeNSQV3P7bTM=";
    };

    dontCheck = true;

    meta = {
      homepage = "https://github.com/kivy/oscpy";
      description = "An efficient OSC implementation compatible with python2.7 and 3.5+";
    };
  };
  pythonWithPackages = python3.withPackages(ps: [
      ps.click 
      ps.psutil
      oscpy
  ]);
in stdenv.mkDerivation rec {
  name = "sonic-pi-tool";
  version = "0.0.1";

  buildInputs = [
    pythonWithPackages
    ruby
  ];
  nativeBuildInputs = [
    makeWrapper
  ];

  src = fetchFromGitHub {
    owner = "emlyn";
    repo = name;
    rev = "b955369294b7669b2706b26d388ec2c2a9d0d3a2";
    sha256 = "sha256-HgJSZGjm0Uwu2TTgv/FMTRKLUdT8ILNaiL4wKJ1RyBs=";
  };

  meta = with lib; {
    description = "A command-line pager for JSON data";
    homepage = "https://github.com/PaulJuliusMartinez/jless";
    license = licenses.mit;
    maintainers = [];
  };

  installPhase = ''
    mkdir -p $out/bin
    echo '#!/usr/bin/env ${pythonWithPackages}/bin/python' > $out/bin/sonic-pi-tool
    sed 1d ${src}/sonic-pi-tool.py >> $out/bin/sonic-pi-tool
    sed -E -i "s|default_paths = \(.*$|default_paths = (\'${sonic-pi}/app\',|" $out/bin/sonic-pi-tool
    sed -E -i "s|ruby_paths = \[.*$|ruby_paths = [\'${ruby}/bin/ruby\',|" $out/bin/sonic-pi-tool
    chmod +x $out/bin/sonic-pi-tool
  '';

  dontPatchShebangs = true;
  doDist = true;

  distPhase = ''
    wrapProgram $out/bin/sonic-pi-tool $wrapperfile --prefix PATH : ${lib.makeBinPath [ jack2 ruby supercollider-with-sc3-plugins ]}
  '';
}