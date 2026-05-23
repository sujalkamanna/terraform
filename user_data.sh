#!/usr/bin/env bash
set -e

exec > /var/log/user-data.log 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "🔄 Updating system packages..."
apt-get update -y
apt-get upgrade -y

echo "📦 Installing required packages..."
apt-get install -y apache2 curl unzip

echo "🚀 Enabling and starting Apache..."
systemctl enable apache2
systemctl start apache2


echo "☁️ Installing AWS CLI v2..."

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update

echo "AWS CLI Version:"
aws --version

echo "🔎 Fetching EC2 Instance ID..."

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>Terraform Project - Ubuntu 24.x</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      text-align: center;
      margin-top: 50px;
      background-color: #f4f6f8;
    }
    @keyframes colorChange {
      0% { color: red; }
      50% { color: green; }
      100% { color: blue; }
    }
    h1 {
      animation: colorChange 2s infinite;
    }
  </style>
</head>
<body>
  <h1>Terraform Project Server</h1>
  <h2>Ubuntu 24.04 / 24.10</h2>
  <h3>Instance ID: <span style="color:green;">$INSTANCE_ID</span></h3>
  <p>AWS CLI Installed Successfully 🚀</p>
</body>
</html>
EOF

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

apt-get clean
rm -rf /tmp/aws /tmp/awscliv2.zip

echo "✅ Setup complete! "

echo "✅ Server 2 setup completed successfully!"