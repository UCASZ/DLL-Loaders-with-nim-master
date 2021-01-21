# DLL-Loaders with nim

主要以nim语言实现的DLL文件的加载程序以及测试用的DLL文件的制作程序，主要用于演示如何使用nim语言实现几类基本的恶意DLL注入。

DLL examples文件夹中主要是为制作DLL文件的，具体的编译方式写在每个样例的注释中（这里展现了跨平台编译的办法）。

DLL Loaders文件夹中主要是各种实现加载DLL examples里面编译出来的DLL库的程序，具体的编译方式同样写在每个样例的注释中。部分程序利用nim的FFI（foreign function interface）以展现其跨语言的实现办法。另外，请自行修改nim程序中对应的DLL路径。



编译的环境主要是windows10，nim版本为1.4。另外部分程序的编译用到了C#和C++。

以下是一个示例：

![example](https://github.com/UCASZ/DLL-Loaders-with-nim-master/blob/master/example.gif)