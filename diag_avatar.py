import paramiko

HOST = '169.239.251.102'
PORT = 222
USER = 'tomoh.ikfingeh'
PASS = 'STCL@UDE20@?'

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, port=PORT, username=USER, password=PASS, timeout=15)

cmds = [
    'chmod 777 ~/public_html/mboa_api/uploads/avatars && echo OK',
    'ls -la ~/public_html/mboa_api/uploads/',
]
for cmd in cmds:
    stdin, stdout, stderr = client.exec_command(cmd)
    print(stdout.read().decode().strip() or stderr.read().decode().strip())

client.close()
