import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('169.239.251.102', port=222, username='tomoh.ikfingeh', password='STCL@UDE20@?', timeout=20)

# Check admin's salt in DB
_, out, _ = ssh.exec_command("mysql -u tomoh.ikfingeh -p'SqlUssd@2026' mobileapps_2026B_tomoh_ikfingeh -e \"SELECT email, salt, LENGTH(password_hash) as hash_len FROM users WHERE email='admin@mboa.health';\" 2>/dev/null")
print("DB:", out.read().decode().strip())

# Test get_salt endpoint
_, out2, _ = ssh.exec_command("curl -s -X POST http://localhost:280/~tomoh.ikfingeh/mboa_api/api/auth/get_salt.php -H 'Content-Type: application/json' -d '{\"email\":\"admin@mboa.health\"}'")
print("get_salt:", out2.read().decode().strip())

# Test login endpoint with the actual hash
import hashlib
new_password = 'Admin@Mboa2026'
ssh.close()
