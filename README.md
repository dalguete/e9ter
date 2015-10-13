# btdocker

Ok, here comes the magic. Here is defined a script with some functionality aimed
to ease the use of Docker and projects in the Bluetent env.

This can be used under `bash` or `zsh` envs, following the installion procedures
below.

So, let's start the fun.

Requirements
------------

We'll need several Docker tools in order to achieve our goal, so the main ones are
[Docker Engine](https://docs.docker.com/), [Docker Machine](https://docs.docker.com/machine/) and [Docker Compose](https://docs.docker.com/compose/)

* Mac Users, please follow the directions set here https://docs.docker.com/installation/mac/
on how to install them all. You'll need Virtualbox too.

* Linux Users, you can find installtion steps info here https://docs.docker.com/installation/.
Search for you distro/version and enjoy.

**IMPORTANT**, despite the fact Linux can run Docker directly, we suggest not to do
so, unless you truly know how the AppArmor/SELinux aspects in your host machine
can influence your containers, particularly when using `--privileged` or similar
options. And well, in our case, that happens frecuently, mostly due to some Docker
bugs not yet resolved when dealing with fuse and blah, blah, blah.
Long story short, you'll be using `boot2docker` images too, the same way as Mac does.

Installation
------------

As this script is aimed to be used as a `oh-my-zsh` plugin, it follows the same procedures
as [btsh](https://github.com/bluetent/btsh) commands. But, here you go:

* **oh-my-zsh**
	* `cd ~/.oh-my-zsh/custom/plugins && git clone git@github.com:bluetent/btdocker.git`
	* Edit your `~/.zshrc` file and add the **btdocker** plugin. eg: plugins=(git btdocker) 
	* Restart you terminal

* **bash**
	* Clone btdocker `git clone git@github.com:bluetent/btdocker.git` wherever you want.

	* For current user only:
		* Edit `~/.bashrc`.
		* Append at the bottom `. </path/to/btdocker/btdocker.plugin.zsh>`, obviously
			making it point to the place where your cloned the project is.
		* Restart you terminal

	* For all users:
		* Edit `/etc/bash.bashrc`
		* Append at the bottom `. </path/to/btdocker/btdocker.plugin.zsh>`, obviously
			making it point to the place where your cloned the project is.
		* Restart you terminal


Commands used to deal with Docker integrations
----------------------------------------------

You'll now have access to some custom commands, explained below:

