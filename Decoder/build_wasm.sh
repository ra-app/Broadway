#!/usr/bin/env bash
set -e
#EMSDK_VERSION="tot-upstream"
EMSDK_VERSION="latest"

c_files="$(ls ./src/*.c)"
exported_functions='-s EXPORTED_FUNCTIONS=["_broadwayGetMajorVersion","_broadwayGetMinorVersion","_broadwayInit","_broadwayExit","_broadwayCreateStream","_broadwayPlayStream","_broadwayOnHeadersDecoded","_broadwayOnPictureDecoded"]'
EXPORT_FLAGS="$exported_functions"

#######################################
# Ensures a repo is checked out.
# Arguments:
#   url: string
#   name: string
# Returns:
#   None
#######################################
ensure_repo() {
  local url name
  local "${@}"

  git -C ${name} pull || git clone ${url} ${name}
}

ensure_emscripten() {
  ensure_repo url='https://github.com/emscripten-core/emsdk.git' name='emsdk'
  pushd 'emsdk'
  ./emsdk update-tags
  ./emsdk install ${EMSDK_VERSION}
  ./emsdk activate ${EMSDK_VERSION}
  source ./emsdk_env.sh
  popd
}

build() {
  emcc $c_files -O3 -D_ERROR_PRINT -s TOTAL_MEMORY=209715200 -s ALLOW_MEMORY_GROWTH=1 -s WASM=1 -s INVOKE_RUN=0 -s DOUBLE_MODE=0  -s DISABLE_EXCEPTION_CATCHING=1  --js-library library.js $EXPORT_FLAGS -Isrc -Iinc --extern-pre-js ../templates/DecoderPre.js --extern-post-js ../templates/DecoderPost.js -o ./js/avc.js
}

copy_files() {
  cp ./js/avc.js ../Player/Decoder.js
  cp ./js/avc.wasm ../Player/
}

main() {
  ensure_emscripten
  build
  copy_files
}

main
