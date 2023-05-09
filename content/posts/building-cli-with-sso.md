+++
title = "Building a CLI with SSO"
cover = ""
date = 2023-05-09
draft = false

categories = [
    "development",
]
tags = ["python", "auth0"]


+++

👋 Let's talk about adding SSO to our CLIs, something really usefull for different reasons. Single Sign-On (SSO) it not only a common practice now a days in organisations but almost a must.

Although it looks challenging for many people at first glance, nowadays the integration it has been simplied thanks to the different services that help to abstract you from the complexity of the different flows. When it comes to the benefits of using SSO, there are many but some very specific for CLI applications.
<!--more-->


1. Simplifies the authentication process. CLI applications usually run locally in the user computer which means they're probably already using SSO for other services with an active session.
2. Allow users to take advantage of a central identity provider (IdP), that could be any of the frequent mainstream social providers like Google, Microsoft, Github or any other over OIDC or SAML protocols.
3. Increases security as the user doesn't need to mantain long lived secret keys, tokens or credentials for authentication.
4. Allow better integration within other systems and services in the organisation.

those, among others, are some of the benefits but each use case it's different,
so what does CLI session flow different?

## Some context

Whereas in a regular application which lives in the cloud the authorisation flow is "simpler", for a CLI application, where the source code lives in the user computer and you can't exchange a secret, a relatively new flow was defined within the [OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc8628) protocol. The "Device authorisation grant". 

This new grant define a secondary "device" apart from the client where the application is executed. The user manually grant access through that "device".

```diagram
      +----------+                                +----------------+
      |          |>---(A)-- Client Identifier --->|                |
      |          |                                |                |
      |          |<---(B)-- Device Code,      ---<|                |
      |          |          User Code,            |                |
      |  Device  |          & Verification URI    |                |
      |  Client  |                                |                |
      |          |  [polling]                     |                |
      |          |>---(E)-- Device Code       --->|                |
      |          |          & Client Identifier   |                |
      |          |                                |  Authorization |
      |          |<---(F)-- Access Token      ---<|     Server     |
      +----------+   (& Optional Refresh Token)   |                |
            v                                     |                |
            :                                     |                |
           (C) User Code & Verification URI       |                |
            :                                     |                |
            v                                     |                |
      +----------+                                |                |
      | End User |                                |                |
      |    at    |<---(D)-- End user reviews  --->|                |
      |  Browser |          authorization request |                |
      +----------+                                +----------------+

                    Figure 1: Device Authorization Flow
````

## Coding time

For learning purpose I created a new CLI tool with a minimum configuration, and
for this specific example I used **Auth0** as the Identity Provider (IdP), but you can easily
configure it for using with other providers like **Okta, Amazon Cognito or others.**

> If you want to run and test it you'd need at least the following requirements:
> * to create you own **Navite application**
> in [auth0](https://auth0.com/docs/get-started/auth0-overview/create-applications/native-apps)
> * Enable social or a database connection
> * [Register your API](https://auth0.com/docs/get-started/architecture-scenarios/mobile-api/part-2#create-the-api)
>
> With that, you'd have the parameters needed for the OAuth flow, like client_id or audience.



### Request device code

As described in the flow diagram, first step is to request a temporary device code that can be used for propmt the
user for the device activation. For that, the IdP give us an endpoint where we can request that device code using
the audience and client_id parameters.

```python
def request_device_code() -> DeviceCodeResponse:
    headers = {"content-type": "application/x-www-form-urlencoded"}
    payload = f"client_id={_APP_CLIENT_ID}&audience={_AUDIENCE}"

    response = requests.post(
        f"{_TENANT}/oauth/device/code", headers=headers, data=payload
    )
    response.raise_for_status()

    device_code_info = DeviceCodeResponse(**response.json())

    _user_authorization_flow(device_code_info=device_code_info)

    return device_code_info

```


### User device activation

The `device code response` includes different information for enabling the user to activate and to manage the CLI session,

```python
@dataclass
class DeviceCodeResponse:
    device_code: str
    user_code: str
    verification_uri: str
    expires_in: int
    interval: int
    verification_uri_complete: str
```

For this use case, the most relevant is the `user_code` along with the `verification_uri`, the user can copy&paste and go the
URL or just directly open `verification_uri_complete` in a browser to manually activate the CLI. For this step, the user 
needs to be logged in with the appropiate credentials, either a social login (google, github, etc) or a database connection.

### Request access token

The CLI needs to request and to store the access token, meanwhile the user is manually validating the device, the CLI is making
a polling to the token URL provided by the IdP on a defined interval.

```python
def _request_access_token(code: str):
    headers = {"content-type": "application/x-www-form-urlencoded"}
    payload = (
        f"grant_type=urn:ietf:params:oauth:grant-type:device_code&"
        f"device_code={code}&client_id={_APP_CLIENT_ID}"
    )
    response = requests.post(f"{_TENANT}/oauth/token", headers=headers, data=payload)
    response.raise_for_status()

    return response


def poll_user_verification(code: str, interval_seconds: int) -> ReceivedCredentials | None:
    time.sleep(interval_seconds)
    valid_response = False

    while not valid_response:
        try:
            response = _request_access_token(code)
            valid_response = True

            return ReceivedCredentials(**response.json())
        except requests.HTTPError as http_error:
            if http_error.response.status_code == 403:
                print("Retrying device code credentials request")
                time.sleep(interval_seconds)
            else:
                raise http_error

```

Once the user has successfully authorised the CLI you get a 200 status code with the `access_token` in the payload along with
additional parameters depending on the API configuration.

```python
@dataclass
class ReceivedCredentials:
    access_token: str
    expires_in: int
    token_type: str
```


### Call you API with the credentials

The `access_token`is a JWT (JSON Web Token) that follows the [RFC7519](https://datatracker.ietf.org/doc/html/rfc7519) and you
can validate and verify for providing access to you APIs and resources. For that, you can call your API passing the access_token
as a bearer token in the request header.


## Sumary

The code above implementes a basic solution for SSO in you CLI, of course, there are different missing pieces like `refresh_tokens`,
managing access through `scopes` or handling `profiles` which could help to understand better how this work in a corporate
environment.

For reference, if you want to follow up on the previous examples, all code snippets presents in this post are available at:
https://github.com/alexhermida/sample_sso_cli


Cheers!
