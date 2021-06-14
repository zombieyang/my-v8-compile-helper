VERSION=8.4.371.19
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"

cd ~
echo "=====[ Getting Depot Tools ]====="	
git clone -q https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=$(pwd)/depot_tools:$PATH
gclient

echo "=====[ Fetching V8 ]====="
fetch v8
echo "target_os = ['mac']" >> .gclient
cd ~/v8
git checkout refs/tags/$VERSION
gclient sync

git remote add zombie https://github.com/zombieyang/v8.git
git fetch zombie 8.4
git checkout zombie/8.4

echo "=====[ Building V8 ]====="
# alias python=./venv2/bin/python2
python ./tools/dev/v8gen.py x64.release -vv -- '
is_debug = false
v8_enable_i18n_support= false
v8_use_snapshot = true
v8_use_external_startup_data = true
v8_static_library = true
strip_debug_info = true
symbol_level=0
libcxx_abi_unstable = false
v8_enable_pointer_compression=false
'
ninja -C out.gn/x64.release -t clean
ninja -C out.gn/x64.release wee8

node ./puerts/genBlobHeader.js "osx 64" out.gn/x64.release/snapshot_blob.bin

rm -rf ./puerts/output

mkdir -p ./puerts/output/Lib/macOS
cp out.gn/x64.release/obj/libwee8.a ./puerts/output/Lib/macOS/
cp -r ./include ./puerts/output/
mv ./puerts/output/include ./puerts/output/Inc
mkdir -p ./puerts/output/Inc/Blob/macOS
cp SnapshotBlob.h ./puerts/output/Inc/Blob/macOS/
rm -rf ./SnapshotBlob.h

zip -r puerts/puerts-v8.zip ./puerts/output