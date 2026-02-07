# SaboHub Automation Service

This service handles automated background tasks for the SaboHub ecosystem.

## Features

- **Daily Business Report**: Automatically generates a summary of business activities (HR, Finance, Tasks) at 7:00 AM daily and sends a notification to the CEO.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Configure Environment:
   Create a `.env` file with:
   ```
   DATABASE_URL=postgresql://user:pass@host:port/db
   ```

3. Build and Run:
   ```bash
   npm run build
   npm start
   ```

## Development

- Run in dev mode:
  ```bash
  npm run dev
  ```

- Trigger manual report (for testing):
  ```bash
  npm run dev -- --run-now
  ```
