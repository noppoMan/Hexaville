# Hexaville

[<img src="https://travis-ci.org/noppoMan/Hexaville.svg?branch=master">](https://travis-ci.org/noppoMan/Hexaville) <img src="https://camo.githubusercontent.com/20738bb8299d3bba047a2257835816c996f32dce/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6f732d6d61634f532d677265656e2e7376673f7374796c653d666c6174"> <img src="https://camo.githubusercontent.com/e03f50adf26f5ec614c12cfd26146990e82f72ce/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6f732d6c696e75782d677265656e2e7376673f7374796c653d666c6174"> [![codebeat badge](https://codebeat.co/badges/9f87684c-8392-488e-807c-2c9fae4350fd)](https://codebeat.co/projects/github-com-noppoman-hexaville-master)

Hexaville - The Serverless Framework using AWS Lambda + ApiGateway etc as a back end.
Build applications comprised of microservices that run in response to events, auto-scale for you, and only charge you when they run. This lowers the total cost of maintaining your apps, enabling you to develop more, faster.

It's the greatest motivation to help many Swift and mobile application developers with rapid server side development and low cost operation.

### Supported Cloud Servises
* AWS(lambda+api-gateway, Node.js 4.3 runtime)


### Swift Build Environments

Ubuntu 14.04 in Docker

## Plugins
* [HexavilleAuth](https://github.com/Hexaville): A pluggable framework for providing various authentication methods(OAuth, simple password based etc.)
* [DynamodbSessionStore](https://github.com/Hexaville/DynamodbSessionStore): Dynamodb Session Store
* [RedisSessionStore](https://github.com/Hexaville/RedisSessionStore): Redis Session Store

## Recommended Database Clients
* [SwiftKnex](https://github.com/noppoMan/SwiftKnex): A Mysql Native Client and Query Builder written in Pure Swift
* [Dynamodb](https://github.com/swift-aws/dynamodb): A Dynamodb typesafe client for swift (This is part of aws-sdk-swift)

## Quick Start

### Install Docker for mac
Install Docker for mac from [here](https://docs.docker.com/docker-for-mac/install/), If you haven't installed yet.

### Install Hexaville from Script(Highly recommended)

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

### Install Hexaville from Source
```sh
git clone https://github.com/noppoMan/Hexaville.git
cd Hexaville
swift build
```
and then, should link Hexaville executable path to /usr/local/bin or something like that.

### Create a Project

`Usage: hexaville generate <projectName>`

```sh
hexaville generate Hello --dest /path/to/your/app
```

#### swift-tools-version
You can specify swift-tools-version for the new project with `--swift-tools-version` option.
Current default tool version is `4.0`

If the tool version is higher than 3.1, layouts and definiations of `Package.swift` are refined.

**EX.**
```sh
# swift.version will be 4.0
hexaville generate Hello

# swift.version will be 3.1
hexaville generate Hello --swift-tools-version 3.1

# swift.version will be swift-4.0-DEVELOPMENT-SNAPSHOT-2017-08-04-a
hexaville generate Hello --swift-tools-version swift-4.0-DEVELOPMENT-SNAPSHOT-2017-08-04-a
```

### Open your project with Xcode

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

router.use(.get, "/") { request, context in
    let htmlString = "<html><head><title>Hexaville</title></head><body>Welcome to Hexaville!</body></html>"
    return Response(headers: ["Content-Type": "text/html"], body: htmlString)
}

app.use(router)

try app.run()
```

### Edit Hexavillefile.yml

Fill `access_key_id`, `secret_access_key`, `region`.

```yml
name: test-app
service: aws
aws:
  credential:
    access_key_id: xxxxxxxxx
    secret_access_key: xxxxxxxxx
  region: us-east-1
  lambda:
    bucket: xxxxxxxxx # here is generated automatically
    role: xxxxxxxxx # should be a `arn:aws:iam::{accountId}:role/{roleName}`
    timout: 10
build:
  nocache: false
swift:
  build:
    configuration: release # default is debug
```

#### Required Properties

* name
* service

if `service` is `aws`

* aws
  * lambda.bucket

### Deploy a Project

`Usage: hexaville deploy <executableName>`

Use this when you have made changes to your Functions, Events or Resources.
This operation take a while.

```sh
cd /path/to/your/app
hexaville deploy Hello
```

#### Troubleshooting

**1. What is executableName?**

`<executableName>` is a name that specified in `products(name: 'executableName')` on Package.swift. In following case, it's a `my-app` not `MyApp`.

```swift
let package = Package(
    name: "MyApp",
    products: [
        .executable(name: "my-app", targets: ["MyApp"])
    ],
    ....
)
```

**2. Got `bucketAlreadyExists` Error?**

If you got **bucketAlreadyExists("The requested bucket name is not available. The bucket namespace is shared by all users of the system. Please select a different name and try again.")**, Change the bucket name for lambda in the Hexavillfile.yml

```yml
lambda:
  bucket: unique-bucket-name-here
```

### Show routes

show routes with running `routes` command at your Project root dir.

```sh
cd /path/to/your/app
hexaville routes
```

Output is like following.
```
Endpoint: https://id.execute-api.ap-northeast-1.amazonaws.com/staging
Routes:
  POST    /hello/{id}
  GET    /hello/{id}
  GET    /hello
  GET    /
  GET    /random_img
```

### Access to your resources
```
curl https://id.execute-api.ap-northeast-1.amazonaws.com/staging/
```

## Binary Media Types

Currenty Hexaville supports following binary media types

* image/*
* application/octet-stream
* application/x-protobuf
* application/x-google-protobuf

### Here is an example for getting image/jpeg

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

You can pass environment variables to the lambda function with using `.env`.
The `.env` file should be put at your root directory of the HexavilleFramework Application.

**The contents in .env is...**
```
SWIFT_ENV=production
FACEBOOK_APP_ID=xxxxxxx
FACEBOOK_APP_SECRET=xxxxxxx
```

## VPC

You can add VPC configuration to the lambda function in Hexavillefile.yml by adding a vpc object property in the lambda configuration section. This object should contain the securityGroupIds and subnetIds array properties needed to construct VPC for this function.

Here's an example.

```yaml
name: test-app
service: aws
aws:
  ....
  lambda:
    ....
    vpc:
       subnetIds:
         - subnet-1234
         - subnet-56789
       securityGroupIds:
         - sg-1234
         - sg-56789
```

## Swift Versioning and Build Configuration

You can configure swift versioning and build configuration in `swift` directive

* default swift version is `4.0`
* default build configuration is `debug`

```yaml
name: test-app
swift:
  version: 4.0 #format should be major.minor.[patch] or valid SWIFT DEVELOPMENT-SNAPSHOT name
  build:
    configuration: release
```

### Use SWIFT DEVELOPMENT-SNAPSHOT

You can also specify SWIFT DEVELOPMENT-SNAPSHOT as internal using swift version.  
The format is same as [swiftenv version](https://swiftenv.fuller.li/en/latest/commands.html#version)

**EX.**
```
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

In that case, Hexaville provides you to connection pooling mechanism with [hexaville-tcp-proxy-server](hexaville-tcp-proxy-server).

hexaville-tcp-proxy-server is not only a Proxy Sever But Connection Pooling Server.
See the detail to see [README](hexaville-tcp-proxy-server).

## Cold Start

Not implemented yet.

## Contributing
All developers should feel welcome and encouraged to contribute to Hexaville, see our getting started document here to get involved.

To contribute a feature or idea to Hexaville, submit an issue and fill in the template. If the request is approved, you or one of the members of the community can start working on it.

If you find a bug, please submit a pull request with a failing test case displaying the bug or create an issue.

If you find a security vulnerability, please contact yuki@miketokyo.com as soon as possible. We take these matters seriously.


## Related Articles
* [Serverless Server Side Swift with Hexaville](https://medium.com/@yukitakei/serverless-server-side-swift-with-hexaville-ef0e1788a20)
* [Serverless Server Side Swift@Builderscon Tokyo 2017](https://speakerdeck.com/noppoman/serverless-server-side-swift)

## License

Hexaville is released under the MIT license. See LICENSE for details.
