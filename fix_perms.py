import paramiko, warnings
warnings.filterwarnings("ignore")

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect("169.239.251.102", port=222, username="tomoh.ikfingeh", password="STCL@UDE20@?")

def run(cmd, desc):
    stdin, stdout, stderr = client.exec_command(cmd)
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    print(f"\n=== {desc} ===")
    if out: print(out)
    if err and "Warning" not in err: print("ERR:", err[:500])

# Check directory/file permissions
run("ls -la ~/public_html/mboa_api/", "mboa_api directory permissions")
run("ls -la ~/public_html/mboa_api/api/", "api directory permissions")
run("ls -la ~/public_html/mboa_api/api/auth/", "auth directory permissions")

# Check public_html permissions
run("ls -la ~/public_html/", "public_html permissions")
run("stat ~/public_html/mboa_api/", "mboa_api stat")

# Fix permissions: directories 755, files 644
run("find ~/public_html/mboa_api -type d -exec chmod 755 {} \\;", "Fix directory permissions (755)")
run("find ~/public_html/mboa_api -type f -exec chmod 644 {} \\;", "Fix file permissions (644)")

# Verify .htaccess is in place
run("cat ~/public_html/mboa_api/.htaccess", "htaccess content")

# Test from localhost
run(
    "curl -s -o /dev/null -w '%{http_code}' "
    "http://localhost:280/~tomoh.ikfingeh/mboa_api/api/auth/register.php",
    "HTTP status code from server"
)

client.close()
