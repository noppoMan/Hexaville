# Hexaville

Hexaville - The Serverless Framework using AWS Lambda + ApiGateway etc as a back end.
Build applications comprised of microservices that run in response to events, auto-scale for you, and only charge you when they run. This lowers the total cost of maintaining your apps, enabling you to develop more, faster.

It's the greatest motivation to help many Swift and mobile application developers with rapid server side development and low cost operation.

## Supported Cloud Servises
* AWS(lambda+api-gateway, Node.js 4.3 runtime)


## Swift Build Environments

Current Swift Version is 3.1

* Docker
* Xcode(Not implemented yet)
* Linux(Not implemented yet)
* Vagrant(Not implemented yet)

## TODO

* Custom Domain Support
* GCP

## Quick Start

### Install Docker for mac
Install Docker for mac from [here](https://docs.docker.com/docker-for-mac/install/), If you haven't installed yet.

### Install Hexaville
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
    bucket: xxxxxxxxx # here is generated automatically
    role: xxxxxxxxx
    timout: 10
build:
  nocache: false

```

### Deploy a Project

`Usage: hexaville deploy <target>`

Use this when you have made changes to your Functions, Events or Resources.
This operation take a while.

```sh
cd /path/to/your/app
/path/to/.build/debug/Hexaville deploy Hello
```

Got `bucketAlreadyExists` Error?

If you got **bucketAlreadyExists("The requested bucket name is not available. The bucket namespace is shared by all users of the system. Please select a different name and try again.")**, Change the bucket name for lambda in the Hexavillfile.yml

```yml
lambda:
  bucket: unique-bucket-name-here
```

### Show routes

show routes with running `routes` command at your Project root dir.

```sh
cd /path/to/your/app
/path/to/.build/debug/Hexaville routes
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

## Contributing
All developers should feel welcome and encouraged to contribute to Hexaville, see our getting started document here to get involved.

To contribute a feature or idea to Hexaville, submit an issue and fill in the template. If the request is approved, you or one of the members of the community can start working on it.

If you find a bug, please submit a pull request with a failing test case displaying the bug or create an issue.

If you find a security vulnerability, please contact yuki@miketokyo.com as soon as possible. We take these matters seriously.


## Related Articles
* [Serverless Server Side Swift with Hexaville](https://medium.com/@yukitakei/serverless-server-side-swift-with-hexaville-ef0e1788a20)

## License

Hexaville is released under the MIT license. See LICENSE for details.
