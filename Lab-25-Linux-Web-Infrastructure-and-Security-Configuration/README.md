# Lab 25 - Linux Server Administration, SSH, Nginx Web Server Deployment, and SSL/TLS Configuration

## Overview

This lab demonstrates remote Linux server administration using SSH from a Windows workstation. I connected to an Ubuntu Linux virtual machine, installed and configured the Nginx web server, verified that the Nginx service was running, edited the default website content, and confirmed the changes through a web browser.

After successfully deploying and customizing the web server, I also configured a locally generated self-signed SSL/TLS certificate to enable HTTPS and gain hands-on experience with secure web server configuration.

## Lab Setup

* **Host Machine:** Windows 11 Laptop
* **Virtualization Platform:** VMware Workstation
* **Server:** Ubuntu Linux Virtual Machine
* **Server IP Address:** `192.168.163.128`
* **Network Type:** NAT
* **Remote Administration Protocol:** SSH
* **Web Server:** Nginx

## Tools Used

* Windows Terminal / Command Prompt
* SSH
* Ubuntu Linux
* APT Package Manager
* Nginx
* systemd / `systemctl`
* Nano Text Editor
* OpenSSL
* Microsoft Edge

## Lab Process

### 1. Remotely Accessed the Linux Server Using SSH

From my Windows workstation, I established an SSH session to the Ubuntu Linux server using its private IP address.

This allowed me to remotely administer the Linux server through the command line without interacting directly with the Ubuntu VM console.

### 2. Updated the Linux Package Repository

After connecting through SSH, I refreshed the Ubuntu package repository information to ensure the system had access to the latest available package metadata.

```bash
sudo apt update
```

### 3. Installed the Nginx Web Server

I installed Nginx using Ubuntu's APT package manager.

```bash
sudo apt install nginx -y
```

After installation, Nginx was registered as a systemd service and configured to run as a background service on the server.

### 4. Verified the Nginx Service

I confirmed that Nginx was installed and running successfully.

```bash
sudo systemctl status nginx
```

The service returned an **active (running)** status, confirming that the Nginx web server was operational.

### 5. Accessed the Nginx Web Server from the Windows Host

From the Windows workstation, I opened Microsoft Edge and navigated to the Ubuntu server's private IP address:

```text
http://192.168.163.128
```

The default Nginx webpage loaded successfully.

This confirmed that:

- Nginx was running correctly.
- The Ubuntu server was reachable from the Windows workstation.
- HTTP traffic was successfully being served over TCP port 80.
- The virtual machine's NAT networking configuration allowed communication between the host and server.

### 6. Edited the Nginx Website Content

I located the default Nginx webpage inside the Linux web root and opened it using the Nano text editor.

```bash
sudo nano /var/www/html/index.nginx-debian.html
```

I modified the HTML heading and changed the webpage so that it displayed:

```text
Hello World! Welcome to John's Server
```

This demonstrated the ability to remotely modify files hosted by a Linux web server while administering the system through SSH.

### 7. Verified the Customized Website

After saving the HTML file, I refreshed the webpage from the Windows workstation.

The Nginx server successfully displayed:

```text
Hello World! Welcome to John's Server
```

This verified that the changes made to the website through the Linux command line were immediately being served by Nginx.

### 8. Generated a Self-Signed SSL/TLS Certificate

After confirming that the HTTP web server was functioning correctly, I used OpenSSL to generate a self-signed X.509 certificate and 2048-bit RSA private key.

The certificate and private key were stored locally on the Ubuntu server for use by Nginx.

A self-signed certificate was appropriate for this lab because the server was operating inside a private virtualized environment rather than hosting a publicly accessible production website.

### 9. Configured Nginx for HTTPS

I opened the default Nginx server configuration file using Nano:

```bash
sudo nano /etc/nginx/sites-available/default
```

I configured Nginx to listen for HTTPS connections on TCP port 443 and referenced the paths containing the SSL certificate and private key.

The resulting configuration allowed the Nginx server to support both:

- **HTTP — TCP port 80**
- **HTTPS — TCP port 443**

### 10. Validated the Nginx Configuration

Before applying the new configuration, I used the built-in Nginx configuration test:

```bash
sudo nginx -t
```

This verifies the configuration syntax and helps prevent an invalid configuration from disrupting the running web service.

### 11. Restarted the Nginx Service

After confirming that the configuration was valid, I restarted Nginx:

```bash
sudo systemctl restart nginx
```

I could also verify the service afterward with:

```bash
sudo systemctl status nginx
```

### 12. Tested HTTPS Connectivity

From the Windows workstation, I accessed the server using:

```text
https://192.168.163.128
```

The browser displayed a certificate warning because the SSL/TLS certificate was self-signed rather than issued by a publicly trusted Certificate Authority.

After proceeding through the warning inside the controlled lab environment, I successfully reached the Nginx web server over HTTPS.

This confirmed that encrypted HTTPS communication was functioning.

