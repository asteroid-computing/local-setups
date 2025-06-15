# Kafka Local Developer Environment

This directory contains Docker Compose configurations for running Apache Kafka in various local development setups, including single-node and multi-node clusters, with optional Confluent Schema Registry support.

## Just Kafka

- **simple.docker-compose.yaml**:

  - Runs a single Kafka broker that also acts as a controller.
  - Exposes broker ports for local access.
  - Suitable for simple development and testing scenarios.

- **multi-node.docker-compose.yaml**:
  - Sets up a multi-node Kafka cluster with three controllers and three brokers.
  - Each broker and controller runs in its own container.
  - Brokers are exposed on different ports for local access.
  - Suitable for simulating a production-like Kafka environment locally.

## With Confluent Schema Registry

- **simple.docker-compose.yaml**:

  - Extends the single-broker setup by adding a Confluent Schema Registry service.
  - Schema Registry connects to the single broker for storing schemas.
  - Useful for development scenarios that require Avro or Protobuf serialization.

- **multi-node.docker-compose.yaml**:
  - Extends the multi-node Kafka cluster by adding a Confluent Schema Registry service.
  - Schema Registry connects to all brokers for high availability.
  - Suitable for advanced development and integration testing with schema management.
