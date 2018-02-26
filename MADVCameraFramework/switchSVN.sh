
cd MADVCamera/XMLManager
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/branch/V1.8.9.17379_02.12_bug/Madv360_v1/XMLManager -r $1
cd ../..

cd MADVCamera/ThirdParty
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/branch/V1.8.9.17379_02.12_bug/Madv360_v1/ThirdParty -r $1
cd ../..

cd MADVCamera/CameraManager
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/branch/V1.8.9.17379_02.12_bug/Madv360_v1/CameraManager -r $1
cd ../..

cd MADVCamera/Renderer
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/branch/V1.8.9.17379_02.12_bug/Madv360_v1/Renderer -r $1
cd ../..

cd MADVCamera/PhotosManager
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/branch/V1.8.9.17379_02.12_bug/Madv360_v1/PhotosManager -r $1
cd ../..

cd MADVCamera/DBHelper
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/branch/V1.8.9.17379_02.12_bug/Madv360_v1/DBHelper -r $1
cd ../..

cd MADVCamera/DataModel
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/branch/V1.8.9.17379_02.12_bug/Madv360_v1/DataModel -r $1
cd ../..

cd MADVCamera/Views
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/branch/V1.8.9.17379_02.12_bug/Madv360_v1/Views -r $1
cd ../..

cd MADVCamera/Utils
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/branch/V1.8.9.17379_02.12_bug/Utils -r $1
cd ../..

cd MADVCamera/FFMpegExt
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/FFmpeg/FFMpegExt -r $1
cd ../..

cd MADVCamera/kxmovie
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/kxmovie -r $1
cd ../..

cd MADVCamera/CycordKit
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/MADVPano/trunk/CycordKit/ -r $1
cd ../..

svn export --force svn://172.10.30.102/madV1/branches/app/ios/source/MADVPano/trunk/platforms/MVGLView.h@$1 MADVCamera/MVGLView.h
svn export --force svn://172.10.30.102/madV1/branches/app/ios/source/MADVPano/trunk/platforms/MVGLView.mm@$1 MADVCamera/MVGLView.mm

cd MADVCamera/libs/FFmpeg
svn switch svn://172.10.30.102/madV1/branches/app/ios/source/FFmpeg/FFmpeglibs -r $1
cd ../..

