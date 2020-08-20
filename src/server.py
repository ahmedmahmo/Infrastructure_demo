import service_pb2_grpc
import service_pb2
import grpc
from grpc_reflection.v1alpha import reflection
from protobuf_to_dict import protobuf_to_dict
from concurrent import futures
from delphai_backend_utils import logging


def serve():
  server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))

  # the reflection service will be aware of "Greeter" and "ServerReflection" services.
  service_names = (
      service_pb2.DESCRIPTOR.services_by_name['Infrastructure_demo'].full_name,
      reflection.SERVICE_NAME,
  )
  reflection.enable_server_reflection(service_names, server)

  address = '0.0.0.0:8080'
  server.add_insecure_port(address)
  server.start()
  logging.info(f'Started server {address}')
  try:
    server.wait_for_termination()
  except KeyboardInterrupt:
    logging.error('Interrupted')


if __name__ == '__main__':
  serve()