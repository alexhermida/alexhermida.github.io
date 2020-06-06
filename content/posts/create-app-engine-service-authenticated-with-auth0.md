+++
title = "Quick overview for deploying backend API with Google App Engine and Auth0."
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

This overview is focus in giving some additional explantions or key points that may help you with your specific use case
and it is complementary to what appears in the official "How-to" guides.

* https://cloud.google.com/endpoints/docs/openapi/authenticating-users-auth0
* https://auth0.com/docs/integrations/google-cloud-platform

Prerequisites:

* Create a Google Cloud project
* Enable billing for the project (https://cloud.google.com/billing/docs/how-to/modify-project)
* Some Google services enabled (https://cloud.google.com/endpoints/docs/quickstart-endpoints#enabling_required_services)

For this _overview_ will only be necessary to use two products from Google Cloud Platform (GCP): App Engine and Endpoints.

A important thing to take into account is the differences between a _flexible_ and a _standard_ environment in Google App Engine. I'll be
focus on enabling it for a _flexible_ environment. The  _Endpoints_ product for _standard_ environment is still in Beta and it requires many
additional configurations for making it work with Auth0.

In python.

Deploy the backend service
Need to configure and deploy Clound enpoints

1. Deploy Cloud Endpoints configuration

Cloud Enpoints uses ESP (Extensible Service Proxy) which allows to serve the API's. We must deploy OpenAPI document to Service Management for configuring the endpoints.

- openapi-appengine.yml: OpenApi file for configuring the endpoints

```
https://gist.github.com/alexhermida/4faef294c2a00cd759bd0c523f31e3dd
```

`gcloud endpoints services deploy openapi-appengine.yml`


2. Deploy backend API

Your project codebase should include at least:

- main.py: entrypoint/executable 
- app.yml: It is your App Engine settings file for each service you deploy (https://cloud.google.com/appengine/docs/standard/python3/config/appref)

You must add to your `app.yml` the configuration for link your proyect to the Cloud Endpoints service configuration

```
endpoints_api_service:
  name: "{GCLOUD_PROJECT_ID}.appspot.com"
  rollout_strategy: managed
```

Additional info: https://cloud.google.com/endpoints/docs/openapi/architecture-overview
https://cloud.google.com/endpoints/docs/openapi/openapi-limitations

