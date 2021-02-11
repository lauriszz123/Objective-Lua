# Objective Lua
> Adding Classes to your favourite language and favourite game engine: Love2D!

Objective Lua tries to implement a class system so that you can code more easily!
It supports original Lua syntax too!

## Installation Love2D

Simply download `olua.lua`. Once you've done that, place it in your project and then add this snippet of code to your project's `main.lua` file:
```Lua
main = require "olua.lua"
```

## Syntax Installation to SublimeText

1. Download `Objective Lua.sublime-syntax` and locate your SublimeText `Packages` folder.

You can find the folder by going to the `Preferences > Browse Packages...` tab.

2. Place the file in the `User` folder.
3. Select `Objective Lua` in SublimeText.

## Usage and explanation

First of all, let me clear up something:
> All Classes sit in the `classes` folder.

> `Main.olua` must be created for Objective Lua to start working.

Now lets continue...

See how it returned the main class in the [Installation](#installation-love2d)? We will need to use that to call the main classes functions, in order to run something.
For example:
```Lua
main:doSomething()
```

To include other classes in your project, just run: `require "folder.another_folder.filename"` and Objective Lua will determine which files are which. Objective Lua classes have extensions of: `*.olua`. No don't worry your `require` function still operates like in vanilla Lua.

All class functions need to be called like so: `instance:function( arguments, ... )`. As I said, everything work's as in vanilla Lua.

So let's get down to business. How do you create classes? Okay, okay, I have an example, just chill down, I know you are thrilled...
Okay let's create a class called `Person`, and let's make so that we can print the name of any instances created, example:
```
class Person
  function Person( name )
    self.name = name
  end
  
  function print()
    print( "Hi, my name is: "..self.name.."!" )
  end
end
```

**NOTE:** classes can't have pre-defined variable definitions like in Java or other languages, example:
```
class Person
  name = ""
  function Person( name )
    self.name = name
  end
end
```
or
```
class Person
  self.name = ""
  function Person( name )
    self.name = name
  end
end
```
All variable definitions are done in the constructor class!

Okay, we created our first class, now we can create it! Example:
```Lua
local person = new Person( "Laurent" )
```
Okay, we created `Person` class instance! Neat! We can access defined functions like so:
```Lua
person:print()

--Output:
--Hi, my name is: Laurent!
```

Okay, cool, but what else it can do? Glad you asked!
We can inherit other classes, so now let's create `Laurent` as his own class.
```
class Laurent inherits Person
  function Laurent()
    self( "Laurent" )
  end
  
  function doSomething()
    self:print()
    print( "Oh, Oops, I spoke out too soon!" )
  end
end
```
We created Laurent's shell, but wait what's that `self()` function call? Oh thats the function to call your inherited classes constructor silly! Ok let's instanciate it, example:
```
local laurent = new Laurent()
```
And let's make him do something, he can't sit all day after all!
```
lauernt:doSomething()

--Output:
--Hi, my name is Lauernt!
--Oh, Oops, I spoke out too soon!
```
And as you can see inheritance is simple, not like in the real world... but thats not the point, the point is that there is more! I've added a sneaky new operator for you to use! Yes! Not joking, it is written like so, example:
```
-- For now let's create a dummy class
class Dummy
  function Dummy()
  
  end
end

local person = new Person( "Harry" )
local laurent = new Laurent()
local dummy = new Dummy()

if dummy instanceof Person then
  print( "You are not the same! You should not get this message, at all, ever!" )
end

if laurent instanceof Person then
  print( "This is the correct way to display this message!" )
end

if person instanceof Person then
  print( "Uh... this is not funny that you can describe if statements like this..." )
end
```
Yeah, not funny.... but you get the point! `instanceof` will test if `<instance> instanceof <class>`. Easy peasy.

So this is a quick tutorial of classes, new operator and how they work! For more info check out the repository and feel free to study how it works! Almost everything described here is used in the example program.

Objective Lua also supports:
```Lua
local i = 0
i += expression
i -= expression
i *= expression
i /= expression
i ^= expression
i %= expression
```
As well as:
```Lua
a, b, c += expression, expression, expression
a, b, c -= expression, expression, expression
a, b, c *= expression, expression, expression
a, b, c /= expression, expression, expression
a, b, c ^= expression, expression, expression
a, b, c %= expression, expression, expression
```

## Release History

* 2.4
    * Added precedence support for self-evaluated expressions/variables.
* 2.3
    * Bug Fixes with math operations in classes.
* 2.2
    * Bug Fixes.
* 2.1
    * Additional support in Objective Lua for math operations.
* 2.0
    * Parser overhaul.
    * Test case support.
    * Added test cases.
* 1.0
    * The first proper and stable release.
* 0.1
    * Started to work on the project.

## Meta

Laurynas Suopys – lauriszz12313@gmail.com

Distributed under the SomeRandomLicenseNameHere license. See ``LICENSE`` for more information. ( You won't find it, though )

[https://github.com/lauriszz123/github-link](https://github.com/lauriszz123/)

## Contributing

Contributing and improving this project would be great! If you want to do that, follow these steps:
1. Fork it (<https://github.com/lauriszz123/Objective-Lua/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request