## Problem Encountered

When accessing the Nginx website over HTTPS, the browser displayed a certificate security warning.

This occurred because the certificate was generated locally and signed by the server itself rather than by a trusted Certificate Authority.

The behavior was expected.

In a production environment, the web server would normally use a certificate issued by a trusted Certificate Authority such as Let's Encrypt, DigiCert, Sectigo, or another certificate provider.

## Troubleshooting and Verification

Several commands were used throughout the lab to verify the configuration and troubleshoot the server.

### Verify Nginx Service Status

```bash
sudo systemctl status nginx
```

This confirmed whether the Nginx service was running.

### Validate Nginx Configuration

```bash
sudo nginx -t
```

This checked the Nginx configuration files for syntax errors before restarting the service.

### Restart Nginx

```bash
sudo systemctl restart nginx
```

This applied configuration changes by restarting the web server.

### Edit Website Content

```bash
sudo nano /var/www/html/index.nginx-debian.html
```

This allowed me to modify the HTML file being served by Nginx.

### Edit the Nginx Server Configuration

```bash
sudo nano /etc/nginx/sites-available/default
```

This allowed me to modify the Nginx server block and configure HTTPS.

## Screenshots

### 1. Nginx Installation and Service Verification

![Nginx Installation and Service Verification](./screenshots/01-nginx-installation-service-verification.png)

### 2. Nginx Web Page Configuration

![Nginx Web Page Configuration](./screenshots/02-nginx-web-page-edit-command.png)

### 3. Custom Nginx Website Verification

![Custom Nginx Website Verification](./screenshots/03-nginx-custom-page-verification.png)

### 4. Nginx HTTPS and SSL/TLS Configuration

![Nginx HTTPS and SSL TLS Configuration](./screenshots/04-nginx-https-tls-configuration.png)

### 5. Final Server State and SSH Session Termination

![Final Server State and SSH Session Termination](./screenshots/05-ssh-session-termination.png)

## Skills Demonstrated

- Remote Linux server administration using SSH
- Ubuntu Linux command-line administration
- SSH client/server connectivity
- Linux package management with APT
- Nginx installation and deployment
- systemd service administration
- `systemctl` service management
- Linux filesystem navigation
- Nano text editor usage
- HTML web content modification
- Web server configuration
- HTTP configuration
- HTTPS configuration
- TCP ports 22, 80, and 443
- SSL/TLS fundamentals
- X.509 certificate generation
- RSA public-key cryptography fundamentals
- OpenSSL
- Nginx configuration validation
- Client/server networking
- VMware virtual networking
- NAT networking
- Web server troubleshooting
- Secure remote administration

## Network and Service Architecture

```text
Windows 11 Workstation
        |
        | SSH - TCP 22
        |
        v
Ubuntu Linux Server
192.168.163.128
        |
        |-- Nginx HTTP  - TCP 80
        |
        |-- Nginx HTTPS - TCP 443
        |
        v
Custom Web Page
"Hello World! Welcome to John's Server"
```

This architecture demonstrates a common systems administration workflow in which an administrator remotely connects to a Linux server using SSH and manages network services entirely through the command line.

## Automation Script

The manual deployment process can also be automated with a Bash script.

The script performs the following actions:

1. Updates Ubuntu package information.
2. Installs Nginx.
3. Creates the customized web page.
4. Generates a self-signed SSL/TLS certificate.
5. Configures Nginx for HTTP and HTTPS.
6. Tests the Nginx configuration.
7. Restarts the Nginx service.

```bash
#!/bin/bash

set -e

# Update package repository
sudo apt update

# Install Nginx
sudo apt install nginx -y

# Create customized web page
echo "<h1>Hello World! Welcome to John's Server</h1>" | \
sudo tee /var/www/html/index.nginx-debian.html > /dev/null

# Generate self-signed SSL/TLS certificate
sudo openssl req \
  -x509 \
  -nodes \
  -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=localhost"

# Configure Nginx
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    root /var/www/html;

    index index.html index.htm index.nginx-debian.html;

    server_name _;
}
EOF

# Validate Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Display service status
sudo systemctl status nginx --no-pager
```

## Outcome

Successfully administered an Ubuntu Linux server remotely from a Windows workstation using SSH.

During the lab, I:

- Established an SSH connection to the Linux server.
- Updated the Ubuntu package repository.
- Installed Nginx.
- Verified the Nginx systemd service.
- Accessed the web server remotely from another machine.
- Located and modified the Nginx website files.
- Changed the website to display **"Hello World! Welcome to John's Server."**
- Generated a self-signed SSL/TLS certificate.
- Configured Nginx to support HTTPS.
- Validated the Nginx configuration.
- Restarted and verified the web service.
- Confirmed HTTP and HTTPS connectivity.

This lab demonstrates practical experience with **Linux server administration, SSH, Nginx, systemd, Linux filesystem management, web infrastructure, networking, SSL/TLS, and remote troubleshooting**.
