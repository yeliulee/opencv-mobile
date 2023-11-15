SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
export OPENCV_VERSION="4.8.1"
export PACKAGENAME="opencv-mobile-4.8.1-ios"
export IOS_DEPLOYMENT_TARGET=9.0
export ENABLE_BITCODE=OFF
export ENABLE_ARC=OFF
export ENABLE_VISIBILITY=OFF



cd $SCRIPT_DIR

wget -q https://github.com/opencv/opencv/archive/$OPENCV_VERSION.zip -O opencv-$OPENCV_VERSION.zip
unzip -q opencv-$OPENCV_VERSION.zip
cd opencv-$OPENCV_VERSION
truncate -s 0 cmake/OpenCVFindLibsGrfmt.cmake
rm -rf modules/gapi
patch -p1 -i ../opencv-4.8.1-no-rtti.patch
patch -p1 -i ../opencv-4.8.1-no-zlib.patch
patch -p1 -i ../opencv-4.8.1-link-openmp.patch
rm -rf modules/highgui
cp -r ../highgui modules/

cd $SCRIPT_DIR

## build

cd opencv-$OPENCV_VERSION
rm -rf build-arm64
mkdir build-arm64 && cd build-arm64
cmake -DCMAKE_TOOLCHAIN_FILE=../../toolchains/ios.toolchain.cmake -DPLATFORM=OS -DARCHS="arm64" \
    -DDEPLOYMENT_TARGET=$IOS_DEPLOYMENT_TARGET -DENABLE_BITCODE=$ENABLE_BITCODE -DENABLE_ARC=$ENABLE_ARC -DENABLE_VISIBILITY=$ENABLE_VISIBILITY \
    -DCMAKE_C_FLAGS="-fno-rtti -fno-exceptions" -DCMAKE_CXX_FLAGS="-fno-rtti -fno-exceptions" \
    -DCMAKE_INSTALL_PREFIX=install -DCMAKE_BUILD_TYPE=Release `cat ../../opencv4_cmake_options.txt` -DBUILD_opencv_world=ON -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON ..
cmake --build . -j 8
cmake --build . --target install

## package

cd $SCRIPT_DIR

rm -rf opencv2.framework
mkdir -p opencv2.framework/Versions/A/Headers
mkdir -p opencv2.framework/Versions/A/Resources
ln -s A opencv2.framework/Versions/Current
ln -s Versions/Current/Headers opencv2.framework/Headers
ln -s Versions/Current/Resources opencv2.framework/Resources
ln -s Versions/Current/opencv2 opencv2.framework/opencv2
lipo -create \
opencv-$OPENCV_VERSION/build-arm64/install/lib/libopencv_world.a \
-o opencv2.framework/Versions/A/opencv2
cp -r opencv-$OPENCV_VERSION/build-arm64/install/include/opencv4/opencv2/* opencv2.framework/Versions/A/Headers/
sed -e 's/__NAME__/OpenCV/g' -e 's/__IDENTIFIER__/org.opencv/g' -e 's/__VERSION__/$OPENCV_VERSION/g' Info.plist > opencv2.framework/Versions/A/Resources/Info.plist
rm -f $PACKAGENAME.zip
zip -9 -y -r $PACKAGENAME.zip opencv2.framework