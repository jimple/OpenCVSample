OpenCVSample
============

OpenCV的iOS例子


想做一些图像匹配，所以最近学习使用openCV，并做了一些试验。


------ 安装 openCV ------

1、首先是学习了这篇博客，了解大概过程。（最终并没有完全按照里面的步骤去做）

http://blog.devtang.com/blog/2012/10/27/use-opencv-in-ios/

2、下载openCV代码。（下载了last release 2.4.8）

https://github.com/Itseez/opencv/releases

3、按照下面的介绍编译。

http://docs.opencv.org/trunk/doc/tutorials/introduction/ios_install/ios_install.html#ios-installation

    - 然后悲剧地发现，在 Maverick + Xcode5 下死活不能全部编译通过。以前Lion+Xcode4编译2.4.2是可以的。
    - 搞了半天没搞掂之后，狠狠地直接下载了framework。
    
    http://www.mirrorservice.org/sites/downloads.sourceforge.net/o/op/opencvlibrary/opencv-ios/
    
4、然后就可以开干了。

先对着教程一阵胡看，再加上以前windows上搞过一下，然后就开始创建工程编码了。

http://www.opencv.org.cn/opencvdoc/2.3.2/html/doc/tutorials/tutorials.html


------ 创建openCV工程 ------

1、创建一个iOS工程，把opencv2.Framework加进去。

2、需要用到openCV的类改为 .mm 文件，导入头文件  #import <opencv2/opencv.hpp>  。



------ JCOpenCVCameraImgMatchDemo 介绍 ------

就是为了做摄像头的实时图像匹配，而且是特定的场景（室内固定地点或者平面广告）。

想法如下：

1、拍一张原图。

2、打开摄像头隔几百毫秒取一张图下来，和原图匹配。

    - 匹配方式：1、几种颜色直方图全比较一下，然后不停地调试，活得比较适合的阀值。
    - 2、原图与目标图做边缘检测，然后把两个边缘检测图也拿去匹配一下。

3、对颜色匹配结果分三种命中率，然后根据具体业务需要，看是严格匹配才算匹配成功，还是随便有点像就算是匹配成功。

4、写了个Utility的类，把一些常用方法独立出来。

5、什么内存、耗电之类的都没考虑。仅在iPhone5上测试过。

据说在iPhone4S+iOS6.1会crash，出错信息如下。可是我没有4S+iOS6.1的环境，opencv又是直接拿的framework没有自己编译。所以，只在模拟器上试了一下本地两张本地静态图片的匹配（木有问题），没有在这个环境下试摄像头实时获取。（臣妾真的做不到啊～～）

    - Bad argument (Invalid histogram header[s]) in cvCompareHist。opencv-2.4.8/modules/imgproc/src/histogram.cpp, line 2460 libc++abi.dylib: terminate called throwing an exception。


------ 感谢 ------

读取摄像头图像的方法用的是这个：

https://github.com/erica/iOS-5-Cookbook/tree/master/C07/05-Camera%20Helper



--------------------------------------------------------------------------
一些用到的资料：

http://docs.opencv.org/trunk/doc/tutorials/introduction/ios_install/ios_install.html#ios-installation

http://www.opencv.org.cn/opencvdoc/2.3.2/html/doc/user_guide/user_guide.html

http://blog.devtang.com/blog/2012/10/27/use-opencv-in-ios/

http://www.opencv.org.cn/opencvdoc/2.3.2/html/doc/tutorials/tutorials.html

http://opencv.org/

https://github.com/erica/iOS-5-Cookbook/tree/master/C07/05-Camera%20Helper

http://www.mirrorservice.org/sites/downloads.sourceforge.net/o/op/opencvlibrary/opencv-ios/










