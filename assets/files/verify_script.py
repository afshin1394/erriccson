import json
import subprocess
import sys

# Get the lrf file path from command-line arguments
lrf_file_path = sys.argv[1]

# Proceed with your existing code
with open(lrf_file_path, "r") as r:
    message = r.read()

# Step 2: Parse the content as JSON
json_data = json.loads(message)

# Step 3: Extract "data" and write it to 'data.txt'
with open("data.txt", "w") as f:
    f.write(json.dumps(json_data["data"]))

# Step 4: Extract "signature", convert to bytes, and write to 'sig1.sig'
sig = json_data["signature"]
signature = bytes.fromhex(sig)
with open("sig1.sig", "wb") as f:
    f.write(signature)

# Step 5: Verify the signature using OpenSSL
try:
    result = subprocess.run(
        [
            "openssl", "dgst", "-sha256",
            "-verify", "sender_public_key.pem",
            "-signature", "sig1.sig",
            "-sigopt", "rsa_padding_mode:pss",
            "data.txt"
        ],
        check=True,  # Raises an error if the command fails
        capture_output=True,
        text=True
    )
    print("Verification successful:\n", result.stdout)
except subprocess.CalledProcessError as e:
    print("Verification failed:\n", e.stderr)
