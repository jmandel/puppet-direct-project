import dns.rdata

class DNS(object):
    def add_to_config(self,client):    
        d = client.factory.create("ns0:dnsRecord")
        d.type=self.record_type
        d.name = self.name
        d.ttl = self.ttl 
        d.data = self.data
        d.id = 0

        for existing in client.service.getDNSByType(self.record_type):
            if existing.name == d.name:
                client.service.removeDNS(existing)

        client.service.addDNS(d)

class A(DNS):

    record_type = 1

    def __init__(self, name, ip, ttl=300):
        self.name=name
        self.ip = ip
        self.ttl = ttl

    @property
    def data(self):
        return to_wire(self.ip, self)

class MX(DNS):

    record_type = 15

    def __init__(self, name, ip, priority=0,  ttl=300):
        self.name = name
        self.priority = priority
        self.ip = ip
        self.ttl = ttl

    @property
    def data(self):
        return to_wire("%s %s"%(self.priority, self.ip), self)

def to_wire(t, c):
    return dns.rdata.from_text(1,c.record_type,t).to_digestable().encode("base64").strip()

def from_wire(w, c):
    b64 = base64.decodestring(w)
    return dns.rdata.from_wire(1,c.record_type,b64,0,len(b64)).to_text()

