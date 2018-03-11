from serializable_object import SerializableObject
from mormot_client import MormotClient
from pprint import pprint

class Person(SerializableObject):    
    def __init__(self, id=0, name='', document=''):
        super().__init__(id)        
        self.name = name
        self.document = document

class PersonInfo(SerializableObject):
    def __init__(self, mysize):
        self.mysize = mysize

class Dest(SerializableObject):
    def __init__(self, source, dest):
        self.source = source
        self.dest = dest
        self.associationtime = None

class PersonInfoDest(Dest):
    pass

def get_id(response):    
    if response:
        location = response.headers['Location']
        return int(location[location.find('/') + 1:])
    return 0

def print_response(response):    
    if response:
        print(response.url)
        pprint(response.headers)    
        print(response.status_code)
        print('-' * 100)


mormot_client = MormotClient()

if mormot_client.login():
    joao = Person(name="Joao", document='000.000.000-00')
    joao_info = PersonInfo(180)

    print("POST joao: ")
    print(joao.__dict__)
    post_response = mormot_client.post(joao)
    print_response(post_response)

    print("GET joao: ")
    joao = mormot_client.get(Person, get_id(post_response))
    print(joao.__dict__)
    print('-' * 100)

    print("PUT joao: ")
    joao.document = '111.222.333-44'
    print(joao.__dict__)
    put_response = mormot_client.put(joao)
    print_response(put_response)

    print("GET joao: ")
    joao = mormot_client.get(Person, get_id(post_response))
    print(joao.__dict__)
    print('-' * 100)

    print("POST joao info: ")
    print(joao_info.__dict__)
    post_response = mormot_client.post(joao_info)
    print_response(post_response)
    joao_info.id = get_id(post_response)
    print(joao_info.__dict__)
    person_info_dest = PersonInfoDest(joao.id, joao_info.id)

    print("POST Joao info dest: ")
    print(person_info_dest.__dict__)
    post_response = mormot_client.post(person_info_dest)
    print_response(post_response)

    print("GET Joao info dest: ")
    list_ids = mormot_client.get_dest_list(PersonInfoDest, joao.id)
    print("Source Ids: {}".format(list_ids))
    print('-' * 100)

    print("Delete Joao info dest: ")
    delete_response = mormot_client.delete_dest(PersonInfoDest, joao.id,  joao_info.id)
    print_response(delete_response)

    print("GET Joao info dest: ")
    list_ids = mormot_client.get_dest_list(PersonInfoDest, joao.id)
    print("Source Ids: {}".format(list_ids))
    print('-' * 100)

    print("Delete Joao info: ")
    delete_response = mormot_client.delete(PersonInfo, joao_info.id)
    print_response(delete_response)

    print("Delete Joao: ")
    joao_id = joao.id
    delete_response = mormot_client.delete(Person, joao.id)
    print_response(delete_response)

    print("GET joao: ")
    joao = mormot_client.get(Person, joao_id)
    print(joao)
    print('-' * 100)
else:
    print("Login failed!")