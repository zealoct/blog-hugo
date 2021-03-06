+++
date = "2015-08-27T18:31:48+08:00"
draft = false
title = "Linux下VIM编码设置——解决中文乱码问题"
tags = ["Linux", "SSH", "Vim", "Windows"]
+++

日常工作与生活中经常需要在Windows下通过Xshell、Putty等SSH客户端远程连接Linux服务器，
在这种场景下使用Vim编辑器查看与录入中文经常会遇到乱码问题。
此外，网上也有很多文章提到过使用Vim将GBK编码的文件转换为UTF-8编码的方法，
这种文件编码的转换在远程Vim的情况下尤其应当小心操作，并提前备份，否则一旦转换失败可能再也难以恢复。
本文记录了一些远程Vim配置方面的心得，希望对大家有所帮助。

远程Vim的工作原理可以简单地理解为从文件读取数据，将数据从**文件的存储编码**转换到终端可识别的**终端编码**，
终端将数据流转发给SSH客户端，SSH客户端则根据客户端内配置的**SSH客户端编码**来对数据流解码，并将内容呈现给用户。
这三个编码我们最关心的是文件的存储编码，然而在配置的时候必须保证三个编码都配置正确，才能正确地显示和转换中文。

### 正确的配置（UTF-8） 

废话少说，先来看正确的配置是怎样的，以及如何正确地配置。

首先，**终端编码与SSH客户端编码需保持一致**，客户端编码的查看与配置方法各有差异，在此不作分析；终端编码可通过如下命令查看：

	locale charmap

如果不是UTF-8的话（默认为ISO-8859-1），可以通过修改环境变量`LANG`和`LC_ALL`来修改，将如下两行添加进`.bashrc`

	export LANG='en_US.UTF-8'
	export LC_ALL='en_US.UTF-8'

这时再通过`locale`命令查看终端编码应该已经变成UTF-8了。

接下来要配置Vim，在正确地配置了终端编码为UTF-8之后，将下面一行添加进.vimrc即可：

	set fencs=utf-8, gbk
	
注意：无需配置`fenc`、`enc`、`tenc`这三个变量！

至此，Vim显示中文的问题应该可以完美解决了！

### Vim配置解析

前边快速地描述了应当如何配置Vim，但并未详细解释这几个选项的作用，但若要做到清楚明白地使用Vim转换文件编码，
了解这些选项的意义还是很有必要的。

Vim与编码相关的配置选项有四个，分别是`fileencodings(fencs)`，`fileencoding(fenc)`，
`encoding(enc)`和`termencoding(tenc)`，其中
`fencs`为一个编码列表，当打开一个文件时，Vim会依次尝试利用列表中的编码去解读文件内容；
`fenc`告诉Vim以哪种编码保存文件内容；
`enc`告诉Vim将文件内容转为哪种编码存储在Vim工作缓冲区内；
`tenc`告诉Vim将缓冲区内的编码转换为何种编码发送给终端。

当Vim打开一个文件的时候，会首先读取`fencs`列表，并尝试以第一个编码去解码文件内容，如果失败则继续尝试第二个，
直到找到一个解码成功的编码，**并将**`fenc`**变量设为该编码**。如果列表内的编码全部解码失败，则设置`fenc`变量为空字符串。

`enc`选项为Vim工作区内容编码，即Vim工作缓存内文件内容的编码，
该编码对用户并不可见，默认为ISO-8859-1（latin1），一般情况下不需要配置。
Vim打开文件时，会从`fencs`列表内匹配编码，并将文件内容从该编码转换为`enc`编码存储在Vim进程的内存里。

`fenc`为文件保存编码，当Vim存储一个文件时，会将工作内存内缓存的内容由`enc`编码转换为`fenc`编码，并写到相应的文件里。
需要注意的是`fenc`选项在Vim启动时会根据`fencs`设定，因此在.vimrc内配置`fenc`并没有意义，
一般只有在需要进行文件编码转换的时候会动态设定该选项的值。
如果`fenc`选项为空字符串，则默认使用`enc`选项所指定的编码保存文件。

