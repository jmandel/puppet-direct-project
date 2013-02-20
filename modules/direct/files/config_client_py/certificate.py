import OpenSSL.crypto as crypto
from datetime import datetime

class Certificate(object):

    def __init__(self, der_location, domain, vali):
        self.cert = crypto.load_certificate(
                   crypto.FILETYPE_ASN1, 
                   open(der_location).read())

    def get_not_before(self):
        return parse_date(self.cert.get_notBefore())

    def get_not_after(self):
        return parse_date(self.cert.get_notAfter())

    def get_cn(self):
        return get_dn_part(self.cert, "CN")

    def add_to_config(self, client):
        c = client.factory.create("ns0:certificate")
        c.id = 0 # TODO: not sure why but this avoids err.
        c.data = crypto.dump_certificate(crypto.FILETYPE_ASN1, self.cert).encode("base64")
        c.owner = self.get_cn()
        c.validEndDate = self.get_not_after() 
        c.validStartDate = self.get_not_before() 
        d.status.value = "ENABLED"
        c.privateKey = False
        client.service.addCertificate(c)

def parse_date(d):
    return datetime.strptime(d[:14], "%Y%m%d%H%M%S")

def get_dn_part(part, name):
    return [ 
       x[1] 
       for x in self.cert.get_issuer().get_components() 
       if x[0]==part
    ][0]

