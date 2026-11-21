FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /workspace

COPY . .

RUN flutter pub get

EXPOSE 8080

CMD ["dart", "run", "apps/server/lib/server.dart"]