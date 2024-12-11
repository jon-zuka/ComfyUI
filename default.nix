{ pkgs ? import <nixpkgs> {
  config = {
    allowUnfree = true;
    cudaSuport = true;
  };
  
  overlays = [
    (final: prev: {
      python311 = let
        self = prev.python311.override {
          packageOverrides = finalPy: prevPy: {
            triton-bin = prevPy.triton-bin.overridePythonAttrs (oldAttrs: {
              postFixup = ''
                chmod +x "$out/${self.sitePackages}/triton/backends/nvidia/bin/ptxas"
                substituteInPlace $out/${self.sitePackages}/triton/backends/nvidia/driver.py \
                  --replace \
                    'return [libdevice_dir, *libcuda_dirs()]' \
                    'return [libdevice_dir, "${prev.addDriverRunpath.driverLink}/lib", "${prev.cudaPackages.cuda_cudart}/lib/stubs/"]'
              '';
            });
            spandrel = finalPy.callPackage ./nix/packages/spandrel { };
            soundfile = finalPy.callPackage ./nix/packages/soundfile { };
          };
        };
      in self;
    })
  ];
} }:
pkgs.mkShell.override { stdenv = pkgs.clangStdenv; } {
  buildInputs = [
    pkgs.python311
    (with pkgs.python311.pkgs; [
      torch-bin
      triton-bin
      torchvision-bin
      torchaudio-bin
      torchsde
      transformers
      tokenizers
      tqdm
      typing-extensions
      matplotlib
      einops # tensor operations
      safetensors
      sentencepiece
      aiohttp
      pyyaml
      pillow
      scipy
      psutil

      # non essential
      kornia 
      spandrel
      soundfile

      # manager dependencies
      gitpython
      pygithub
      huggingface-hub
      matrix-client
      typer
      rich
      pip
    ])
  ];
  JUPYTER_CONFIG_DIR = "./config";
}
