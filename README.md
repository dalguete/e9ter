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

  You'll also need to update some packages to latest versions, to have a complete
  experience. All can be done by using Homebrew. Next, what you'll need to install:
	
	* Bash >=4 OS X - Follow this guide http://johndjameson.com/blog/updating-your-shell-with-homebrew/ to enable it.
	* Coreutils >=8 OS X - `brew install coreutils` to enable it.
	* getopt >=1.1.6 OS X - `brew install gnu-getopt` to enable it.

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

About Entries In 'recipe.sh'
----------------------------

To better understand the entry types that file handles, next a brief explanation
is displayed, so you can have a better on how to proceed when defining data into it:

	* **Folder**: Defines where to search for the actual recipe data from. If nothing
		defined **recipe** is used as name.
		Receives a single value.
		Used in **clone** process.

	* **Template**: Defines a series of entries used to identify template vars to be
		used inside the .TEMPLATE files. This is not a recopilation of all available
		vars, but a list of default values, so when initializing the recipe, the user
		won't have to explicitely pass values for them.
		Receives a multiple value.
		Used in **init** process.

	* **Component**: Defines a series of entries used to identify the different components
		of a recipe, when it is a compound one. Basic information to use are:

		* Name: Name of the component recipe to use. ID option. Only required entry.
		* Version: Version of the component recipe to use. Used to further identificate
			the correct recipe. If not set, internal processes will use the last available
			recipe. ID option.
		* Source: From where to get the mentioned recipe. Defaults to global recipes location.
		* Status: Tells if the component should be "normally installed", "removed" or "replaced".
			Useful when extending/altering a compound recipe.
		* ICO: Set of entries aimed to alter a given component definition. With it you
			can change Non-ID options of those components.

		Receives a multiple value.
		Used in **clone** process.

New Operations
--------------

When defining a new operation, you should be aware that even when using other operations
internally (see clone vs init) all the checkings should live inside of each of them.

Commands used to deal with Docker integrations
----------------------------------------------

You'll now have access to some custom commands, explained below:

