# Local Development Guide

To develop and test the `myadmin-api` application locally without deploying the full cloud infrastructure, you can use the provided Docker Compose environment.

## Prerequisites

- **Docker** and **Docker Compose** installed on your machine.

## Setup

1. **Navigate to the API directory**:

    ```bash
    cd docker/api
    ```

2. **Clone the API Repository URL**:

    ```bash
    git clone https://github.com/Andrainarivo/MyAdmin.git
    ```

3. **Create a `.env` file**: This file is used by `docker-compose` to inject environment variables, especially secrets.

    ```env
    # .env
    ENV=development
    SECRET_KEY="your-dev-secret-key"
    ENCRYPTION_KEY="your-dev-encryption-key"
    ```

4. **Launch the containers**: This command will build the API image (if needed) and start the API and MySQL database containers.

    ```bash
    docker-compose up --build
    ```

The API will then be accessible at `http://localhost:8000`.

The MySQL database is accessible on port `3306` of your host machine, and its data is persisted in a Docker volume named `mysql_dev_data`.

## Stopping the Environment

To stop the containers:

```bash
docker-compose down
```
