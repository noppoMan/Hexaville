# Hexaville

[<img src="https://travis-ci.org/noppoMan/Hexaville.svg?branch=master">](https://travis-ci.org/noppoMan/Hexaville) <img src="https://camo.githubusercontent.com/20738bb8299d3bba047a2257835816c996f32dce/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6f732d6d61634f532d677265656e2e7376673f7374796c653d666c6174"> <img src="https://camo.githubusercontent.com/e03f50adf26f5ec614c12cfd26146990e82f72ce/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6f732d6c696e75782d677265656e2e7376673f7374796c653d666c6174"> [![codebeat badge](https://codebeat.co/badges/9f87684c-8392-488e-807c-2c9fae4350fd)](https://codebeat.co/projects/github-com-noppoman-hexaville-master)

Hexaville - The Serverless Framework using AWS Lambda + ApiGateway etc as a back end.
Build applications comprised of microservices that run in response to events, auto-scale for you, and only charge you when they run. This lowers the total cost of maintaining your apps, enabling you to develop more, faster.

It's the greatest motivation to help many Swift and mobile application developers with rapid server side development and low cost operation.

### Supported Cloud Servises
* [x] AWS Lambda(Node.js 8.1 Runtime) + APIGateway
* [ ] Google Cloud Function

### Pre-Required

* [Docker](https://www.docker.com/): using for builiding swift application
* [serverless](https://serverless.com/): using for deployment

### Deployment Engine

* 0.x: fullscratch deployment with [aws-sdk-swift](https://github.com/swift-aws/aws-sdk-swift)
* 1.x or later: [serverless framework](https://serverless.com/)

## Plugins
* [HexavilleAuth](https://github.com/Hexaville): A pluggable framework for providing various authentication methods(OAuth, simple password based etc.)
* [DynamodbSessionStore](https://github.com/Hexaville/DynamodbSessionStore): Dynamodb Session Store
* [RedisSessionStore](https://github.com/Hexaville/RedisSessionStore): Redis Session Store

## Recommended Database Clients
* [DynamoDB](https://github.com/swift-aws/aws-sdk-swift): A DynamoDB typesafe client in AWSSDKSwift

## Example Application for Hexaville

[HexavilleTODOExample](https://github.com/Hexaville/HexavilleTODOExample) has following practical examples for Hexaville application.

* User authentication with GitHub's OAuth
* Data persistence with DynamoDB
* Dynamic HTML Rendering

# Quick Start

## Install Docker for mac
Install Docker for mac from [here](https://docs.docker.com/docker-for-mac/install/), If you haven't installed yet.

## Install Hexaville from Script(Highly recommended)

```
curl -L https://rawgit.com/noppoMan/Hexaville/master/install.sh | bash
```

The script clones the hexaville repository to `~/.hexaville` and adds the source line to your profile (~/.zshrc, or ~/.bashrc).
```
export PATH="$PATH:$HOME/.hexaville"
```

`source` your profile and then, type `hexaville`

```sh
source ~/.bashrc
hexaville
```

## Install Hexaville from Source
```sh
git clone https://github.com/noppoMan/Hexaville.git
cd Hexaville
swift build
```
and then, should link Hexaville executable path to /usr/local/bin or something like that.

## Create a Project

`Usage: hexaville generate <projectName>`

```sh
hexaville generate Hello --dest /path/to/your/app
```

### swift-tools-version
You can specify swift-tools-version for the new project with `--swift-tools-version` option.
Current default tool version is `5.1`

If the tool version is higher than 3.1, layouts and definiations of `Package.swift` are refined.

**e.g.**
```sh
# swift.version will be 5.1
hexaville generate Hello

# swift.version will be 5.0
hexaville generate Hello --swift-tools-version 5.0

# swift.version will be swift-4.0-DEVELOPMENT-SNAPSHOT-2017-08-04-a
hexaville generate Hello --swift-tools-version swift-4.0-DEVELOPMENT-SNAPSHOT-2017-08-04-a
```

## Open your project with Xcode

```
swift package generate-xcodeproj
open *.xcodeproj
```

The created codes in the project is example snippet of https://github.com/noppoMan/HexavilleFramework

HexavilleFramework is an express like micro framework for Hexaville.

The syntax is following.
```swift
import HexavilleFramework

let app = HexavilleFramework()

app.use(RandomNumberGenerateMiddleware())

let router = Router()

router.use(.GET, "/") { request, context in
    let htmlString = "<html><head><title>Hexaville</title></head><body>Welcome to Hexaville!</body></html>"
    return Response(headers: ["Content-Type": "text/html"], body: htmlString)
}

app.use(router)

try app.run()
```

## Deploy Your Project

Hexaville depends on [serverless](https://serverless.com/) at deployment.

See Install Guide: https://serverless.com/framework/docs/getting-started/

### Packaging hexaville application

`hexaville package` command does the following.

* build a swift application on the docker(Ubuntu14.04) to create the ELF that is executed on servrless environment.
* zip ELF, swift standard libraries, runtime program and assets

```sh
cd /path/to/your/app
hexaville package
```

### Deploying to the cloud

```sh
serverless deploy --stage staging
```

Default serverless.yml that is created by `hexaville generate` has only staging and production environment.
If you'd like to add other environments, please edit severless.yml manually.

### Troubleshooting

**1. What is executableTarget in Hexavillefile.yml?**

`executableTarget` is a name that specified in `products(name: 'executableTarget')` on Package.swift. In following case, it's a `my-app` not `MyApp`.

```swift
let package = Package(
    name: "MyApp",
    products: [
        .executable(name: "my-app", targets: ["MyApp"])
    ],
    ....
)
```

## Access to your api resources
```
curl https://xxxxxx.execute-api.ap-northeast-1.amazonaws.com/staging/
```

or access the endpoint from Browser.

## Binary Media Types

Currenty Hexaville supports following binary media types

* image/*
* application/octet-stream
* application/x-protobuf
* application/x-google-protobuf

### How to get binary content?

Threr are two rules to respond to the binary content in the routing handler.
* RowBinaryData should be encoded as Base64
* Adding `"Content-Type": "{BinaryMediaType}"` to the response headers

```swift
router.use(.get, "/some_image") { request, context in
    let imageData = Data(contentsOf: URL(string: "file:///path/to/your/image.jpeg")!)
    return Response(headers: ["Content-Type": "image/jpeg"], body: imageData.base64EncodedData())
}
```

Getting binary content from Hexaville, need to send request that includes `Content-Type: {BinaryMediaType}` and `Accept: {BinaryMediaType}` headers

```sh
curl --request GET -H "Accept: image/jpeg" -H "Content-Type: image/jpeg" https://yourdomain.com/staging/random_image

# ????JFIF``??;CREATOR: gd-jpeg v1.0 (using IJG JPEG v62), quality = 70
# ??C
#
#
#
#
#
# #%$""!&+7/&)4)!"0A149;>>>%.DIC<H7=>;??C
#
#
# ;("(;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;???"??
# ............
```


## How to debug?

You can debug your application with the HexavilleFramework's builtin web server with serve command.

```sh
/path/to/your/app/.build/debug/Hello serve
# => Hexaville Builtin Server started at 0.0.0.0:3000
```

# Advanced Settings

## Environment Variables

See: https://serverless.com/framework/docs/providers/aws/guide/variables/

## VPC and Security Groups

See: https://serverless.com/framework/docs/providers/aws/guide/functions#vpc-configuration

## Swift Versioning and Build Configuration

You can configure swift versioning and build configuration in `swift` directive

* default swift version is `5.1`
* default build configuration is `debug`

```yaml
swift:
  version: 5.1 #format should be major.minor.[patch] or valid SWIFT DEVELOPMENT-SNAPSHOT name
  buildOptions:
    configuration: release
```

### Use SWIFT DEVELOPMENT-SNAPSHOT

You can also specify SWIFT DEVELOPMENT-SNAPSHOT as internal using swift version.  
The format is same as [swiftenv version](https://swiftenv.fuller.li/en/latest/commands.html#version)

**e.g.**
```yaml
swift:
  version: swift-4.0-DEVELOPMENT-SNAPSHOT-2017-08-04-a
```

## Static Assets

You can also upload static assets.
Just put your assets into the `assets` directory in your project root.

### Loading Static Assets in Application

You can load static assets from local filesystem with `AssetLoader`

```swift
import HexavilleFramework

let data = try AssetLoader.shared.load(fileInAssets: "/html/index.html")
```

# Against for the Severless weak points

## Too many connections will created between Serveless functions and RDB, Cache Server

Almost Web develoeprs access RDB, Cache Server through connection pooling from your applications. It's a one of the best practice for reducing connection for them. But Functions that are called on Serverless is like a Pre-Folk. It means can not have connection pooling and the number of connection of Database is same as number of functions that are executed in parallel.

In that case, Hexaville provides you to connection pooling mechanism with [hexaville-tcp-proxy-server](https://github.com/Hexaville/hexaville-tcp-proxy-server).

hexaville-tcp-proxy-server is not only a Proxy Sever But Connection Pooling Server.
See the detail to see [README](https://github.com/Hexaville/hexaville-tcp-proxy-server).

## Cold Start

There are several third parties's libraries to againt cold start on github.

The major one is [serverless-plugin-warmup](https://github.com/FidelLimited/serverless-plugin-warmup)

## How to update Hexaville CLI Version?

```sh
$ rm -rf ~/.hexaville
$ curl -L https://rawgit.com/noppoMan/Hexaville/master/install.sh | bash
$ hexaville version
```

## Contributing
All developers should feel welcome and encouraged to contribute to Hexaville, see our getting started document here to get involved.

To contribute a feature or idea to Hexaville, submit an issue and fill in the template. If the request is approved, you or one of the members of the community can start working on it.

If you find a bug, please submit a pull request with a failing test case displaying the bug or create an issue.

If you find a security vulnerability, please contact yuki@miketokyo.com as soon as possible. We take these matters seriously.


## Related Articles
* [Serverless Server Side Swift with Hexaville](https://medium.com/@yukitakei/serverless-server-side-swift-with-hexaville-ef0e1788a20)
* [Serverless Server Side Swift@Builderscon Tokyo 2017](https://speakerdeck.com/noppoman/serverless-server-side-swift)
* [WEB+DB PRESS Vol.101](https://www.amazon.co.jp/WEB-DB-PRESS-Vol-101-%E6%A3%AE%E6%9C%AC/dp/4774192392)

## License

Hexaville is released under the MIT license. See LICENSE for details.
