openssl genrsa -out rsa-key.pem 2048 --passout pass:""

openssl  req -new  -config req-config -key rsa-key.pem > req.pem

openssl  x509 \
        -req \
        -in req.pem \
        -days 3650  \
	-extfile sign-config \
        -signkey rsa-key.pem \
        -text \
        -out certificate.pem



# Make a PKCS12 file from domain cert + key

cat rsa-key.pem certificate.pem | \
    openssl pkcs12 -export \
    -out cert-with-key-package.p12 \
    -passout pass:""


