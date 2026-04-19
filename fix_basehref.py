import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('169.239.251.102', port=222, username='tomoh.ikfingeh', password='STCL@UDE20@?', timeout=20)

# Fix base href
cmd = "sed -i 's|<base href=\"/\">|<base href=\"/~tomoh.ikfingeh/mboa_health/\">|' ~/public_html/mboa_health/index.html"
_, out, err = ssh.exec_command(cmd)
out.read(); err.read()

# Verify
_, out2, _ = ssh.exec_command('grep "base href" ~/public_html/mboa_health/index.html')
print('Fixed:', out2.read().decode().strip())
ssh.close()
