const spawn = require('child_process').spawn;
const byline = require('./byline');

// //for debug
// var event = {
//   "resource": "/hello/{id}",
//   "path": "/hello/100",
//   "httpMethod": "GET",
//   "headers": {
//     "Accept": " application/json"
//   },
//   "queryStringParameters": null,
//   "pathParameters": {
//     "id": "1"
//   },
//   "stageVariables": null,
//   "requestContext": {
//     "path": "/foo/{id}",
//     "accountId": "158695423430",
//     "resourceId": "a0wtva",
//     "stage": "test-invoke-stage",
//     "requestId": "test-invoke-request",
//     "identity": {
//       "cognitoIdentityPoolId": null,
//       "accountId": "158695423430",
//       "cognitoIdentityId": null,
//       "caller": "158695423430",
//       "apiKey": "test-invoke-api-key",
//       "sourceIp": "test-invoke-source-ip",
//       "accessKey": "ASIAJR2F2MMJNQRECQQA",
//       "cognitoAuthenticationType": null,
//       "cognitoAuthenticationProvider": null,
//       "userArn": "arn:aws:iam::158695423430:root",
//       "userAgent": "Apache-HttpClient/4.5.x (Java/1.8.0_112)",
//       "user": "158695423430"
//     },
//     "resourcePath": "/foo/{id}",
//     "httpMethod": "GET",
//     "apiId": "1tosi3qyij"
//   },
//   "body": null,
//   "isBase64Encoded": false
// }

exports.handler = function(event, context, callback) {
  const method = event.httpMethod;
  var path = event.path;
  var queryStringParameters = event.queryStringParameters || {};
  var headers = event.headers;
  if(!headers) {
    headers = {};
  }
  headers["User-Agent"] = event.requestContext.identity.userAgent;

  const query = Object.keys(queryStringParameters).map(function(key) { return `${key}=${queryStringParameters[key]}` }).join("/")
  if(query !== "") {
    path += `?${query}`
  }

  const header = Object.keys(headers).map(function(key) { return `${key}=${headers[key]}` }).join("/")
  const body = event.body || '';

  const proc = spawn(`${__dirname}/{{executablePath}}`, [
    "execute",
    method,
    path,
    "--header",
    header,
    "--body",
    body
  ], { stdio: ['pipe', 'pipe', process.stderr]});

  const response = [];
  var responsePhaseIsStart = false;
  var responsePhaseIsEnd = false;

  function isCorrectHexavilleResponseFormat(response) {
    return response[0] == heaxvilleResponseHeader &&
      response[response.length-1] == heaxvilleResponseSeparator &&
      response[response.length-2] == heaxvilleResponseSeparator
  }

  function getResponseBody(responseArr) {
    const response = responseArr.slice();
    response.shift();
    response.shift();
    response.pop();
    response.pop();
    return response.join("");
  }

  proc.stdin.on('data', (data) => {
    console.log(data);
  });

  var stdout = byline(proc.stdout);

  const heaxvilleResponseHeader = "hexaville response format/json";
  const heaxvilleResponseSeparator = "\t";

  stdout.on('data', function(data){
    const line = data.toString();
    if(line == heaxvilleResponseHeader) {
      responsePhaseIsStart = true;
      response.push(heaxvilleResponseHeader);
      return;
    }

    if(responsePhaseIsStart && !responsePhaseIsEnd) {
      response.push(line);
      if(isCorrectHexavilleResponseFormat(response)) {
        responsePhaseIsEnd = true;
      }
    } else {
      console.log(line);
    }
  });

  proc.on('error', (error) => {
    callback(error);
  });

  proc.on('close', (code) => {
    if(!responsePhaseIsEnd) {
      callback(null, {statusCode: 500, "header": {"Content-Type": "application/json"}, body: {"error": "Invalid Hexaville resposne format: " + response.join("")}});
      return;
    }

    try {
      const json = JSON.parse(getResponseBody(response));
      callback(null, json);
    } catch (e) {
      const body = JSON.stringify({"error": e.toString()});
      callback(null, {statusCode: 500, "headers": {"Content-Type": "application/json"}, body: body});
    }
  });
}

// //for debug
// exports.handler(event, null, function(err, data){
//   console.log(data);
// });
