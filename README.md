# e9ter

Ok, here comes the magic. Here is defined a script with some functionality aimed
to ease the creation of a given project environment. That is, the files and folders
required for it to be usable. They are served in what has been called, **recipes**

So, let's start the fun.

Requirements
------------

* Mac Users, you'll need to update some packages to latest versions, to have a complete
  experience. All can be done by using Homebrew. Next, what you'll need to install:
	
	* Bash >=4 OS X - Follow this guide http://johndjameson.com/blog/updating-your-shell-with-homebrew/ to enable it.
	* Coreutils >=8 OS X - `brew install coreutils` to enable it.
	* getopt >=1.1.6 OS X - `brew install gnu-getopt` to enable it.

* Linux Users, enjoy!.


Recipes
=============

A recipe is the center of the **e9ter** solution. It's a set of files and folders
aimed to serve a purpose. They can have variables defined, which will be replaced
the moment of processing a given recipe.

Also, a recipe can be composed of other ones, and on and on and on.

Recipe Format
-------------

Every recipe requires to be represented in a structure that holds the name of the
recipe itself, inside with folders named after the version it holds, and finally,
internally the 'recipe.sh' file with all recipe variables, as required.

By default, you'll use a recipe folder, living next to recipe.sh, where all your
recipe definitions will live. You can use a different folder by setting the **Folder**
var inside recipe.sh.

Despite the fact recipe folder can have anything you want, disposed in any way, we
recommend you create inside of it, other folder, named after your recipe's name,
and inside of it all the final recipe structure. The idea is to have just one entry
for the recipe, to better support cases when multiple sub-recipes will be used. 
Because you have a lot of flexibility in defining recipes that eventually could
use another recipes, there are chances you'll define the same recipe under
the same parent folder. More than one file or folder defined in that sub recipe,
the more the chances of data overrides. Think about a recipe that defines more than one
web server recipe under the same dir.

In general, the recipe structure should be something like:

```
<recipe name>
 │
 ├── version
 ├── <version folder>/
 │    ├── recipe.sh
 │    └── recipe/
 │        └── <actual recipe contents>
 │
 ├── <version folder X>/
 ├── <version folder Y>/
 ├── <version folder Z>/
 └── ...
```

Having the entries as follows:

  * **\<recipe name\>**: Name of the recipe.

  * **version**: Text file which contains the name of the recipe's default version.
    As a recipe can have several versions, with this file the default one can be located.
    Just one line is required, as only the first line will be evaluated. Required.

  * **\<version folder\>/**: Folder named after the version holded here. At least
    one of them should exist, that must match the value given in **version** file.

  * **recipe.sh**: Recipe configuration file, that holds basic information about
    the recipe, like location, replacement variables, inner recipes or components,
    etc.

  * **recipe/**: Folder where the actual recipe contents will live. If not overriden
    in recipe.sh file, this is the default place **e9ter** will look for. If other name
    defined in recipe.sh, that folder will be used as the place to check.

  * **\<actual recipe contents\>**: As the name implies, these are the real recipe
    contents. This can be anything you want, but the recommendation is to make this
    a folder named after the recipe, and inside of it the recipe contents. This just
    as a helper for possible compound recipes that could be using this one.


About Entries In 'recipe.sh'
----------------------------

To better understand the entry types that file handles, next a brief explanation
is displayed, so you can have a better understanding on how to proceed when defining
data into it:

  * **Folder**: Defines where to search for the actual recipe data from. If nothing
		defined **recipe** is used as name.
		Receives a single value.
		Used in **clone** process.

  * **Template**: Defines a series of entries used to identify template vars to be
		used inside the .TEMPLATE files and [TEMPLATE:*] entries. This is not a recopilation of all available
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
==============

When defining a new operation, you should be aware that even when using other operations
internally (see clone vs init) all the checkings should live inside of each of them.

