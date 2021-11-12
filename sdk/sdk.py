""" Movai-Service's SDK """

import socket
import json
import os

"""
sdk.module.command(params...)

sdk = Sdk('/vra/merfdas.sock')
sdk.module.function(params...)
sdk.__getattr__(module).__getattr__(function).__call__(params...)
"""

class _Cmd(object):

    def __init__(self, module, command, callback):
        self._mod = module
        self._cmd = command
        self._callback = callback

    def __call__(self, **params):
        return self._callback(self._mod, self._cmd, **params)


class _Mod(object):

    def __init__(self, module, callback):
        self._mod = module
        self._callback = callback

    def __getattr__(self, name):
        return _Cmd(self._mod, name, self._callback)


class Sdk(object):

    def __init__(self, unix_socket: str = '/var/run/movai/movai.sock'):
        if not os.path.exists(unix_socket):
            raise FileNotFoundError(f"Socket '{unix_socket}' not found")
        self._unix_socket = unix_socket

    def __getattr__(self, name):
        return _Mod(name, self._request)

    def _request(self, _mod: str, _cmd: str, timeout: float=None, **params):
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM, 0)
        sock.settimeout(timeout)
        req_data = {
            'request': 'action',
            'request_params': {
                'module': _mod,
                'command': _cmd,
                'command_params': params
            }
        }
        raw_data = json.dumps(req_data).encode()
        try:
            sock.connect(self._unix_socket)
        except FileNotFoundError:
            return {'error': "Can't connect to socket"}
        except OSError as err:
            return {'error': str(err)}
        sock.send(raw_data)
        response = sock.recv(2048)

        try:
            data = json.loads(response.decode())
            if 'hijack' in data.keys():
                data['socket'] = sock
            else:
                sock.close()
            return data
        except json.JSONDecodeError:
            sock.close()
            return {'error': "can't parse data from server. Raw response: %s" % response}



__all__ = ['Sdk']
