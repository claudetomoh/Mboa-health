import paramiko
import os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('169.239.251.102', port=222, username='tomoh.ikfingeh', password='STCL@UDE20@?', timeout=30)
sftp = ssh.open_sftp()

# 1. Upload new backend PHP files
backend_files = [
    (r'backend\api\auth\forgot_password.php',
     '/home/tomoh.ikfingeh/public_html/mboa_api/api/auth/forgot_password.php'),
    (r'backend\api\auth\reset_password.php',
     '/home/tomoh.ikfingeh/public_html/mboa_api/api/auth/reset_password.php'),
]
for local, remote in backend_files:
    sftp.put(local, remote)
    print(f'Uploaded backend: {os.path.basename(local)}')

# Fix backend permissions
ssh.exec_command('chmod 644 ~/public_html/mboa_api/api/auth/forgot_password.php ~/public_html/mboa_api/api/auth/reset_password.php')

# 2. Upload updated web build (full replace)
def upload_dir(sftp, local_path, remote_path):
    try:
        sftp.mkdir(remote_path)
    except:
        pass
    for item in os.listdir(local_path):
        if item.startswith('.'):
            continue
        local_item = os.path.join(local_path, item)
        remote_item = remote_path + '/' + item
        if os.path.isdir(local_item):
            upload_dir(sftp, local_item, remote_item)
        else:
            sftp.put(local_item, remote_item)

print('Uploading web build...')
upload_dir(sftp, r'build\web', '/home/tomoh.ikfingeh/public_html/mboa_health')

# Fix index.html base href (always set correct subpath)
_, out, _ = ssh.exec_command(
    "sed -i 's|<base href=\"/\">|<base href=\"/~tomoh.ikfingeh/mboa_health/\">|g' "
    "~/public_html/mboa_health/index.html"
)
out.read()

# Fix permissions
ssh.exec_command('find ~/public_html/mboa_health -type d -exec chmod 755 {} \\; ; find ~/public_html/mboa_health -type f -exec chmod 644 {} \\;')

sftp.close()
ssh.close()
print('All done!')
