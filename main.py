import requests


print(requests.get('http://ifconfig.me', proxies = {
    'http': 'http://admin:password@localhost:3128'
}).text)