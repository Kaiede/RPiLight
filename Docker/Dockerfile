###### BUILDER
FROM swiftarm/swift:5.5.2-ubuntu-21.04 as builder
WORKDIR /project

ARG COMMIT

RUN apt-get install -y \
  git

ADD . /project
RUN swift build -j 1 -c release

###### RUNTIME CONTAINER
FROM swiftarm/swift:5.5.2-ubuntu-21.04-slim
WORKDIR /opt/rpilight

ENTRYPOINT ["/opt/rpilight/rpilight", "-v"]

COPY --from=builder /project/.build/release/rpilight .

