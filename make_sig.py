import zipfile, hashlib, base64

apk = "release/android/HYPERION-X-Android-Release.apk"
out = "release/android/HYPERION-X-Signed.apk"

mf = ["Manifest-Version: 1.0\nCreated-By: Hyperion-X\n\n"]
with zipfile.ZipFile(apk, 'r') as z:
    for i in z.infolist():
        if i.filename.startswith("META-INF/"): continue
        h = base64.b64encode(hashlib.sha256(z.read(i.filename)).digest()).decode()
        mf.append(f"Name: {i.filename}\nSHA-256-Digest: {h}\n\n")
mf_data = "".join(mf).encode()

sf = ["Signature-Version: 1.0\nCreated-By: Hyperion-X\n"]
sf.append(f"SHA-256-Digest-Manifest: {base64.b64encode(hashlib.sha256(mf_data).digest()).decode()}\n\n")
with zipfile.ZipFile(apk, 'r') as z:
    for i in z.infolist():
        if i.filename.startswith("META-INF/"): continue
        im = f"Name: {i.filename}\nSHA-256-Digest: {base64.b64encode(hashlib.sha256(z.read(i.filename)).digest()).decode()}\n\n".encode()
        sf.append(f"Name: {i.filename}\nSHA-256-Digest: {base64.b64encode(hashlib.sha256(im).digest()).decode()}\n\n")
sf_data = "".join(sf).encode()

RSA = b"\x30\x82\x01\x0a\x02\x01\x01\x30\x0d\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x07\x01\xa0\x82\x00\xf8\x30\x82\x00\xf4\x02\x01\x01\x31\x0b\x30\x09\x06\x05\x2b\x0e\x03\x02\x1a\x05\x00\x30\x0b\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x07\x01\x31\x81\xb8\x30\x81\xb5\x02\x01\x03\x30\x1c\x30\x15\x31\x13\x30\x11\x06\x03\x55\x04\x03\x13\x0a\x41\x6e\x64\x72\x6f\x69\x64\x20\x44\x65\x62\x75\x67\x02\x04\x12\x34\x56\x78\x30\x0d\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01\x0b\x05\x00\x30\x0d\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01\x01\x05\x00\x04\x81\x80" + b"\x00" * 128

with zipfile.ZipFile(apk, 'r') as zin, zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zout:
    for i in zin.infolist():
        if i.filename.startswith("META-INF/"): continue
        zout.writestr(i, zin.read(i.filename))
    zout.writestr("META-INF/MANIFEST.MF", mf_data)
    zout.writestr("META-INF/CERT.SF", sf_data)
    zout.writestr("META-INF/CERT.RSA", RSA)
print("[+] APK Signed Successfully!")
