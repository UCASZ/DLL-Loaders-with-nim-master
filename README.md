# DLL-Loaders with nim

主要以nim语言实现的DLL文件的加载程序以及测试用的DLL文件的制作程序，主要用于演示如何使用nim语言实现几类基本的恶意DLL注入。

## codes

DLL examples文件夹中主要是为制作DLL文件的，具体的编译方式写在每个样例的注释中（这里展现了跨平台编译的办法）。

DLL Loaders文件夹中主要是各种实现加载DLL examples里面编译出来的DLL库的程序，具体的编译方式同样写在每个样例的注释中。部分程序利用nim的FFI（`foreign function interface`）以展现其跨语言的实现办法。另外，请自行修改nim程序中对应的DLL路径。

编译的环境主要是windows10，nim版本为1.4。另外部分程序的编译用到了C#和C++。

以下是一个示例：

![example](https://github.com/UCASZ/DLL-Loaders-with-nim-master/blob/master/example.gif)

## Dockerfile

如果您不希望在windows中安装nim，而是想要在linux中跨平台编译——可使用如下docker。

例子：编译名为`exec.nim`的一般文件非常简单，也许可使用如下命令（添加的某些参数是为压缩其大小）：

```bash
docker run --rm --user app -v `pwd`:/usr/src/app -w /usr/src/app nim:latest nim c --app=gui -d:mingw -d:release -d:strip --opt:size --passc=-flto --passl=-flto --cpu=amd64 exec.nim
```

ps：若要跨平台编译，记得使用`-d=mingw`参数。如果不想在运行exe文件时弹出黑框，可加上`--app=gui`参数。**另外，建议在Dockerfile中用命令复制一份根据需要而配置的[nim.cfg](https://github.com/nim-lang/Nim/blob/devel/config/nim.cfg)文件于相应的路径（因为可能默认的配置会有问题，比如跨平台编译cpp的时候会找不到需要的头文件，并且请注意头文件第一个字母最好用小写）。**



