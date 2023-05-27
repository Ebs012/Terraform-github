
#!/bin/bash
sudo su
yum update -y
yum install httpd -y
systemctl start httpd.service
systemctl enable httpd.service
echo "Hello World from $(hostname -f)" > /var/www/html/index.html