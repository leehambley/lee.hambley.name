---
title: "Managing Go Language Package Versions"
date: 2013/06/06
---

It's come up a bunch of times lately that people are complaining that Go doesn't allow you to version your imports.

The problem is as such, Go installs packages to your `$GOPATH`, typically this is `~/.go`, effectively meaning that all your dependencies are global, and it's possible that an update to packages in project <em>X</em> could inadvertently upgrade a dependency which breaks project <em>Y</em>.

The import statement doesn't have enough information to version resources, here's a typical import line:

    import (
    	"encoding/base64"
    	"fmt"
    	"github.com/streadway/amqp"
    	"io/ioutil"
    	"net/http"
    	"os"
    	"time"
    )
    
Here the `amqp` package is just begging to be broken incase that a newer version is shipped, or broken release is shipped.

There's no way to specify this as a tag, or branch, it's simply the `HEAD` reference. There's a subtlety here that means if there's a branch who's name matches your current Go version, that'll be taken.

There's some proposals for bundling tools and other ways to manage this, which I haven't linked, because I don't think they're needed, I actually use *GNU Make*.

    GOROOT=/usr/local/go
    GOPATH=$(shell pwd)

    run:
    	GOROOT=${GOROOT} GOPATH=${GOPATH} go run main.go
    build: get
    	GOROOT=${GOROOT} GOPATH=${GOPATH} go build main.go
    get:
    	GOROOT=${GOROOT} GOPATH=${GOPATH} go get ...

    .PHONY: run get build

The key thing here is that the `GOPATH` is always set to the local directory, and then packages are installed into `$(pwd)/src/...`. The `go get ...` *ellipsis* operator is a special case (read more at `go help packages`) which will install any named dependencies in the current package.

In this mechanism, the three most common Go commands that I ever use are aliased to `make run`, `make build` and `make get`, although this is called as a dependency of the other targets.

I check the entire directory in, I really believe that since Go ships as as static binary, it's wise to take the (small, 948K in this case) overhead of checking the `amqp` in to our own repository, effectively *vendoring* my dependencies.