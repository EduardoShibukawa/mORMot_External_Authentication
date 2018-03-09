import json 
import collections

class SerializableObject:
    def __init__(self, id=0):
        self.id = id

    @classmethod
    def from_json(cls, json_value):       
        if isinstance(json_value, str):
            json_dict = json.loads(json_value)
        else: json_dict = json_value        
                        
        allowed = set(dir(cls())) - set(dir(cls))
        json_dict = {k.lower(): v for k, v in json_dict.items() if k.lower() in allowed}
        
        return cls(**json_dict)

    def to_json(self):
            return json.dumps(
                self, 
                default=lambda o: o.__dict__, 
                sort_keys=True, 
                indent=4,
            )        
    