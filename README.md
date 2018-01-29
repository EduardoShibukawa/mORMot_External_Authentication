# mORMot_External_Example

This project contains examples demonstrating how to connect to a server mormot, using an Authenticated HTTP connection.

## Getting Started

### Prerequisites

python 3.6
requests 2.12.4

### Installing

pip install -r requirements.txt

### Example

run:

```bash
python mormort_http_client.py
```


Code   
```python
                                     #host,       port,   root
HTTP_CLIENT = AutheticatedHTTPClient('localhost', '888', 'root')
SESSION = HTTP_CLIENT.login(
  'Admin', #User
  '67aeea294e1cb515236fd7829c55ec820ef888e8e221814d24d83b3dc4d825dd' #Hashed Password
)
if SESSION:
    from pprint import pprint
    print("Logged in session:")
    pprint(SESSION.__dict__)

    METHOD = 'ParamMethod'
    PARAMETERS = {'Param1': '4'}

    REQUEST = HTTP_CLIENT.request(METHOD, PARAMETERS)
    print("Making request: {}".format(METHOD))
    pprint(REQUEST.json())

    METHOD = 'Mehod'
    PARAMETERS = {}

    REQUEST = HTTP_CLIENT.request(METHOD, PARAMETERS)
    print("Making request: {}".format(METHOD))
    pprint(REQUEST.json())
else print("Invalid username or Password!")
```

## Authors

* **Eduardo Shibukawa** - *Initial work* - [EduardoShibukawa](https://github.com/EduardoShibukawa)

## License

This project is licensed under the GNU V3.0 License - see the [LICENSE.md](LICENSE.md) file for details
