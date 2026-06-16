# Coding Agent in Pharo Smalltalk

Author: Han Zhupeng (hanzhupeng@gmail.com)  aka. AlbertLee

## Why Smalltalk

why not? If you know Debugger and inspector, you'll realize that the Smalltalk Image is the perfect fit for a Coding Agent.

More details:
[Why Smalltalk Coding Agent](docs/why-smalltalk-agent.md)

## Project Status

The proof-of-concept stage can already autonomously generate and run code, and inspect Pharo image contents, but it has not yet been tuned.

![](docs/images/demo1.png)

The generated code is still somewhat clumsy and does not leverage existing methods:
![CodeGen](docs/images/demo2.png)
