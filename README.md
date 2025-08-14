# Smart Library Backend

A Node.js backend for the Smart Library project, using MySQL and MongoDB for data storage.
Runs inside Docker for easy setup and deployment.
Configured to serve the API locally on http://localhost:8080.

---

## Tech Stack
- **NodeJS**
- **MySQL**
- **MongoDB**
- **Docker & Docker Compose**

---

## Prerequisites
- **Docker & Docker Compose installed** v20.9.x
- **Node.js** v20.x recommended
 
---

## Installation

Clone the repository:
```bash
git clone https://github.com/HoangLongRMIT/smart-library-backend.git
```

Run server with Docker:
```bash
docker compose up --build
```

Install dependencies (only if running locally without Docker):
```bash
npm install
```

Backend will available:
```
http://localhost:8080
```