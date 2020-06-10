+++
title = "Quick overview for securing a backend API with Google App Engine and Auth0."
cover = "/img/appengine-auth0.png"
date = 2020-06-06
draft = false

categories = [
    "backend",
]
tags = ["Google Cloud Platform", "App Engine", "Auth0", "api"]


+++

Google App Engine it's a good product for quick API deployment and very easy to integrate with Auth0 for autentication.
I'll go through the basics concepts for deploying an API backend in Python.
<!--more-->
Auth0 is a cloud authentication and authorisation service which solves for you the complexity of identity managament.

This overview is focus in giving some additional explantions or key points that may help you with your specific use case.
It is complementary to what appears in the official "How-to" guides.

* https://cloud.google.com/endpoints/docs/openapi/authenticating-users-auth0
* https://auth0.com/docs/integrations/google-cloud-platform

Prerequisites:

* Create a Google Cloud project (https://cloud.google.com/resource-manager/docs/creating-managing-projects)
* Enable billing for the project (https://cloud.google.com/billing/docs/how-to/modify-project)
* Some Google services enabled (https://cloud.google.com/endpoints/docs/quickstart-endpoints#enabling_required_services)

For this _overview_ will only be necessary to use two products from Google Cloud Platform (GCP): [App Engine](https://cloud.google.com/appengine)
and [Endpoints](https://cloud.google.com/endpoints).

An important thing to take into account is the differences between a **_flexible_** and a **_standard_** environment in Google App Engine. I'll be
focus on enabling it for a _flexible_ environment. The  _Endpoints_ product for _Standard_ environment is still in Beta and it requires many
additional configurations for making it work with Auth0.

1. Deploying backend API

You can deploy your API or application before the Endpoints configuration so you can test it without any authentication. There are
many boilerplates from the [Google documantation](https://github.com/GoogleCloudPlatform/python-docs-samples/tree/master/appengine/flexible)

You could just create your basic sample with any framework like Flask, FastAPI or Django.

* main.py: entrypoint/executable
  
  ```python
    from fastapi import FastAPI

    app = FastAPI()


    @app.get("/getText/{text}")
    def get_text(text: str):
            return {"Text": text}


    @app.get("/notAuthenticated")
    def not_authenticated():
        return {"Endpoint without authentication"}


    @app.get("/")
    def root():
        return {"Root without authentication"}
  ```

* requirements.txt: Requirements for your app. Take into account that GCloud uses only `requirements.txt` file
for the Python runtime. [Additional info](https://cloud.google.com/appengine/docs/flexible/python/using-python-libraries#declaring_and_managing_dependencies)
  
  ```txt
    click==7.1.2
    fastapi==0.55.1
    gunicorn==20.0.4
    h11==0.9.0
    httptools==0.1.1
    pydantic==1.5.1
    starlette==0.13.2
    uvicorn==0.11.5
    uvloop==0.14.0
    websockets==8.1
  ```

* app.yml: It is your App Engine settings file for each service you deploy (https://cloud.google.com/appengine/docs/standard/python3/config/appref)

  ```yaml
    runtime: python
    env: flex
    runtime_config:
        python_version: 3
    entrypoint: gunicorn -w 4 -k uvicorn.workers.UvicornWorker  main:app
    service: test-auth0
  ```

After you already tested the running API you can procced to the Endpoints configuration.

2. Deploy Cloud Endpoints configuration

Cloud Enpoints uses ESP (Extensible Service Proxy) which allows to serve the API's. We must deploy OpenAPI document to Service Management for configuring the endpoints.

OpenApi file for configuring the endpoints:

* openapi-appengine.yml

```yaml
swagger: '2.0'
info:
  title: Test auth0
  version: 1.0.0
host: "{GCLOUD_PROJECT_ID}.appspot.com"
consumes:
- "application/json"
produces:
- "application/json"
schemes:
- "http"
- "https"
paths:
  "/getText/{text}":
    get:
      description: "Get text"
      operationId: "getTextInUri"
      parameters:
        - name: text
          in: path
          description: Get text
          required: true
          type: string
      responses:
        200:
          description: "Success."
          schema:
            type: string
        400:
          description: "Forbidden access"
      security:
       - auth0_jwt: []
  "/notAuthenticated":
     get:
       description: "Not authenticated endpoint"
       operationId: "notAuth"
       responses:
        200:
          description: "Success."
        400:
          description: "Forbidden access"
securityDefinitions:
    auth0_jwt:
      authorizationUrl: "https://{AUTH0_DOMAIN}/authorize"
      flow: "implicit"
      type: "oauth2"
      x-google-issuer: "https://{AUTH0_DOMAIN}/"
      x-google-jwks_uri: "https://{AUTH0_DOMAIN}/.well-known/jwks.json"
      x-google-audiences: "https://{AUTH0_API_ID}/"
```

The file includes two endpoints, only the `getText` one is authenticated. Also, is worth mentioning that the root endpoint
is not available in Google Endpoints. Check [limitations and unsupported features](https://cloud.google.com/endpoints/docs/openapi/openapi-limitations#operations_on_url_root_path_).

Deploy Endpoints service configuration:

`gcloud endpoints services deploy openapi-appengine.yml`

Additional info: https://cloud.google.com/endpoints/docs/openapi/architecture-overview

You must add to your `app.yml` the configuration for link your proyect to the Cloud Endpoints service configuration

```yaml
endpoints_api_service:
  name: "{GCLOUD_PROJECT_ID}.appspot.com"
  rollout_strategy: managed
```

You can do any update to your OpenApi without the need of reloading the service.


I hope this help you!

Cheers.
