+++
date = "2015-09-14T16:51:18+08:00"
draft = false
title = "[转]windows下交换CapsLock和Ctrl键"
+++

原文地址：http://www.kodiva.com/post/swapping-caps-lock-and-control-keys

NOTE：原文描述该方法在 Windows XP，Windows Vista，Windows 7下可用，本人测试在Win10下亦可用

In our opinion this is the best way to swap the control and caps lock keys in Windows because you don't have to rely on any external program and the registry edit works 100% perfectly (for the paranoid). 

Why should one bother changing the caps lock and control keys, what's wrong with the control key where it is? After extensive testing, our conclusion is that - if you use the control key a lot (like in Emacs or Vim), then you should definitely swap the control and caps lock keys as it's extremely ergo-dynamic to have the control key in the home row.

1.	Click Start -> Run

1.	Type: *regedit*, and click OK

1.	Go to: *HKEY_LOCAL_MACHINE* -> *System* -> *CurrentControlSet* -> *Control* -> *KeyBoard Layout*

	Note: *KeyBoard Layout*, and NOT *KeyBoard Layouts*

1.	Right-click: Keyboard Layout, and select New -> Binary value

1.	Rename: New Value #1 -> Scancode Map

1.	Right click: Scancode Map -> Modify

		0000  00 00 00 00 00 00 00 00		
		0008  03 00 00 00 1d 00 3a 00
		0010  3a 00 1d 00 00 00 00 00
		0018

1.	Close regedit and restart your computer