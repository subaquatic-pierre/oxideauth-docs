## Introduction

OxideAuth provides a robust, centralized authentication service designed to support a microservice architecture. By centralizing authentication and authorization, OxideAuth ensures a consistent security model across all services while simplifying the development and maintenance process.

## Demo

- Website: https://oxideauth.nebuladev.io

## Repositories

- API: https://github.com/subaquatic-pierre/oxideauth-api
- Dashboard: https://github.com/subaquatic-pierre/oxideauth-dashboard

### Key Features

1. **Decentralized Microservices**

   - Each service runs independently with its own business logic.
   - They often need to interact with shared resources or other services that require authentication and authorization.

2. **Token-Based Authentication**

   - OxideAuth uses JSON Web Tokens (JWTs) for authentication.
   - When a user logs in, they receive an access token that contains information about the user's identity and permissions.

3. **Service Interactions**

   - **Authentication Request**: A microservice sends a request to the OxideAuth service with the user credentials.
   - **Token Issuance**: If the credentials are valid, the OxideAuth service issues an access token and returns it to the microservice.
   - **Service Call**: The microservice uses the access token in subsequent requests to call other services within the architecture.
   - **Permission Check**: Each service validates the access token using the OxideAuth service to ensure that the user has the necessary permissions.
   - **Response**: The requested data is returned to the client.

4. **Scalability and Performance**

   - OxideAuth is designed to handle high traffic and can be scaled horizontally to accommodate growing demand.
   - It uses efficient caching mechanisms to reduce latency and improve performance.

5. **Security Features**
   - **Token Expiration**: Access tokens have a predefined expiration time to enhance security.
   - **Token Revocation**: Tokens can be revoked on-demand to address security incidents or policy changes.
   - **Rate Limiting**: OxideAuth includes rate limiting mechanisms to prevent abuse and denial-of-service attacks.

## Architecture

### Components

1. **User Management Service**

   - Handles user registration, authentication, and authorization.
   - Stores user credentials and permissions in a secure database.

2. **Token Issuance Service**

   - Receives login requests from microservices.
   - Validates user credentials and issues access tokens if valid.

3. **Token Validation Service**

   - Validates access tokens received by microservices.
   - Ensures that the token is still valid and has the necessary permissions.

4. **OAuth 2.0 Support**
   - Supports OAuth 2.0 for third-party authentication providers like Google, Facebook, and GitHub.
   - Enables users to log in using their existing accounts from these providers.

### Workflow

1. **User Registration**

   - New users register through the OxideAuth User Management Service.
   - Credentials and permissions are stored securely.

2. **Login Request**

   - A microservice sends a login request with user credentials to the Token Issuance Service.

3. **Token Generation**

   - The Token Issuance Service validates the credentials.
   - If valid, it generates an access token containing user information and permissions.

4. **Token Transmission**

   - The access token is returned to the microservice.
   - The microservice uses this token in subsequent requests to other services.

5. **Service-to-Service Communication**

   - Microservices include the access token in their requests.
   - Each service forwards the request to the Token Validation Service for validation.

6. **Permission Check**
   - The Token Validation Service checks the token's permissions against the requested action.
   - If authorized, the requested data is returned; otherwise, an error response is generated.
