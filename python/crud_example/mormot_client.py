from mormort_http_client import AutheticatedHTTPClient


class MormotClient:
    def __init__(self):        
        self.server = AutheticatedHTTPClient('localhost', '888', 'root')   
        self.session = None
                              
    def get(self, cls, id):        
        if self.session:
            response = self.server.request(
                "{class_name}/{id}".format(class_name=cls.__name__, id=id),
                {}
            )                                  
            if response.status_code == 200:
                return cls().from_json(response.json())
        return None

    def post(self, value):        
        if self.session:
            return self.server.post(
                value.__class__.__name__,                
                value.to_json() 
            )

        return None

    def put(self, value):
        if self.session:
            return self.server.put(
                "{class_name}/{id}".format(class_name=value.__class__.__name__, id=value.id),
                value.to_json() 
            )            

        return None        

    def delete(self, cls, id):
        if self.session:
            return self.server.delete(
                "{class_name}/{id}".format(class_name=cls.__name__,id=id)
            )

        return None

    def get_dest_list(self, cls, id_source):
        if self.session:
            response = self.server.xget(
                'SELECT Dest FROM {table} WHERE Source=:({id_source}):'.format(
                    table=cls.__name__,
                    id_source=id_source
                )
            )        

            if response.status_code == 200:
                if isinstance(response.json(), list):                    
                    return [v for d in response.json() for v in d.values()]
                else: return []
        return None

    def delete_dest(self, cls, id_source, id_dest):
        if self.session:
            response = self.server.xget(
                'SELECT Id FROM {table} WHERE Source=:({id_source}): AND Dest=:({id_dest}): LIMIT 1'.format(
                    table=cls.__name__,
                    id_source=id_source,
                    id_dest=id_dest
                )
            )        
            
            if response.status_code == 200:                        
                return  self.delete(cls, response.json()[0]["ID"])        
        return None

    def login(self):
        self.session = self.server.login(
                'Admin', #User
                '67aeea294e1cb515236fd7829c55ec820ef888e8e221814d24d83b3dc4d825dd' #Hashed Password
                )    

        return self.session != None    