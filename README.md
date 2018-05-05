# get-kubernetes-packages
Get Kubernetes Packages without VPN

欢迎使用睿云智合提供的Kubernetes部署资源获取工具！

                                           --- Alan Peng ( alan_peng@wise2c.com / peng.alan@gmail.com)

        该工具用来在没有VPN翻墙工具的时候，可以顺畅的利用Gitlab服务来为我们制作Kubernetes或其它任意难以在国内

获取的Docker镜像包或OS下安装所需的二进制包，例如RPM或DEB格式的安装包文件。

        您首先需要拥有一个Gitlab站点 http://gitlab.com （不是私有部署的Gitlab服务器）的账号，用它来完成所有

操作，如果还没有，请自行注册一个即可，这是免费的。

        在程序主界面默认提供了基于Kubeadm安装模式的Kubernetes 1.10.2的版本号及其相关组件的版本号，您可以对其

中任意版本号进行自定义输入。也可以点击镜像列表页的按钮“获取K8S版本号列表”自动同步。

        当然您还可以使用该工具获取与Kubernetes无关的镜像，只需要在首页的镜像列表里自己输入完整镜像名即可，每行

一个镜像名，请勿使用任何其它符号分隔。

        由于网络方面的原因，程序使用过程中可能会遇到一些错误提示，通常您只需要多试一两次即可完成任务。我采用了

transfer.sh作为文件中转，然而该站点有些时候在国内的访问速度会有点慢，这时请您使用docker命令获取

压缩包。

        使用过程中遇到任何问题或对我们其它产品产生兴趣，欢迎随时请联系我们。

                                                                                深圳睿云智合科技有限公司


点击“获取K8S版本号列表”可出现下拉框，选择您需要的版本：

![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/getkubernetespackages01.png)

输入您在Gitlab网站 ( https://gitlab.com ) 上的账号及密码，然后点击“开始构建并下载”按钮：

如果出现ssl相关错误，那是因为您电脑上缺少了两个dll文件（libeay32.dll和ssleay32.dll），请在本项目的openssl-library-files目

录下载到Windows的系统目录（32位是C:\Windows\System32；64位是C:\Windows\SysWOW64）或直接保存在该工具所在目录下。如截图所示：

![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/SSL-Library-01.png)

![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/SSL-Library-02.png)

![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/SSL-Library-03.png)

![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/getkubernetespackages02.png)

直至任务成功，这期间由于国内访问Gitlab站点可能会不太稳定，程序会给出各种错误提示，一般您只需要重新执行几次就可以正常了。

![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/getkubernetespackages03.png)

下载该压缩包文件并解压开，按下面截图操作方法获得Kubernetes所需的docker镜像以及二进制包文件：

![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/getkubernetespackages04.png)
![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/how%20to%20get%20the%20deb%20or%20rpm%20files.png)
![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/how%20to%20load%20images.png)

######################################################################

macOS操作系统下的程序界面是类似的，操作方法完全一致：

![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/macOS01.png)
![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/macOS02.png)
![Alt text](https://github.com/wise2ck8s/get-kubernetes-packages/raw/master/images/macOS03.png)

Alan Peng ( alan_peng@wise2c.com / peng.alan@gmail.com )
