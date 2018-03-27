+++
date = "2016-06-30T17:46:35+08:00"
title = "Zsh git prompt"
tags = ["zsh", "git"]
+++

之前在Zsh中手动添加了[zsh-git-prompt](https://github.com/olivierverdier/zsh-git-prompt)插件，
不过一直存在一个问题，就是更换文件夹后`$PROMPT`中的`$(git_super_status)`变量不会自动更新，
必须重新执行`source ~/.zshrc`才行。

当时没有时间折腾，今天有时间仔细看了一下问题所在，原来是`$PROMPT`变量的设置有问题，原本的设置是：

``` bash
PROMPT="$(git_super_status) %# "
```

在这里，错误地使用了双引号，导致`$(git_super_status)`函数在赋值阶段就被字符串替换成了当时该函数的值，
因此之后即使更换文件夹，这个部分的显示内容也不会发生变化。双引号情况下`$PROMPT`变量实际的值：

``` bash
(master|✚1) % echo $PROMPT
(%{%}master%{%}|%{%}%{✚%G%}1%{%}%{%}) %# 
```

可以看到`$PROMPT`中的`$(git_super_status)`已经被替换为`(%{%}master%{%}|%{%}%{✚%G%}1%{%}%{%})`，
故而每次显示的都是同样的内容。正确的做法是在`.zshrc`中使用单引号替代双引号，
保证脚本处理的时候不会对字符串内容进行替换，从而保留真正的内容，留待运行时再进行替换：

``` bash
PROMPT='$(git_super_status) %# '
```

``` bash
(master|✚1) % echo $PROMPT   
$(git_super_status) %# 
```