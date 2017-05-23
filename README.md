# Hexaville

Hexaville - The Serverless Framework using AWS Lambda + ApiGateway etc as a back end.
Build applications comprised of microservices that run in response to events, auto-scale for you, and only charge you when they run. This lowers the total cost of maintaining your apps, enabling you to develop more, faster.

It's the greatest motivation to help many Swift and mobile application developers with rapid server side development and low cost operation.

## Features

* AWS(lambda+api-gateway, Node.js 4.3 runtime)

## Swift Build Environments

Current Swift Version is 3.1

* Docker
* Xcode(Not implemented yet)
* Linux(Not implemented yet)
* Vagrant(Not implemented yet)

## TODO

* Custom Domain Support
* VPC Support
* a
* GCP

## Quick Start

### Insall Hexaville
```sh
git clone https://github.com/noppoMan/Hexaville.git
cd Hexaville
swift build
```

### Create a Project

`Usage: hexaville generate <projectName>`

```sh
./.build/debug/Hexaville generate Hello --dest /path/to/your/app
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
    let str = "<html><head><title>Hexaville</title></head><body>Welcome to Hexaville!</body></html>"
    return Response(headers: ["Content-Type": "text/html"], body: .buffer(str.data))
}

app.use(router)

try app.run()
```

### Edit Hexavillefile.yml

Fill `access_key_id`, `secret_access_key`, `region` and `lambda.role` in!

`lambda.role` should be a `arn:aws:iam::{accountId}:role/{roleName}` format.

```yml
name: test-app
service: aws
aws:
  credential:
    access_key_id: xxxxxxxxx
    secret_access_key: xxxxxxxxx
  region: us-east-1
  lambda:
    role: xxxxxxxxx
    timout: 10
build:
  nocache: false

```


### Deploy a Project

`Usage: hexaville deploy <hexavileApplicationPath> <target>`

Use this when you have made changes to your Functions, Events or Resources.
This operation take a while.

```sh
./.build/debug/Hexaville deploy ~/Hello Hello
```

### Show routes

show routes with running `routes` command at your Project root dir.

```swift
cd /path/to/your/app
/path/to/.build/debug/Hexaville routes
```

Output is like following.
```
Endpoint: https://id.execute-api.ap-northeast-1.amazonaws.com/staging
Routes:
  GET /hello
  GET /
  POST /hello/{id}
  GET /hello/{id}
```

### Access to your resources
```
curl https://id.execute-api.ap-northeast-1.amazonaws.com/staging/
```

## Contributing
All developers should feel welcome and encouraged to contribute to Hexaville, see our getting started document here to get involved.

To contribute a feature or idea to Hexaville, submit an issue and fill in the template. If the request is approved, you or one of the members of the community can start working on it.

If you find a bug, please submit a pull request with a failing test case displaying the bug or create an issue.

If you find a security vulnerability, please contact yuki@miketokyo.com as soon as possible. We take these matters seriously.


## License

Hexaville is released under the MIT license. See LICENSE for details.
