import base64

b64 = "AAD4//j/AQAAAAAAAAD4/wAAAQAAAAAAAAD4/wgAAQAAAAAAAAAAAPj/AQAAAAAAAAAAAAAAAQAAAAAAAAAAAAgAAQAAAAAAAAAIAPj/AQAAAAAAAAAIAAAAAQAAAAAAAAAIAAgAAQAAAAAAAAA="
data = base64.b64decode(b64)
print(f"Length: {len(data)}")
# try chunks of 12 or something
for i in range(0, len(data), 12):
    print(data[i:i+12].hex())