`tenc`告诉Vim终端编码类型，Vim会将缓冲区内容由`enc`编码转换为`tenc`编码之后发送给终端渲染。
与`fenc`类似，如果`tenc`为空字符串，则不进行转换，直接输出`enc`编码到终端。

如果你对这些编码转来转去的感觉比较麻烦，一个简单不会出错的方法就是把这些全部都设为UTF-8，世界就清净了 (=

#### 文件编码转换

在进行文件编码转换之前，最好保证上述配置都正确无误（都是UTF-8），并且你的Vim可以正确地解读目标文件编码内容，
简单来说就是`fenc`不是空字符串（这一点很重要，在后面会详细讲述），那么此时你的状态应当是，Vim知道源文件编码，
缓冲区内的编码为`enc`，此时若要进行编码转换，只需在Vim内执行命令（假设UTF-8转GBK）：

	:set fenc=gbk

之后保存的时候，Vim就会自动将缓冲区内容从`enc`转到新的`fenc`编码保存了。

### 我能显示中文就是配置正确了么？

答案当然是**否定**的，而且我就在这个问题上栽过跟头。

远程Vim过程中，可以“正常显示”中文意味着什么呢？答案是，终端发送给SSH客户端的数据被正确地解码了。
但是，这并不代表你的配置是正确的了，在这种场景下进行文件编码转换是**非常危险**的行为！

举一个配置错误、转换错误但是显示正常的例子吧。

	LANG='en_US'
	LC_ALL='en_US'
	fencs=utf-8,gbk
	Xshell encoding='gbk'

此时，终端编码为latin1，Vim内部编码亦为latin1，打开一个GBK编码的中文文件，中文却是可以正常显示的！
其根本原因在于，**GBK和latin1都是ASCII编码方式**（使用latin1来解码GBK数据流并不会出错，只是会出现乱码），
尝试用latin1编码打开GBK编码的文件**并不会进行实质上的编码转换**，终端把它认为是latin1编码的内容发送给Xshell，
Xshell只要使用GBK编码解码，就依然可以正确地显示中文。

但是，这种情况下如果尝试通过修改`fenc`来进行文件编码转换（希望从GBK转到UTF-8），就会出现问题，
因为Xshell虽然知道文件内容是GBK编码，但是Vim并不知道，Vim会尝试把文件内容从latin1转换到UTF-8保存。
这一步转换并不会报错，只是转出来的UTF-8并不是你想要的UTF-8罢了，
因为从GBK转UTF-8会遇到2个字节（一个汉字）转一个UTF-8的情况，而latin1转UTF-8都是单字节转一个UTF-8编码，
如果把转换之后的文件拷到Windows下使用Sublime等编辑器打开，就会发现中文全部都是乱码。

好玩儿的是，虽然Windows下看该UTF-8文件是乱码，同样的配置下在远程Vim里依然可以“正确”地解读该UTF-8文件。
原因也很简单，Vim打开该文件发现是UTF-8编码，会将UTF-8转换为内部缓冲编码latin1，这实际上还原了原本的GBK编码，
使得Xshell可以继续以GBK解码该数据流，但是如果尝试使用`iconv`把这个UTF-8文件直接转换为GBK就会报错。

因此，为了避免不必要的麻烦，日常工作中还是建议将终端编码、SSH客户端编码都设为UTF-8。

### GBK vs. UTF-8

根据前文可以看出来，由于GBK本质上是ASCII编码，因此单纯读取文件内容是无法判断其具体编码的（利用latin1和GBK去解码都正确），
而UTF-8编码的文件会有标示，编辑器可以非常清晰的分辨出这个文件确实是UTF-8编码的文件，因此UTF-8编码在实际使用过程中更不容易出问题，
乱码也就不太会出现了。