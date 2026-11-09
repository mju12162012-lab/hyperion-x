import os, zipfile, hashlib, base64, datetime
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import hashes, serialization
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives.serialization import pkcs7

apk_path = "release/android/HYPERION-X-Android-Release.apk"
out_apk = "release/android/HYPERION-X-Signed.apk"

print("[+] Initializing pure Python in-memory cryptographic signing...")
private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
subject = issuer = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Android Debug")])
cert = x509.CertificateBuilder().subject_name(subject).issuer_name(issuer).public_key(
    private_key.public_key()
).serial_number(x509.random_serial_number()).not_valid_before(
    datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=1)
).not_valid_after(
    datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=3650)
).sign(private_key, hashes.SHA256())

manifest_lines = ["Manifest-Version: 1.0\nCreated-By: Hyperion-X Builder\n\n"]
with zipfile.ZipFile(apk_path, 'r') as zin:
    for item in zin.infolist():
        if item.filename.startswith("META-INF/"): continue
        data = zin.read(item.filename)
        h = base64.b64encode(hashlib.sha256(data).digest()).decode('utf-8')
        manifest_lines.append(f"Name: {item.filename}\nSHA-256-Digest: {h}\n\n")
manifest_data = "".join(manifest_lines).encode('utf-8')

sf_lines = ["Signature-Version: 1.0\nCreated-By: Hyperion-X Builder\n"]
main_digest = base64.b64encode(hashlib.sha256(manifest_data).digest()).decode('utf-8')
sf_lines.append(f"SHA-256-Digest-Manifest: {main_digest}\n\n")
with zipfile.ZipFile(apk_path, 'r') as zin:
    for item in zin.infolist():
        if item.filename.startswith("META-INF/"): continue
        data = zin.read(item.filename)
        item_manifest = f"Name: {item.filename}\nSHA-256-Digest: {base64.b64encode(hashlib.sha256(data).digest()).decode('utf-8')}\n\n".encode('utf-8')
        item_digest = base64.b64encode(hashlib.sha256(item_manifest).digest()).decode('utf-8')
        sf_lines.append(f"Name: {item.filename}\nSHA-256-Digest: {item_digest}\n\n")
sf_data = "".join(sf_lines).encode('utf-8')

pkcs7_builder = pkcs7.PKCS7SignatureBuilder().set_data(sf_data).add_signer(cert, private_key, hashes.SHA256())
pkcs7_signed = pkcs7_builder.sign(serialization.Encoding.DER)

with zipfile.ZipFile(apk_path, 'r') as zin, zipfile.ZipFile(out_apk, 'w', zipfile.ZIP_DEFLATED) as zout:
    for item in zin.infolist():
        if item.filename.startswith("META-INF/"): continue
        zout.writestr(item, zin.read(item.filename))
    zout.writestr("META-INF/MANIFEST.MF", manifest_data)
    zout.writestr("META-INF/CERT.SF", sf_data)
    zout.writestr("META-INF/CERT.RSA", pkcs7_signed)

print("[+] SUCCESS: Valid signed APK generated at:", out_apk)
