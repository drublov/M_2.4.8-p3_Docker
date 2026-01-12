# Adobe Commerce & Open Source 2.4.8-p3 Docker Setup

This repository contains a complete Docker environment for running Adobe Commerce or Magento Open Source 2.4.8-p3.

## Stack Overview
- **PHP:** 8.4-FPM
- **Web Server:** Nginx 1.28
- **Database:** MariaDB 11.4
- **Search Engine:** OpenSearch 3.0.0
- **Cache/Session:** Valkey 8.0
- **Message Broker:** RabbitMQ 4.1
- **Email Catching:** Mailpit
- **Composer:** 2.9

## Installation Steps

### 1. Prepare Credentials
Adobe Commerce requires Marketplace credentials to download.
1. Copy the sample file:
   ```bash
   cp auth.json.sample auth.json
   ```
2. Edit `auth.json` and replace `<your-public-key>` and `<your-private-key>` with your Adobe Commerce credentials.

### 2. Start the Docker Environment
Build and launch the containers:
```bash
docker-compose up -d --build
```

### 3. Run the Bootstrap Script
Initialize the project and install Magento. You can choose to install Adobe Commerce (Enterprise) or Magento Open Source (Community).

**For Adobe Commerce (Enterprise Edition):**
```bash
docker-compose exec -u www-data app bash docker/bootstrap.sh enterprise
```

**For Magento Open Source (Community Edition):**
```bash
docker-compose exec -u www-data app bash docker/bootstrap.sh community
```

**To install with Sample Data:**
Add `true` as the second argument:
```bash
docker-compose exec -u www-data app bash docker/bootstrap.sh enterprise true
```

*Note: If no argument is provided, the script defaults to `enterprise`. The second argument (sample data) defaults to `false`. The script will download the source code if it's not already in the root directory.*

### 4. Configure Local Hosts
Add the following line to your local machine's `/etc/hosts` file:
```text
127.0.0.1 magento.test
```

### 5. Access the Store
- **Storefront:** [https://magento.test/](https://magento.test/)
- **Admin Panel:** [https://magento.test/admin](https://magento.test/admin)
  - **Username:** `admin`
  - **Password:** `password123`
- **Mailpit Dashboard:** [http://localhost:8025/](http://localhost:8025/) (Use this to catch and view all outgoing emails, including 2FA codes).

---

## HTTPS Setup (SSL)
The environment is configured to use HTTPS with `magento.test`. 
To ensure your browser trusts the local certificate:
1. Generate Certificates:
   If you have `mkcert` installed on your host:
   ```bash
   mkdir -p docker/certs
   mkcert -install
   mkcert -cert-file docker/certs/magento.test.crt -key-file docker/certs/magento.test.key magento.test
   ```
   If you **don't** have `mkcert` on your host, you can run it via the app container:
   ```bash
   mkdir -p docker/certs
   docker-compose exec -u root app mkcert -cert-file docker/certs/magento.test.crt -key-file docker/certs/magento.test.key magento.test
   ```
   **To trust the certificate on your host:**
   If you used the Docker method, you need to manually trust the Root CA generated inside the container:
   - On macOS: 
     ```bash
     sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain docker/mkcert/rootCA.pem
     ```
   - On Windows/Linux: Import `docker/mkcert/rootCA.pem` into your browser's or system's Trusted Root Certification Authorities.
3. Restart the web container:
   ```bash
   docker-compose restart web
   ```

---

## Mailpit (Email Catching)
All outgoing emails sent by the application are automatically intercepted by Mailpit. This is useful for testing email functionality (like 2FA, order confirmations, etc.) without sending real emails.

- **Web UI:** Access the dashboard at [http://localhost:8025/](http://localhost:8025/) to view all intercepted messages.
- **SMTP Port:** The application is configured to send emails to `mailpit:1025`.

---

## Database Access
You can connect to the MariaDB database from your host system using any database client (e.g., Sequel Ace, TablePlus, DBeaver).

- **Host:** `127.0.0.1`
- **Port:** `3306`
- **Database:** `magento`
- **Username:** `magento`
- **Password:** `magento`
- **Root Password:** `root`

---

## Useful Commands

| Action | Command |
| --- | --- |
| Stop containers | `docker-compose stop` |
| Restart containers | `docker-compose restart` |
| Remove containers & data | `docker-compose down -v` |
| View logs | `docker-compose logs -f` |
| Enter PHP container | `docker-compose exec -u www-data app bash` |
| Run Magento CLI | `docker-compose exec -u www-data app bin/magento <command>` |
| Deploy Sample Data | `docker-compose exec -u www-data app bin/magento sampledata:deploy` |
| Run Upgrade | `docker-compose exec -u www-data app bin/magento setup:upgrade` |
| Clean Cache | `docker-compose exec -u www-data app bin/magento cache:clean` |
